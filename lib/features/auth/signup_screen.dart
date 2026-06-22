import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/vendor_provider.dart';
import '../../widgets/app_logo.dart';
import '../../core/utils/page_transitions.dart';
import '../navigation/main_nav_shell.dart';

// Restaurant choices that match the mock data — also reused by the Google
// sign-in first-time setup screen.
const kVendorSignupRestaurants = [
  (id: 'r001', name: 'Tim Hortons', location: 'Building B3'),
  (id: 'r002', name: 'Oakberry', location: 'Building B3'),
  (id: 'r003', name: 'Edge Cafe', location: 'Building B9'),
  (id: 'r004', name: 'Caribou Coffee', location: 'Building E4'),
  (id: 'r005', name: 'JamKai', location: 'Building B20'),
  (id: 'r006', name: 'Bold Café', location: 'Atrium 5'),
  (id: 'r007', name: "L'Hardy", location: 'Building B12'),
  (id: 'r008', name: 'Ennabi 92', location: 'Building B4'),
];
const _kRestaurants = kVendorSignupRestaurants;

class VendorSignupScreen extends StatefulWidget {
  const VendorSignupScreen({super.key});

  @override
  State<VendorSignupScreen> createState() => _VendorSignupScreenState();
}

class _VendorSignupScreenState extends State<VendorSignupScreen> {
  int _step = 0; // 0=personal, 1=restaurant, 2=contact, 3=review, 4=pending

  // Step 0
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passConfirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  // Step 1
  ({String id, String name, String location})? _selectedRestaurant;
  final _roleCtrl = TextEditingController();

  // Step 2
  final _phoneCtrl = TextEditingController();

  String? _stepError;
  bool _submitting = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _passConfirmCtrl.dispose();
    _roleCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  String? _validateStep() {
    switch (_step) {
      case 0:
        if (_nameCtrl.text.trim().isEmpty) return 'Full name is required.';
        if (!_emailCtrl.text.contains('@')) return 'Enter a valid email address.';
        if (_passCtrl.text.length < 6) return 'Password must be at least 6 characters.';
        if (_passCtrl.text != _passConfirmCtrl.text) return 'Passwords do not match.';
        return null;
      case 1:
        if (_selectedRestaurant == null) return 'Please select your restaurant.';
        if (_roleCtrl.text.trim().isEmpty) return 'Please enter your role.';
        return null;
      case 2:
        if (_phoneCtrl.text.trim().length < 8) return 'Enter a valid phone number.';
        return null;
      default:
        return null;
    }
  }

  void _next() {
    final err = _validateStep();
    if (err != null) {
      setState(() => _stepError = err);
      return;
    }
    setState(() {
      _stepError = null;
      _step++;
    });
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);

    final error = await context.read<VendorAuthProvider>().signUp(
          email: _emailCtrl.text,
          password: _passCtrl.text,
          restaurantId: _selectedRestaurant!.id,
          restaurantName: _selectedRestaurant!.name,
          restaurantLocation: _selectedRestaurant!.location,
        );

    if (!mounted) return;
    if (error != null) {
      setState(() {
        _submitting = false;
        _stepError = error;
      });
      return;
    }

