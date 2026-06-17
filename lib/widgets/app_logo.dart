import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_colors.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 40, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.restaurant_menu_rounded, size: size, color: c),
        const SizedBox(width: 8),
        Text(
          'Uni Eats',
          style: GoogleFonts.fredoka(
            color: c,
            fontSize: size * 0.55,
            fontWeight: FontWeight.w600,
          ),
        ),
        Container(
          margin: const EdgeInsets.only(left: 6),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'vendor',
            style: GoogleFonts.plusJakartaSans(
              color: c,
              fontSize: size * 0.25,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}
