import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/onboarding_repository.dart';
import 'onboarding_widgets.dart';

/// Cold self-application (no invite). Collects contact details + the outlet the
/// applicant runs (free text — flagged for a rep to resolve against the campus
/// catalogue). Creates a pending registration; no account until approval.
class ColdApplyScreen extends StatefulWidget {
  const ColdApplyScreen({super.key});

  @override
  State<ColdApplyScreen> createState() => _ColdApplyScreenState();
}

class _ColdApplyScreenState extends State<ColdApplyScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _outlet = TextEditingController();
  bool _submitting = false;
  bool _done = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _outlet.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty ||
        !_email.text.contains('@') ||
        _phone.text.trim().length < 8 ||
        _outlet.text.trim().isEmpty) {
      setState(() => _error = 'Please fill in every field with valid details.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await OnboardingRepository.instance.submitColdApplication(
        contactName: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        outletRequest: _outlet.text.trim(),
      );
      if (!mounted) return;
      setState(() => _done = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Couldn\'t submit — check your connection and try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = OnboardingColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: c.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: _done ? _successBody(context, c) : _formBody(context, c),
      ),
    );
  }

  Widget _successBody(BuildContext context, OnboardingColors c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.mark_email_read_outlined, color: AppColors.success, size: 44),
          const SizedBox(height: 20),
          Text('Application received',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: c.textPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(
            'Thanks! Our team will review your request and email you a sign-in link once your outlet is set up.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: 28),
          OnboardingPrimaryButton(
            label: 'Done',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _formBody(BuildContext context, OnboardingColors c) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Apply for access',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: c.textPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Tell us about you and your outlet — we\'ll take it from there.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: c.textSecondary)),
          const SizedBox(height: 28),
          OnboardingInput(
              controller: _name, label: 'Your name', icon: Icons.person_outline, hint: 'Full name'),
          const SizedBox(height: 16),
          OnboardingInput(
              controller: _email,
              label: 'Email',
              icon: Icons.email_outlined,
              hint: 'you@example.com',
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 16),
          OnboardingInput(
              controller: _phone,
              label: 'Phone',
              icon: Icons.phone_outlined,
              hint: '+974 ...',
              keyboardType: TextInputType.phone),
          const SizedBox(height: 16),
          OnboardingInput(
              controller: _outlet,
              label: 'Your outlet',
              icon: Icons.storefront_outlined,
              hint: 'Restaurant / stall name'),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 28),
          OnboardingPrimaryButton(
            label: 'Submit application',
            loading: _submitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
