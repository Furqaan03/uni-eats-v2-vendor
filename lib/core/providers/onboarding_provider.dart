import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../data/models/registration.dart';
import '../../data/repositories/onboarding_repository.dart';
import '../../features/analytics/onboarding_analytics.dart';

/// Which onboarding step the pending shell should show. Derived from how far
/// the registration has progressed, not stored — keeps the step counter honest.
enum OnboardingStep { confirmDetails, setPassword, uploadDocuments, status }

/// Drives the pending shell: holds the claim-derived access level and the
/// vendor's registration, and exposes the four onboarding actions. Approval is
/// observed by watching the registration doc flip to `approved`, at which point
/// we force-refresh the token so claims unlock the full app with no re-login.
class OnboardingProvider extends ChangeNotifier {
  OnboardingProvider({OnboardingRepository? repo})
      : _repo = repo ?? OnboardingRepository.instance;

  final OnboardingRepository _repo;

  VendorAccess _access = VendorAccess.none;
  Registration? _registration;
  bool _loading = false;
  String? _error;
  StreamSubscription<Registration>? _sub;

  VendorAccess get access => _access;
  Registration? get registration => _registration;
  bool get loading => _loading;
  String? get error => _error;

  /// The step to show. `status` once documents are in or the app is under
  /// review; otherwise the first incomplete step.
  OnboardingStep get step {
    final r = _registration;
    if (r == null) return OnboardingStep.confirmDetails;
    if (r.status == RegistrationStatus.needsChanges) return OnboardingStep.uploadDocuments;
    if (!r.detailsConfirmed) return OnboardingStep.confirmDetails;
    if (!r.passwordSet) return OnboardingStep.setPassword;
    if (r.documents.isEmpty) return OnboardingStep.uploadDocuments;
    return OnboardingStep.status;
  }

  /// Loads claims + registration and starts watching for approval.
  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _access = await _repo.readAccess();
      _registration = await _repo.loadForCurrentUser();
      _listen();
    } catch (e) {
      _error = 'Could not load your application. Check your connection.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _listen() {
    _sub?.cancel();
    final id = _registration?.id;
    if (id == null) return;
    _sub = _repo.watch(id).listen((r) async {
      _registration = r;
      // The doc status flips to `approved` when the approval engine runs; pull
      // fresh claims so routing unlocks without a re-login.
      if (r.status == RegistrationStatus.approved && _access != VendorAccess.approved) {
        _access = await _repo.readAccess(refresh: true);
        OnboardingAnalytics.log('activated');
      }
      notifyListeners();
    });
  }

  Future<void> refreshAccess() async {
    _access = await _repo.readAccess(refresh: true);
    notifyListeners();
  }

  // --- Actions -------------------------------------------------------------

  Future<String?> confirmDetails({
    required String contactName,
    required String phone,
    required String location,
  }) =>
      _guard(() async {
        await _repo.confirmDetails(
          _registration!.id,
          contactName: contactName,
          phone: phone,
          location: location,
        );
        OnboardingAnalytics.log('details_confirmed');
        await _reload();
      });

  Future<String?> setPassword(String password) => _guard(() async {
        await _repo.setPassword(_registration!.id, password);
        OnboardingAnalytics.log('password_set');
        await _reload();
      });

  Future<RegistrationDocument?> uploadDocument({
    required String kind,
    required File file,
  }) async {
    try {
      return await _repo.uploadDocument(kind: kind, file: file);
    } catch (e) {
      _error = e is ArgumentError ? e.message.toString() : 'Upload failed. Try again.';
      notifyListeners();
      return null;
    }
  }

  Future<String?> submitDocuments(List<RegistrationDocument> docs) => _guard(() async {
        await _repo.submitDocuments(_registration!.id, docs);
        OnboardingAnalytics.log('documents_submitted');
        await _reload();
      });

  Future<void> _reload() async {
    _registration = await _repo.loadForCurrentUser();
    _listen();
  }

  /// Runs [action], surfacing a user-facing error string (null on success).
  Future<String?> _guard(Future<void> Function() action) async {
    _error = null;
    try {
      await action();
      notifyListeners();
      return null;
    } catch (e) {
      final msg = 'Something went wrong. Please try again.';
      _error = msg;
      notifyListeners();
      return msg;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
