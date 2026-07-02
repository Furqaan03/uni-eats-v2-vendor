import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/providers/onboarding_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/onboarding_repository.dart';
import 'onboarding_widgets.dart';

/// Screen 5.5 — honest single-state status. Never shows "approved" and "under
/// review" together. Approval routing happens above this screen (root reacts to
/// the claim flip); the "continue" button is a manual fallback.
class PendingStatusScreen extends StatelessWidget {
  const PendingStatusScreen({super.key, required this.onApproved});
  final VoidCallback onApproved;

  @override
  Widget build(BuildContext context) {
    final c = OnboardingColors.of(context);
    final prov = context.watch<OnboardingProvider>();
    final approved = prov.access == VendorAccess.approved;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: (approved ? AppColors.success : AppColors.primary).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  approved ? Icons.check_circle_outline : Icons.hourglass_top_rounded,
                  color: approved ? AppColors.success : AppColors.primary,
                  size: 44,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                approved ? 'You\'re approved' : 'Under review',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(color: c.textPrimary, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                approved
                    ? 'Your account is live. Continue to your dashboard.'
                    : 'Your application has been submitted. We\'ll email you the moment you\'re approved — no need to keep this open.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: 32),
              if (approved)
                OnboardingPrimaryButton(label: 'Continue', onPressed: onApproved)
              else ...[
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
                const SizedBox(height: 40),
                TextButton(
                  onPressed: () async {
                    await context.read<VendorAuthProvider>().signOut();
                  },
                  child: Text('Sign out',
                      style: TextStyle(color: c.textSecondary)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Terminal rejected screen — no app access, support contact only.
class RejectedScreen extends StatelessWidget {
  const RejectedScreen({super.key, this.note = ''});
  final String note;

  @override
  Widget build(BuildContext context) {
    final c = OnboardingColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, color: c.textSecondary, size: 44),
              const SizedBox(height: 24),
              Text('Application not approved',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(color: c.textPrimary, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              Text(
                note.isNotEmpty
                    ? note
                    : 'Unfortunately we couldn\'t approve your application. Please contact our team if you believe this is a mistake.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: 28),
              Text('support@theunieats.com',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () => context.read<VendorAuthProvider>().signOut(),
                child: Text('Sign out', style: TextStyle(color: c.textSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
