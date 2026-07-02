import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/onboarding_provider.dart';
import '../../data/models/registration.dart';
import 'onboarding_widgets.dart';

/// Screen 5.2 — confirm pre-filled details. Rep-set fields (outlet, role) are
/// read-only; the vendor can edit their contact name, phone and building.
class ConfirmDetailsScreen extends StatefulWidget {
  const ConfirmDetailsScreen({super.key, required this.registration});
  final Registration registration;

  @override
  State<ConfirmDetailsScreen> createState() => _ConfirmDetailsScreenState();
}

class _ConfirmDetailsScreenState extends State<ConfirmDetailsScreen> {
  late final _name = TextEditingController(text: widget.registration.contactName);
  late final _phone = TextEditingController(text: widget.registration.phone);
  late final _location = TextEditingController(text: widget.registration.location);
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Please enter the contact person\'s name.');
      return;
    }
    if (_phone.text.trim().length < 8) {
      setState(() => _error = 'Please enter a valid phone number.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final err = await context.read<OnboardingProvider>().confirmDetails(
          contactName: _name.text.trim(),
          phone: _phone.text.trim(),
          location: _location.text.trim(),
        );
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _error = err;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = OnboardingColors.of(context);
    final r = widget.registration;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OnboardingStepHeader(
                step: 1,
                total: 4,
                title: 'Confirm your details',
                subtitle: 'Check everything looks right before we continue.',
              ),
              const SizedBox(height: 28),
              OnboardingInput(
                controller: _name,
                label: 'Contact person',
                icon: Icons.person_outline,
                hint: 'Full name',
              ),
              const SizedBox(height: 16),
              _ReadOnlyField(label: 'Email', value: r.email, icon: Icons.email_outlined),
              const SizedBox(height: 16),
              OnboardingInput(
                controller: _phone,
                label: 'Phone',
                icon: Icons.phone_outlined,
                hint: '+974 ...',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              _ReadOnlyField(
                label: 'Outlet',
                value: r.outletName.isEmpty ? r.outletId : r.outletName,
                icon: Icons.storefront_outlined,
              ),
              const SizedBox(height: 16),
              OnboardingInput(
                controller: _location,
                label: 'Building / location',
                icon: Icons.location_on_outlined,
                hint: 'e.g. Building B3',
              ),
              const SizedBox(height: 16),
              _ReadOnlyField(label: 'Role', value: r.role.label, icon: Icons.badge_outlined),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 28),
              OnboardingPrimaryButton(
                label: 'Confirm & continue',
                loading: _submitting,
                onPressed: _confirm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

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
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: c.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: c.textSecondary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(value,
                    style: TextStyle(color: c.textSecondary, fontSize: 15)),
              ),
              Icon(Icons.lock_outline, color: c.textSecondary, size: 16),
            ],
          ),
        ),
      ],
    );
  }
}
