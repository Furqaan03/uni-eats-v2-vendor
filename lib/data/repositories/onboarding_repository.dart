import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

import '../../services/firestore_order_service.dart' show AppEnv, DataEnv;
import '../models/registration.dart';

// Cloudinary unsigned upload target for vendor documents. The project runs on
// the Firebase Spark plan, where Firebase Storage (and Cloud Functions) can't
// be enabled — documents go to Cloudinary instead. The cloud name and preset
// name are public by design (unsigned uploads); the API secret is NOT here.
// The preset must exist in the Cloudinary console: Settings → Upload →
// Upload presets → Add: name `vendor_docs`, Signing Mode: Unsigned,
// folder `vendor-docs`.
const String _cloudinaryCloudName = 'dhsq8isal';
const String _cloudinaryUploadPreset = 'vendor_docs';

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

  /// Consumes the token from the invite deep link and signs in.
  ///
  /// Two link shapes are supported:
  /// - Spark plan (no Cloud Functions): `t` IS a Firebase custom token (a JWT,
  ///   minted by scripts/onboarding_worker.js, expires in 1 hour) — sign in
  ///   with it directly. Expiry surfaces as [FirebaseAuthException]
  ///   'invalid-custom-token'.
  /// - Blaze plan: `t` is an opaque single-use secret exchanged via the
  ///   `consumeLoginToken` callable, which enforces single-use + expiry.
  ///
  /// Throws [FirebaseFunctionsException] (code 'failed-precondition' == expired
  /// / already used) or [FirebaseAuthException] (expired custom token) so the
  /// caller can show the right UI.
  Future<void> consumeLoginToken({
    required String registrationId,
    required String secret,
    required String env,
  }) async {
    // A JWT has exactly two dots (header.payload.signature); the callable-path
    // secret is plain hex. Decide the sign-in path by shape.
    if ('.'.allMatches(secret).length == 2) {
      await _auth.signInWithCustomToken(secret);
    } else {
      final res = await _functions.httpsCallable('consumeLoginToken').call({
        'registrationId': registrationId,
        'secret': secret,
        'env': env,
      });
      final token = (res.data as Map)['customToken'] as String;
      await _auth.signInWithCustomToken(token);
    }
    await _auth.currentUser?.getIdToken(true); // pull fresh claims immediately
  }

  /// Rate-limited (max 3/24h) re-issue of the auto-login link. Prefers the
  /// callable; on Spark (functions unreachable) falls back to flagging the
  /// registration doc with `resendQueued` for scripts/onboarding_worker.js.
  /// The fallback needs the vendor signed in (rules: own-doc updates only) —
  /// from a signed-out expired-link screen it will fail, and the admin can
  /// resend from the dashboard instead.
  Future<void> resendLoginLink({
    required String registrationId,
    required String env,
  }) async {
    try {
      await _functions.httpsCallable('resendLoginLink').call({
        'registrationId': registrationId,
        'env': env,
      });
    } on FirebaseFunctionsException catch (e) {
      const unreachable = {'not-found', 'unavailable', 'internal'};
      if (!unreachable.contains(e.code)) rethrow;
      await _registrations.doc(registrationId).update({'resendQueued': true});
    }
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

  /// Uploads one document to Cloudinary (unsigned preset — see the constants
  /// at the top of this file) and returns it with the delivery URL stored as
  /// the document's path, so the admin can preview it straight from the
  /// registration doc. Client-side type/size checks kept from the Storage era.
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

    final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/auto/upload');
    final req = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _cloudinaryUploadPreset
      ..fields['folder'] = 'vendor-docs/${user.uid}'
      ..fields['public_id'] = '$kind-${DateTime.now().millisecondsSinceEpoch}'
      ..files.add(await http.MultipartFile.fromPath('file', file.path));
    final res = await http.Response.fromStream(await req.send());
    if (res.statusCode != 200) {
      String message = 'Upload failed (${res.statusCode}).';
      try {
        final err = jsonDecode(res.body) as Map<String, dynamic>;
        message = (err['error'] as Map?)?['message'] as String? ?? message;
      } catch (_) {}
      throw StateError(message);
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final url = body['secure_url'] as String? ?? '';
    if (url.isEmpty) throw StateError('Upload succeeded but returned no URL.');
    return RegistrationDocument(kind: kind, storagePath: url, uploadedAt: DateTime.now());
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
