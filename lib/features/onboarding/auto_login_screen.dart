import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/vendor_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/page_transitions.dart';
import '../../data/repositories/onboarding_repository.dart';
import '../auth/login_screen.dart';
import 'onboarding_widgets.dart';
import 'pending_shell.dart';

/// Screen 5.1 — auto-login handoff. Consumes the single-use token from the
/// invite deep link, signs in, and routes into the pending shell (which then
/// routes on the claim). Expired/used links show a recovery screen.
class AutoLoginScreen extends StatefulWidget {
  const AutoLoginScreen({
    super.key,
    required this.registrationId,
    required this.secret,
    required this.env,
  });

  final String registrationId;
  final String secret;
  final String env;

  @override
  State<AutoLoginScreen> createState() => _AutoLoginScreenState();
}

enum _State { working, expired, error }

class _AutoLoginScreenState extends State<AutoLoginScreen> {
  _State _state = _State.working;
  bool _resending = false;
  String? _resendMessage;

  @override
  void initState() {
    super.initState();
    _consume();
  }

  Future<void> _consume() async {
    setState(() => _state = _State.working);
    try {
      await OnboardingRepository.instance.consumeLoginToken(
        registrationId: widget.registrationId,
        secret: widget.secret,
        env: widget.env,
      );
      if (!mounted) return;
      // Reset any stale active-restaurant selection from a prior session.
      context.read<VendorProvider>();
      Navigator.of(context).pushReplacement(fadeSlidePage(const VendorPendingShell()));
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() => _state =
          (e.code == 'failed-precondition' || e.message == 'expired') ? _State.expired : _State.error);
    } on FirebaseAuthException catch (e) {
      // Spark-plan links carry the custom token itself; Firebase rejects it
      // after 1 hour with invalid-custom-token → same "expired" UX.
      if (!mounted) return;
      setState(() => _state =
          (e.code == 'invalid-custom-token' || e.code == 'custom-token-mismatch')
              ? _State.expired
              : _State.error);
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = _State.error);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _resendMessage = null;
    });
    try {
      await OnboardingRepository.instance.resendLoginLink(
        registrationId: widget.registrationId,
        env: widget.env,
      );
      if (!mounted) return;
      setState(() => _resendMessage = 'A fresh sign-in link is on its way to your email.');
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() => _resendMessage = e.code == 'resource-exhausted'
          ? 'Too many requests — please try again later.'
          : 'Couldn\'t resend the link. Try again.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _resendMessage = 'Couldn\'t resend the link. Try again.');
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = OnboardingColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Center(
            child: _state == _State.working
                ? const _Working()
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.link_off_rounded, color: c.textSecondary, size: 44),
                      const SizedBox(height: 20),
                      Text(
                        _state == _State.expired
                            ? 'This link has expired'
                            : 'We couldn\'t sign you in',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(color: c.textPrimary, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _state == _State.expired
                            ? 'Sign-in links are single-use and expire after an hour. Send a fresh one, or sign in with your password.'
                            : 'Something went wrong opening your link. Try again or sign in with your password.',
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(color: c.textSecondary),
                      ),
                      const SizedBox(height: 28),
                      OnboardingPrimaryButton(
                        label: 'Send a fresh link',
                        loading: _resending,
                        onPressed: _resend,
                      ),
                      if (_resendMessage != null) ...[
                        const SizedBox(height: 12),
                        Text(_resendMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: c.textSecondary, fontSize: 13)),
                      ],
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.of(context)
                            .pushReplacement(fadeSlidePage(const VendorLoginScreen())),
                        child: const Text('Sign in with your password',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _Working extends StatelessWidget {
  const _Working();

  @override
  Widget build(BuildContext context) {
    final c = OnboardingColors.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: AppColors.primary),
        const SizedBox(height: 24),
        Text('Signing you in…',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: c.textSecondary)),
      ],
    );
  }
}
