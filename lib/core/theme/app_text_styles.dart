import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle _display(Color color) => GoogleFonts.fredoka(color: color);
  static TextStyle _body(Color color) => GoogleFonts.plusJakartaSans(color: color);

  static TextTheme textTheme(Color primaryText, Color secondaryText) {
    return TextTheme(
      displayLarge: _display(primaryText).copyWith(fontSize: 36, fontWeight: FontWeight.w600),
      displayMedium: _display(primaryText).copyWith(fontSize: 30, fontWeight: FontWeight.w600),
      headlineLarge: _display(primaryText).copyWith(fontSize: 24, fontWeight: FontWeight.w600),
      headlineMedium: _display(primaryText).copyWith(fontSize: 20, fontWeight: FontWeight.w600),
      titleLarge: _body(primaryText).copyWith(fontSize: 18, fontWeight: FontWeight.w600),
      titleMedium: _body(primaryText).copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge: _body(primaryText).copyWith(fontSize: 16, fontWeight: FontWeight.w400),
      bodyMedium: _body(primaryText).copyWith(fontSize: 14, fontWeight: FontWeight.w400),
      bodySmall: _body(secondaryText).copyWith(fontSize: 12, fontWeight: FontWeight.w400),
      labelLarge: _body(primaryText).copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      labelMedium: _body(secondaryText).copyWith(fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: _body(secondaryText).copyWith(fontSize: 11, fontWeight: FontWeight.w500),
    );
  }

  static TextTheme get light => textTheme(AppColors.lightTextPrimary, AppColors.lightTextSecondary);
  static TextTheme get dark => textTheme(AppColors.darkTextPrimary, AppColors.darkTextSecondary);
}
