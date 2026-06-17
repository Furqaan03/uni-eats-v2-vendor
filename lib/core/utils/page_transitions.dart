import 'package:flutter/material.dart';

PageRouteBuilder<T> fadeSlidePage<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, animation, __) => page,
    transitionsBuilder: (_, animation, __, child) {
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      final slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
          .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
      return FadeTransition(opacity: fade, child: SlideTransition(position: slide, child: child));
    },
    transitionDuration: const Duration(milliseconds: 280),
  );
}
