import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../services/firestore_order_service.dart' show AppEnv, DataEnv;
import '../models/registration.dart';

/// Vendor access state derived from the Firebase Auth custom claims. This is
/// the source of truth for routing — the registration doc only drives the
/// onboarding steps' UI.
enum VendorAccess { none, pending, needsChanges, approved, rejected }

VendorAccess _accessFromClaim(Object? v) => switch (v) {
      'approved' => VendorAccess.approved,
      'pending' => VendorAccess.pending,
      'needs_changes' => VendorAccess.needsChanges,
      'rejected' => VendorAccess.rejected,
      _ => VendorAccess.none,
    };

/// All the server round-trips the onboarding flow needs: reading claims,
/// consuming the auto-login token, and reading/updating the vendor's own
/// registration doc + document uploads. Custom claims and status→approved are
/// NEVER written here — only Cloud Functions can (see functions/index.js).
class OnboardingRepository {
  OnboardingRepository._();
  static final OnboardingRepository instance = OnboardingRepository._();

  static String get envName => AppEnv.current == DataEnv.live ? 'live' : 'test';

  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _registrations =>
      _db.collection(AppEnv.col('registrations'));

  // --- Claims --------------------------------------------------------------

  /// Reads the vendor access level off the current user's claims. Pass
  /// [refresh] true after a server-side claim change (e.g. approval) so the
  /// new state takes effect with no re-login.
  Future<VendorAccess> readAccess({bool refresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return VendorAccess.none;
    final res = await user.getIdTokenResult(refresh);
    return _accessFromClaim(res.claims?['vendorStatus']);
  }

  // --- Auto-login handoff (Screen 5.1) -------------------------------------

  /// Consumes the single-use token from the invite deep link and signs in.
  /// Throws [FirebaseFunctionsException] (code 'failed-precondition' == expired
  /// / already used) so the caller can show the right UI.
  Future<void> consumeLoginToken({
    required String registrationId,
    required String secret,
    required String env,
  }) async {
    final res = await _functions.httpsCallable('consumeLoginToken').call({
      'registrationId': registrationId,
      'secret': secret,
      'env': env,
    });
    final token = (res.data as Map)['customToken'] as String;
    await _auth.signInWithCustomToken(token);
    await _auth.currentUser?.getIdToken(true); // pull fresh claims immediately
  }

  /// Rate-limited (server-enforced, max 3/24h) re-issue of the auto-login link.
  Future<void> resendLoginLink({
    required String registrationId,
    required String env,
  }) async {
    await _functions.httpsCallable('resendLoginLink').call({
      'registrationId': registrationId,
      'env': env,
    });
  }

  // --- Registration doc ----------------------------------------------------

  /// Loads the signed-in vendor's own registration. Matches by uid first, then
  /// by the invited email — stamping the uid onto the doc the first time so
  /// subsequent reads (and the rules' uid match) are stable.
  Future<Registration?> loadForCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final byUid = await _registrations.where('uid', isEqualTo: user.uid).limit(1).get();
    if (byUid.docs.isNotEmpty) return Registration.fromDoc(byUid.docs.first);

    final email = user.email?.trim().toLowerCase();
    if (email == null || email.isEmpty) return null;
    final byEmail = await _registrations.where('email', isEqualTo: email).limit(1).get();
    if (byEmail.docs.isEmpty) return null;

    final doc = byEmail.docs.first;
    // Claim the doc for this uid so future access is uid-stable.
    if ((doc.data()['uid'] as String?)?.isEmpty ?? true) {
      await doc.reference.update({'uid': user.uid});
    }
    return Registration.fromDoc(doc);
  }

  Stream<Registration> watch(String id) =>
      _registrations.doc(id).snapshots().map(Registration.fromDoc);

  /// Confirms the editable details and records this device's push token so the
  /// approval push can reach it.
  Future<void> confirmDetails(
    String id, {
    required String contactName,
    required String phone,
    required String location,
  }) async {
    final update = <String, dynamic>{
      'contactName': contactName,
      'phone': phone,
      'location': location,
      'detailsConfirmed': true,
    };
    final token = await _safeFcmToken();
    if (token != null) update['fcmTokens'] = FieldValue.arrayUnion([token]);
    await _registrations.doc(id).update(update);
  }

  /// Sets the real Firebase Auth password (Screen 5.3) and flags passwordSet so
  /// the vendor can get back in with a password if they close the app before
  /// approval.
  Future<void> setPassword(String id, String password) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Not signed in.');
    await user.updatePassword(password);
    await _registrations.doc(id).update({'passwordSet': true});
  }

  /// Uploads one document to the locked-down vendor-docs path and returns its
  /// storage path. Client-side type/size checks mirror the Storage rules.
  Future<RegistrationDocument> uploadDocument({
    required String kind,
    required File file,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Not signed in.');

    final len = await file.length();
    if (len > 5 * 1024 * 1024) {
      throw ArgumentError('File is larger than 5 MB.');
    }
    final ext = file.path.split('.').last.toLowerCase();
    const allowed = {'jpg', 'jpeg', 'png', 'pdf'};
    if (!allowed.contains(ext)) {
      throw ArgumentError('Only JPG, PNG or PDF files are allowed.');
    }
    final contentType = ext == 'pdf'
        ? 'application/pdf'
        : (ext == 'png' ? 'image/png' : 'image/jpeg');

    final path = 'vendor-docs/${user.uid}/$kind-${DateTime.now().millisecondsSinceEpoch}.$ext';
    final ref = FirebaseStorage.instance.ref(path);
    await ref.putFile(file, SettableMetadata(contentType: contentType));
    return RegistrationDocument(kind: kind, storagePath: path, uploadedAt: DateTime.now());
  }

  /// Writes the documents array and (re)submits for review. Works for both the
  /// first submission and a needs_changes → pending resubmission.
  Future<void> submitDocuments(String id, List<RegistrationDocument> docs) async {
    await _registrations.doc(id).update({
      'documents': docs.map((d) => d.toMap()).toList(),
      'status': RegistrationStatus.pending.wire,
      'adminNote': '',
    });
  }

  /// Cold self-application (no invite): creates a pending registration with
  /// nothing pre-filled and the requested outlet flagged for a rep to resolve.
  /// No account is created here — that only happens on approval. Allowed
  /// unauthenticated by the security rules (status forced pending, no uid).
  Future<void> submitColdApplication({
    required String contactName,
    required String email,
    required String phone,
    required String outletRequest,
  }) async {
    await _registrations.add({
      'type': 'vendor',
      'status': RegistrationStatus.pending.wire,
      'environment': envName,
      'contactName': contactName,
      'email': email.trim().toLowerCase(),
      'phone': phone,
      'outletId': '',
      'outletName': outletRequest,
      'branchId': null,
      'location': '',
      'role': VendorRole.vendorAdmin.wire,
      'documents': [],
      'detailsConfirmed': false,
      'passwordSet': false,
      'invitedByRepId': null,
      'outletUnlisted': true,
      'adminNote': '',
      'submittedAt': FieldValue.serverTimestamp(),
      'reviewedAt': null,
    });
  }

  Future<String?> _safeFcmToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }
}
