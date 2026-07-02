import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Shared building blocks for the pending-shell onboarding screens so they
/// share one look with the login screen (dark/light aware, same radii/colors).

class OnboardingColors {
  final Color bg, surface, textPrimary, textSecondary, border;
  const OnboardingColors._(
      this.bg, this.surface, this.textPrimary, this.textSecondary, this.border);

  factory OnboardingColors.of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return OnboardingColors._(
      dark ? AppColors.darkBackground : AppColors.lightBackground,
      dark ? AppColors.darkSurface : AppColors.white,
      dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
      dark ? AppColors.darkBorder : AppColors.lightBorder,
    );
  }
}

/// Honest step counter — "Step N of 4".
class OnboardingStepHeader extends StatelessWidget {
  const OnboardingStepHeader({
    super.key,
    required this.step,
    required this.total,
    required this.title,
    required this.subtitle,
  });

  final int step;
  final int total;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final c = OnboardingColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(total, (i) {
            final done = i < step;
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
                decoration: BoxDecoration(
                  color: done ? AppColors.primary : c.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        Text('Step $step of $total',
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w700,
                )),
        const SizedBox(height: 6),
        Text(subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: c.textSecondary)),
      ],
    );
  }
}

class OnboardingInput extends StatelessWidget {
  const OnboardingInput({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.enabled = true,
    this.suffix,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool enabled;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = OnboardingColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: c.textPrimary)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: enabled ? c.surface : c.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border),
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            obscureText: obscureText,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: TextStyle(color: c.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: c.textPrimary.withValues(alpha: 0.4), fontSize: 15),
              prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
              suffixIcon: suffix,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class OnboardingPrimaryButton extends StatelessWidget {
  const OnboardingPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(label,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