    setState(() {
      _submitting = false;
      _stepError = null;
      _step = 4; // pending approval screen
    });
  }

  // Mock admin approval — just admit them straight in
  void _continueToApp() {
    final session = context.read<VendorAuthProvider>().session;
    if (session != null) {
      context.read<VendorProvider>().setRestaurant(
            id: session.restaurantId,
            name: session.restaurantName,
            location: session.restaurantLocation,
          );
    }
    Navigator.of(context).pushReplacement(fadeSlidePage(const MainNavShell()));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: _step == 4 ? _PendingScreen(onContinue: _continueToApp) : _FormContent(
          step: _step,
          onNext: _next,
          onBack: _back,
          onSubmit: _submit,
          submitting: _submitting,
          stepError: _stepError,
          nameCtrl: _nameCtrl,
          emailCtrl: _emailCtrl,
          passCtrl: _passCtrl,
          passConfirmCtrl: _passConfirmCtrl,
          obscurePass: _obscurePass,
          obscureConfirm: _obscureConfirm,
          onTogglePass: () => setState(() => _obscurePass = !_obscurePass),
          onToggleConfirm: () => setState(() => _obscureConfirm = !_obscureConfirm),
          selectedRestaurant: _selectedRestaurant,
          onSelectRestaurant: (r) => setState(() => _selectedRestaurant = r),
          roleCtrl: _roleCtrl,
          phoneCtrl: _phoneCtrl,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main form scaffold
// ─────────────────────────────────────────────────────────────────────────────

class _FormContent extends StatelessWidget {
  final int step;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final Future<void> Function() onSubmit;
  final bool submitting;
  final String? stepError;

  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final TextEditingController passConfirmCtrl;
  final bool obscurePass;
  final bool obscureConfirm;
  final VoidCallback onTogglePass;
  final VoidCallback onToggleConfirm;

  final ({String id, String name, String location})? selectedRestaurant;
  final void Function(({String id, String name, String location})?) onSelectRestaurant;
  final TextEditingController roleCtrl;
  final TextEditingController phoneCtrl;

  const _FormContent({
    required this.step,
    required this.onNext,
    required this.onBack,
    required this.onSubmit,
    required this.submitting,
    required this.stepError,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.passCtrl,
    required this.passConfirmCtrl,
    required this.obscurePass,
    required this.obscureConfirm,
    required this.onTogglePass,
    required this.onToggleConfirm,
    required this.selectedRestaurant,
    required this.onSelectRestaurant,
    required this.roleCtrl,
    required this.phoneCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.white;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    final stepTitles = ['Personal Info', 'Restaurant', 'Contact', 'Review'];
    final totalSteps = stepTitles.length;

    Widget body;
    switch (step) {
      case 0:
        body = _StepPersonal(
          nameCtrl: nameCtrl,
          emailCtrl: emailCtrl,
          passCtrl: passCtrl,
          passConfirmCtrl: passConfirmCtrl,
          obscurePass: obscurePass,
          obscureConfirm: obscureConfirm,
          onTogglePass: onTogglePass,
          onToggleConfirm: onToggleConfirm,
          surface: surface,
          border: border,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        );
      case 1:
        body = _StepRestaurant(
          selectedRestaurant: selectedRestaurant,
          onSelectRestaurant: onSelectRestaurant,
          roleCtrl: roleCtrl,
          surface: surface,
          border: border,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        );
      case 2:
        body = _StepContact(
          phoneCtrl: phoneCtrl,
          surface: surface,
          border: border,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        );
      default:
        body = _StepReview(
          name: nameCtrl.text,
          email: emailCtrl.text,
          restaurant: selectedRestaurant,
          role: roleCtrl.text,
          phone: phoneCtrl.text,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          surface: surface,
          border: border,
        );
    }

    return Column(
      children: [
        // App bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (step > 0)
                IconButton(
                  icon: Icon(Icons.arrow_back_ios_new, color: textPrimary, size: 18),
                  onPressed: onBack,
                )
              else
                IconButton(
                  icon: Icon(Icons.close, color: textSecondary, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              const Spacer(),
              AppLogo(size: 24, color: AppColors.primary),
              const Spacer(),
              // Step counter
              Text(
                '${step + 1} / $totalSteps',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: textSecondary),
              ),
            ],
          ),
        ),

        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (step + 1) / totalSteps,
              backgroundColor: isDark ? AppColors.darkSurfaceAlt : AppColors.lightBorder,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            stepTitles[step],
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.primary),
          ),
        ),

        // Form body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: body,
          ),
        ),

        // Error + button
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            children: [
              if (stepError != null) ...[
                Text(
                  stepError!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: submitting ? null : (step == 3 ? onSubmit : onNext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          step == 3 ? 'Submit Application' : 'Continue',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 0: Personal Info
// ─────────────────────────────────────────────────────────────────────────────

class _StepPersonal extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final TextEditingController passConfirmCtrl;
  final bool obscurePass;
  final bool obscureConfirm;
  final VoidCallback onTogglePass;
  final VoidCallback onToggleConfirm;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;

  const _StepPersonal({
    required this.nameCtrl,
    required this.emailCtrl,
    required this.passCtrl,
    required this.passConfirmCtrl,
    required this.obscurePass,
    required this.obscureConfirm,
    required this.onTogglePass,
    required this.onToggleConfirm,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Create your account', context, textPrimary),
        const SizedBox(height: 4),
        _sectionSubtitle('Tell us about yourself.', context, textSecondary),
        const SizedBox(height: 24),
        _label('Full Name', context, textPrimary),
        const SizedBox(height: 8),
        _Field(
          controller: nameCtrl,
          hint: 'Your full name',
          icon: Icons.person_outline,
          surface: surface,
          border: border,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),
        const SizedBox(height: 16),
        _label('Work Email', context, textPrimary),
        const SizedBox(height: 8),
        _Field(
          controller: emailCtrl,
          hint: 'you@udst.edu.qa',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          surface: surface,
          border: border,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),
        const SizedBox(height: 16),
        _label('Password', context, textPrimary),
        const SizedBox(height: 8),
        _Field(
          controller: passCtrl,
          hint: 'At least 6 characters',
          icon: Icons.lock_outline,
          obscureText: obscurePass,
          surface: surface,
          border: border,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          suffix: IconButton(
            icon: Icon(
              obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: textSecondary,
              size: 20,
            ),
            onPressed: onTogglePass,
          ),
        ),
        const SizedBox(height: 16),
        _label('Confirm Password', context, textPrimary),
        const SizedBox(height: 8),
        _Field(
          controller: passConfirmCtrl,
          hint: 'Re-enter password',
          icon: Icons.lock_outline,
          obscureText: obscureConfirm,
          surface: surface,
          border: border,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          suffix: IconButton(
            icon: Icon(
              obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: textSecondary,
              size: 20,
            ),
            onPressed: onToggleConfirm,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 1: Restaurant Selection
// ─────────────────────────────────────────────────────────────────────────────

class _StepRestaurant extends StatelessWidget {
  final ({String id, String name, String location})? selectedRestaurant;
  final void Function(({String id, String name, String location})?) onSelectRestaurant;
  final TextEditingController roleCtrl;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;

  const _StepRestaurant({
    required this.selectedRestaurant,
    required this.onSelectRestaurant,
    required this.roleCtrl,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Your Restaurant', context, textPrimary),
        const SizedBox(height: 4),
        _sectionSubtitle('Select the restaurant you work at.', context, textSecondary),
        const SizedBox(height: 24),
        ..._kRestaurants.map((r) {
          final selected = selectedRestaurant?.id == r.id;
          return GestureDetector(
            onTap: () => onSelectRestaurant(r),
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
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        _label('Your Role / Position', context, textPrimary),
        const SizedBox(height: 8),
        _Field(
          controller: roleCtrl,
          hint: 'e.g. Manager, Cashier',
          icon: Icons.badge_outlined,
          surface: surface,
          border: border,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 2: Contact
// ─────────────────────────────────────────────────────────────────────────────

class _StepContact extends StatelessWidget {
  final TextEditingController phoneCtrl;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;

  const _StepContact({
    required this.phoneCtrl,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Contact Details', context, textPrimary),
        const SizedBox(height: 4),
        _sectionSubtitle('So we can reach you about your application.', context, textSecondary),
        const SizedBox(height: 24),
        _label('Phone Number', context, textPrimary),
        const SizedBox(height: 8),
        _Field(
          controller: phoneCtrl,
          hint: '+974 XXXX XXXX',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          surface: surface,
          border: border,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 3: Review
// ─────────────────────────────────────────────────────────────────────────────

class _StepReview extends StatelessWidget {
  final String name;
  final String email;
  final ({String id, String name, String location})? restaurant;
  final String role;
  final String phone;
  final Color textPrimary;
  final Color textSecondary;
  final Color surface;
  final Color border;

  const _StepReview({
    required this.name,
    required this.email,
    required this.restaurant,
    required this.role,
    required this.phone,
    required this.textPrimary,
    required this.textSecondary,
    required this.surface,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Review & Submit', context, textPrimary),
        const SizedBox(height: 4),
        _sectionSubtitle('Confirm your details before sending.', context, textSecondary),
        const SizedBox(height: 24),
        _ReviewCard(
          surface: surface,
          border: border,
          children: [
            _reviewRow('Name', name, textPrimary, textSecondary, context),
            _reviewRow('Email', email, textPrimary, textSecondary, context),
            _reviewRow('Restaurant', restaurant?.name ?? '–', textPrimary, textSecondary, context),
            _reviewRow('Location', restaurant?.location ?? '–', textPrimary, textSecondary, context),
            _reviewRow('Role', role, textPrimary, textSecondary, context),
            _reviewRow('Phone', phone, textPrimary, textSecondary, context, last: true),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: AppColors.primary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Your application will be reviewed by an admin. You will receive access shortly after approval.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: textSecondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Color surface;
  final Color border;
  final List<Widget> children;

  const _ReviewCard({required this.surface, required this.border, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(children: children),
    );
  }
}

Widget _reviewRow(String label, String value, Color textPrimary, Color textSecondary,
    BuildContext context, {bool last = false}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    decoration: BoxDecoration(
      border: last ? null : Border(bottom: BorderSide(color: textSecondary.withValues(alpha: 0.12))),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '–' : value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textPrimary, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Step 4: Pending Approval
// ─────────────────────────────────────────────────────────────────────────────

class _PendingScreen extends StatelessWidget {
  final VoidCallback onContinue;

  const _PendingScreen({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated check / pending icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                ),
                child: const Icon(Icons.how_to_reg_outlined, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 32),
              Text(
                'Application Submitted',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(color: textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your vendor application is under review. Our admin team will verify your details and grant access shortly.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: textSecondary, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Mock: immediate approval notice
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline, color: AppColors.success, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Access approved — welcome aboard!',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.success),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'Continue to App',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget _sectionTitle(String text, BuildContext context, Color color) =>
    Text(text, style: Theme.of(context).textTheme.displayMedium?.copyWith(color: color));

Widget _sectionSubtitle(String text, BuildContext context, Color color) =>
    Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color));

Widget _label(String text, BuildContext context, Color color) =>
    Text(text, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color));

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Widget? suffix;

  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
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
        style: TextStyle(color: textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: textPrimary.withValues(alpha: 0.4), fontSize: 15),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
