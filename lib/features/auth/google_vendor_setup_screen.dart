import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/providers/vendor_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/page_transitions.dart';
import '../navigation/main_nav_shell.dart';
import 'signup_screen.dart' show kVendorSignupRestaurants;

/// Shown the first time a vendor signs in with a Google account that has no
/// existing vendor record — picks which restaurant they manage, then
/// finishes account creation.
class GoogleVendorSetupScreen extends StatefulWidget {
  final String email;
  const GoogleVendorSetupScreen({super.key, required this.email});

  @override
  State<GoogleVendorSetupScreen> createState() => _GoogleVendorSetupScreenState();
}

class _GoogleVendorSetupScreenState extends State<GoogleVendorSetupScreen> {
  ({String id, String name, String location})? _selected;
  bool _submitting = false;
  String? _error;

  Future<void> _continue() async {
    final selected = _selected;
    if (selected == null) {
      setState(() => _error = 'Please select your restaurant.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });

    final error = await context.read<VendorAuthProvider>().completeGoogleSignup(
          email: widget.email,
          restaurantId: selected.id,
          restaurantName: selected.name,
          restaurantLocation: selected.location,
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (error != null) {
      setState(() => _error = error);
      return;
    }

    final session = context.read<VendorAuthProvider>().session!;
    context.read<VendorProvider>().setRestaurant(
          id: session.restaurantId,
          name: session.restaurantName,
          location: session.restaurantLocation,
        );
    Navigator.of(context).pushReplacement(fadeSlidePage(const MainNavShell()));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final surface = isDark ? AppColors.darkSurface : AppColors.white;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(backgroundColor: bg, elevation: 0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Almost there',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(color: textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'Which restaurant do you manage, ${widget.email}?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textSecondary),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: kVendorSignupRestaurants.map((r) {
                    final selected = _selected?.id == r.id;
                    return GestureDetector(
                      onTap: () => setState(() => _selected = r),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary.withValues(alpha: 0.08) : surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected ? AppColors.primary : border,
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.storefront_outlined,
                              color: selected ? AppColors.primary : textSecondary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.name,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: textPrimary,
                                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                        ),
                                  ),
                                  Text(
                                    r.location,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            if (selected) Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              if (_error != null) ...[
                Text(_error!, style: TextStyle(color: AppColors.error, fontSize: 13)),
                const SizedBox(height: 8),
              ],
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Continue'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
