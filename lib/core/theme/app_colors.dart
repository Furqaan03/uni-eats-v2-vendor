import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFFFF7A00);
  static const Color primaryLight = Color(0xFFFFAA4D);
  static const Color primaryDark = Color(0xFFCC5500);
  static const Color accent = Color(0xFF02BA26);
  static const Color accentLight = Color(0xFF4AE56B);

  // Neutrals
  static const Color black = Color(0xFF000000);
  static const Color charcoal = Color(0xFF2D2D2D);
  static const Color lightGrey = Color(0xFFE0E0E0);
  static const Color offWhite = Color(0xFFF4F4F4);
  static const Color white = Color(0xFFFFFFFF);

  // Semantic
  static const Color success = accent;
  static const Color warning = primary;
  static const Color error = Color(0xFFE0453F);
  static const Color star = Color(0xFFFFB020);
  static const Color info = Color(0xFF2196F3);

  // Order status colours
  static const Color statusNew = Color(0xFF2196F3);
  static const Color statusPreparing = primary;
  static const Color statusReady = accent;
  static const Color statusDelivered = Color(0xFF8A8A8A);

  // Light surfaces
  static const Color lightBackground = offWhite;
  static const Color lightSurface = Color(0xFFFAFAF8);
  static const Color lightSurfaceAlt = Color(0xFFECECE9);
  static const Color lightBorder = Color(0xFFD0D0CE);
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF555555);

  // Dark surfaces – elevated charcoal with a hint of warmth
  static const Color darkBackground = Color(0xFF1C1917);
  static const Color darkSurface = Color(0xFF292524);
  static const Color darkSurfaceAlt = Color(0xFF3A3330);
  static const Color darkBorder = Color(0xFF4A4440);
  static const Color darkTextPrimary = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFFB0ABAA);

  // Tints for badges/chips
  static const Color primaryTintLight = Color(0xFFFFEDD6);
  static const Color primaryTintDark = Color(0xFF3D1F00);
  static const Color accentTintLight = Color(0xFFE3F8E7);
  static const Color accentTintDark = Color(0xFF15301C);
  static const Color errorTintLight = Color(0xFFFFECEB);
  static const Color infoTintLight = Color(0xFFE3F2FD);
  static const Color infoTintDark = Color(0xFF0D2137);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryLight, primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkHeroGradient = LinearGradient(
    colors: [Color(0xFF3D1F00), darkBackground],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient lightHeroGradient = LinearGradient(
    colors: [primaryLight, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<BoxShadow> glow(Color color, {double opacity = 0.35}) => [
        BoxShadow(
          color: color.withValues(alpha: opacity),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
}
