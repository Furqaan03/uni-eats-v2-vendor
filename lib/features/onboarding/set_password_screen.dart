import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/onboarding_provider.dart';
import '../../core/theme/app_colors.dart';
import 'onboarding_widgets.dart';

/// Screen 5.3 — set (not change) a password against a live requirements
/// checklist. Submit stays disabled until all five rules pass. No wall of red.
class SetPasswordScreen extends StatefulWidget {
  const SetPasswordScreen({super.key});

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final _pass = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;
  String? _error;

  bool get _len => _pass.text.length >= 8;
  bool get _upper => _pass.text.contains(RegExp(r'[A-Z]'));
  bool get _lower => _pass.text.contains(RegExp(r'[a-z]'));
  bool get _digit => _pass.text.contains(RegExp(r'[0-9]'));
  bool get _symbol => _pass.text.contains(RegExp(r'[^A-Za-z0-9]'));
  bool get _allMet => _len && _upper && _lower && _digit && _symbol;

  @override
  void dispose() {
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_allMet) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final err = await context.read<OnboardingProvider>().setPassword(_pass.text);
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _error = err;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = OnboardingColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OnboardingStepHeader(
                step: 2,
                total: 4,
                title: 'Set your password',
                subtitle: 'You\'ll use this to sign in from any device.',
              ),
              const SizedBox(height: 28),
              OnboardingInput(
                controller: _pass,
                label: 'Password',
                icon: Icons.lock_outline,
                hint: 'Create a password',
                obscureText: _obscure,
                onChanged: (_) => setState(() {}),
                suffix: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: c.textSecondary,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              const SizedBox(height: 20),
              _Rule(met: _len, label: 'At least 8 characters'),
              _Rule(met: _upper, label: 'An uppercase letter'),
              _Rule(met: _lower, label: 'A lowercase letter'),
              _Rule(met: _digit, label: 'A number'),
              _Rule(met: _symbol, label: 'A symbol'),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 28),
              OnboardingPrimaryButton(
                label: 'Set password & continue',
                loading: _submitting,
                onPressed: _allMet ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.met, required this.label});
  final bool met;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = OnboardingColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: met ? AppColors.success : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: met ? AppColors.success : c.border, width: 1.5),
            ),
            child: met
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: met ? c.textPrimary : c.textSecondary,
              fontSize: 14,
              fontWeight: met ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
