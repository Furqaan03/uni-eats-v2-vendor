import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/onboarding_provider.dart';
import '../../core/providers/vendor_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/page_transitions.dart';
import '../../data/repositories/onboarding_repository.dart';
import '../navigation/main_nav_shell.dart';
import 'confirm_details_screen.dart';
import 'pending_status_screen.dart';
import 'set_password_screen.dart';
import 'upload_documents_screen.dart';

/// The pending shell — the ONLY route tree a non-approved vendor can reach.
/// No bottom nav, no orders, no menu, no payouts. The Phase 0 security rules
/// are what actually keep a pending account out of real data; this is UX.
class VendorPendingShell extends StatelessWidget {
  const VendorPendingShell({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<OnboardingProvider>(
      create: (_) => OnboardingProvider()..load(),
      child: const _PendingShellBody(),
    );
  }
}

class _PendingShellBody extends StatelessWidget {
  const _PendingShellBody();

  void _enterFullApp(BuildContext context, OnboardingProvider prov) {
    final r = prov.registration;
    if (r != null) {
      context.read<VendorProvider>().setRestaurant(
            id: r.outletId,
            name: r.outletName.isEmpty ? r.outletId : r.outletName,
            location: r.location,
          );
    }
    Navigator.of(context).pushReplacement(fadeSlidePage(const MainNavShell()));
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<OnboardingProvider>();

    // Approval unlocks the full app in place — no re-login. Route once the
    // claim has flipped to approved.
    if (prov.access == VendorAccess.approved && prov.registration != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) _enterFullApp(context, prov);
      });
    }

    if (prov.loading && prov.registration == null) {
      return const Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (prov.access == VendorAccess.rejected) {
      return RejectedScreen(note: prov.registration?.adminNote ?? '');
    }

    final r = prov.registration;
    if (r == null) {
      return _ErrorState(message: prov.error ?? 'We couldn\'t find your application.');
    }

    return switch (prov.step) {
      OnboardingStep.confirmDetails => ConfirmDetailsScreen(registration: r),
      OnboardingStep.setPassword => const SetPasswordScreen(),
      OnboardingStep.uploadDocuments => UploadDocumentsScreen(registration: r),
      OnboardingStep.status => PendingStatusScreen(
          onApproved: () => _enterFullApp(context, prov),
        ),
    };
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.darkTextSecondary)),
          ),
        ),
      ),
    );
  }
}
