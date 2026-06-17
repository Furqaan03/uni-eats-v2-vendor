import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/nav_provider.dart';
import 'core/providers/vendor_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/splash/splash_screen.dart';

void main() {
  runApp(const UniEatsVendorApp());
}

class UniEatsVendorApp extends StatelessWidget {
  const UniEatsVendorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => VendorProvider()),
        ChangeNotifierProvider(create: (_) => NavProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Uni Eats Vendor',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode,
            themeAnimationDuration: const Duration(milliseconds: 300),
            themeAnimationCurve: Curves.easeInOut,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
