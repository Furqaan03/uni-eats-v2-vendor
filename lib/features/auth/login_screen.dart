import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/vendor_provider.dart';
import '../../widgets/app_logo.dart';
import '../navigation/main_nav_shell.dart';
import '../auth/signup_screen.dart';
import '../../core/utils/page_transitions.dart';
import 'google_vendor_setup_screen.dart';

class VendorLoginScreen extends StatefulWidget {
  const VendorLoginScreen({super.key});

  @override
  State<VendorLoginScreen> createState() => _VendorLoginScreenState();
}

class _VendorLoginScreenState extends State<VendorLoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _googleLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final auth = context.read<VendorAuthProvider>();
    final error = await auth.signIn(_emailCtrl.text, _passwordCtrl.text);

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      setState(() => _error = error);
      return;
    }

    if (!mounted) return;
    final session = auth.session!;
    context.read<VendorProvider>().setRestaurant(
          id: session.restaurantId,
          name: session.restaurantName,
          location: session.restaurantLocation,
        );

    Navigator.of(context).pushReplacement(fadeSlidePage(const MainNavShell()));
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _googleLoading = true;
      _error = null;
    });

    final auth = context.read<VendorAuthProvider>();
    final result = await auth.signInWithGoogle();

    if (!mounted) return;
    setState(() => _googleLoading = false);

    if (result.error != null) {
      setState(() => _error = result.error);
      return;
    }

    if (result.pendingEmail != null) {
      Navigator.of(context)
          .push(fadeSlidePage(GoogleVendorSetupScreen(email: result.pendingEmail!)));
      return;
    }

    final session = auth.session!;
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 56),

              // Logo — AppLogo already includes "Uni Eats vendor"
              AppLogo(size: 36, color: AppColors.primary),

              const SizedBox(height: 48),
              Text(
                'Welcome back',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(color: textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'Sign in to manage your restaurant',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textSecondary),
              ),
              const SizedBox(height: 36),

              // Email
              Text('Email',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: textPrimary)),
              const SizedBox(height: 8),
              _InputField(
                controller: _emailCtrl,
                hint: 'restaurant@testrun.qa',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                surface: surface,
                border: border,
                textColor: textPrimary,
              ),
              const SizedBox(height: 16),

              // Password
              Text('Password',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: textPrimary)),
              const SizedBox(height: 8),
              _InputField(
                controller: _passwordCtrl,
                hint: '••••••••',
                icon: Icons.lock_outline,
                obscureText: _obscure,
                surface: surface,
                border: border,
                textColor: textPrimary,
                suffix: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: textSecondary,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.error)),
              ],

              const SizedBox(height: 20),

              // Sign In button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _signIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text('Sign In',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: Colors.white)),
                ),
              ),

              const SizedBox(height: 16),

              // Or divider
              Row(
                children: [
                  Expanded(child: Divider(color: border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: textSecondary)),
                  ),
                  Expanded(child: Divider(color: border)),
                ],
              ),
              const SizedBox(height: 16),

              // Continue with Google
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _googleLoading ? null : _signInWithGoogle,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _googleLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: textSecondary),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.g_mobiledata_rounded, color: textPrimary, size: 26),
                            const SizedBox(width: 6),
                            Text('Continue with Google',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: textPrimary)),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Sign Up link
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(fadeSlidePage(const VendorSignupScreen())),
                  child: RichText(
                    text: TextSpan(
                      text: "New vendor? ",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textSecondary),
                      children: [
                        TextSpan(
                          text: 'Apply for access',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),
              Center(
                child: Text(
                  'Vendor portal · UDST Campus',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: textSecondary),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final Color surface;
  final Color border;
  final Color textColor;
  final Widget? suffix;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    required this.surface,
    required this.border,
    required this.textColor,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: TextStyle(color: textColor, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: textColor.withValues(alpha: 0.4), fontSize: 15),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
