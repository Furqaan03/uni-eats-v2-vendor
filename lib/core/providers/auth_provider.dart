import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class VendorSession {
  final String email;
  final String restaurantId;
  final String restaurantName;
  final String restaurantLocation;

  const VendorSession({
    required this.email,
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantLocation,
  });
}

/// Result of a Google sign-in attempt for the vendor app.
/// - [error] set: genuine failure.
/// - [pendingEmail] set (error null): this Google account has no vendor
///   record yet — caller should prompt for restaurant selection and call
///   [VendorAuthProvider.completeGoogleSignup].
/// - both null: signed in successfully, [VendorAuthProvider.session] is set.
class GoogleVendorSignInResult {
  final String? error;
  final String? pendingEmail;
  const GoogleVendorSignInResult({this.error, this.pendingEmail});
}

/// Manages real Firebase Auth sign-in/sign-up for vendors. Vendor profile
/// data (restaurant ownership) lives in Firestore at vendors/{uid}, keyed by
/// Firebase Auth uid — never by email or a client-readable password.
class VendorAuthProvider extends ChangeNotifier {
  VendorSession? _session;

  VendorSession? get session => _session;
  bool get isLoggedIn => _session != null;

  CollectionReference<Map<String, dynamic>> get _vendorsCol =>
      FirebaseFirestore.instance.collection('vendors');

  Future<VendorSession?> _loadSession(String uid, String fallbackEmail) async {
    final doc = await _vendorsCol.doc(uid).get();
    final data = doc.data();
    if (data == null) return null;
    return VendorSession(
      email: data['email'] as String? ?? fallbackEmail,
      restaurantId: data['restaurantId'] as String,
      restaurantName: data['restaurantName'] as String,
      restaurantLocation: data['restaurantLocation'] as String,
    );
  }

  Future<void> _createVendorDoc({
    required String uid,
    required String email,
    required String restaurantId,
    required String restaurantName,
    required String restaurantLocation,
    required String authProvider,
  }) {
    return _vendorsCol.doc(uid).set({
      'email': email,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'restaurantLocation': restaurantLocation,
      'authProvider': authProvider,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Returns null on success, an error message on failure.
  Future<String?> signIn(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    try {
      final cred = await fb.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final session = await _loadSession(cred.user!.uid, normalizedEmail);
      if (session == null) return 'No vendor profile found for this account.';
      _session = session;
      notifyListeners();
      return null;
    } on fb.FirebaseAuthException catch (e) {
      return (e.code == 'wrong-password' || e.code == 'invalid-credential')
          ? 'Invalid email or password.'
          : e.message ?? 'Could not sign in. Please try again.';
    } catch (e) {
      return 'Could not sign in — check your connection and try again.';
    }
  }

  /// Creates a new vendor account via Firebase Auth, plus its Firestore
  /// profile doc. Returns null on success, an error message on failure.
  Future<String?> signUp({
    required String email,
    required String password,
    required String restaurantId,
    required String restaurantName,
    required String restaurantLocation,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    try {
      final cred = await fb.FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      await _createVendorDoc(
        uid: cred.user!.uid,
        email: normalizedEmail,
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        restaurantLocation: restaurantLocation,
        authProvider: 'password',
      );
      _session = VendorSession(
        email: normalizedEmail,
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        restaurantLocation: restaurantLocation,
      );
      notifyListeners();
      return null;
    } on fb.FirebaseAuthException catch (e) {
      return e.code == 'email-already-in-use'
          ? 'An account with this email already exists.'
          : e.message ?? 'Could not create your account. Please try again.';
    } catch (e) {
      return 'Could not create your account — check your connection and try again.';
    }
  }

  /// Signs in with Google via real Firebase Auth.
  Future<GoogleVendorSignInResult> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return const GoogleVendorSignInResult(); // user cancelled
      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final cred = await fb.FirebaseAuth.instance.signInWithCredential(credential);
      final email = (cred.user!.email ?? googleUser.email).toLowerCase().trim();

      final session = await _loadSession(cred.user!.uid, email);
      if (session != null) {
        _session = session;
        notifyListeners();
        return const GoogleVendorSignInResult();
      }

      // New vendor signing in via Google for the first time — no account yet.
      return GoogleVendorSignInResult(pendingEmail: email);
    } catch (e) {
      return const GoogleVendorSignInResult(error: 'Google sign-in failed. Please try again.');
    }
  }

  /// Finishes account creation for a first-time Google vendor once they've
  /// picked which restaurant they manage. Must be called while the Google
  /// credential from [signInWithGoogle] is still the active Firebase Auth
  /// session.
  Future<String?> completeGoogleSignup({
    required String email,
    required String restaurantId,
    required String restaurantName,
    required String restaurantLocation,
  }) async {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user == null) return 'Your session expired — please sign in again.';
    try {
      await _createVendorDoc(
        uid: user.uid,
        email: email,
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        restaurantLocation: restaurantLocation,
        authProvider: 'google',
      );
      _session = VendorSession(
        email: email,
        restaurantId: restaurantId,
        restaurantName: restaurantName,
        restaurantLocation: restaurantLocation,
      );
      notifyListeners();
      return null;
    } catch (e) {
      return 'Could not create your account — check your connection and try again.';
    }
  }

  /// Restores the session from Firebase Auth's own persisted login state
  /// (no plaintext credentials stored by this app). Returns the session on
  /// success, null otherwise.
  Future<VendorSession?> tryAutoSignIn() async {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final session = await _loadSession(user.uid, user.email?.toLowerCase().trim() ?? '');
    if (session != null) {
      _session = session;
      notifyListeners();
    }
    return session;
  }

  Future<void> signOut() async {
    _session = null;
    await fb.FirebaseAuth.instance.signOut();
    notifyListeners();
  }
}
