import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/vendor_provider.dart';
import '../../core/utils/page_transitions.dart';
import '../../widgets/app_logo.dart';
import '../onboarding/onboarding_screen.dart';
import '../auth/login_screen.dart';
import '../navigation/main_nav_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.firebaseReady});
  final Future<void> firebaseReady;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  late final Animation<double> _logoFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
  );
  late final Animation<double> _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
    CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack)),
  );
  late final Animation<double> _taglineFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.35, 0.75, curve: Curves.easeOut),
  );
  late final Animation<Offset> _taglineSlide = Tween<Offset>(
    begin: const Offset(0, 0.3),
    end: Offset.zero,
  ).animate(_taglineFade);
  late final Animation<double> _dotsFade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _init();
  }

  Future<void> _init() async {
    // Run Firebase init, prefs read, and minimum splash duration in parallel.
    final results = await Future.wait([
      widget.firebaseReady,
      SharedPreferences.getInstance(),
      Future<void>.delayed(const Duration(milliseconds: 1000)),
    ]);
    if (!mounted) return;
    final prefs = results[1] as SharedPreferences;
    final seenOnboarding = prefs.getBool('vendor_seen_onboarding') ?? false;

    if (!seenOnboarding) {
      Navigator.of(context).pushReplacement(fadeSlidePage(const VendorOnboardingScreen()));
      return;
    }

    // Try auto-login from saved credentials.
    final auth = context.read<VendorAuthProvider>();
    final session = await auth.tryAutoSignIn();
    if (!mounted) return;

    if (session != null) {
      context.read<VendorProvider>().setRestaurant(
            id: session.restaurantId,
            name: session.restaurantName,
            location: session.restaurantLocation,
          );
      Navigator.of(context).pushReplacement(fadeSlidePage(const MainNavShell()));
    } else {
      Navigator.of(context).pushReplacement(fadeSlidePage(const VendorLoginScreen()));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: const AppLogo(size: 52, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeTransition(
                    opacity: _taglineFade,
                    child: SlideTransition(
                      position: _taglineSlide,
                      child: Text.rich(
                        TextSpan(
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.darkTextSecondary,
                            fontSize: 14,
                          ),
                          children: [
                            const TextSpan(text: 'Your Kitchen. '),
                            TextSpan(
                              text: 'Your Control.',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppColors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 40,
              child: FadeTransition(
                opacity: _dotsFade,
                child: const Center(child: _LoadingDots()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_controller.value + i * 0.2) % 1.0;
            final scale = 0.6 + 0.4 * (0.5 + 0.5 * math.sin(2 * math.pi * phase));
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
