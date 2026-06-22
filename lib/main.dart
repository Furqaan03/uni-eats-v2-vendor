import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/nav_provider.dart';
import 'core/providers/vendor_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/splash/splash_screen.dart';
import 'firebase_options.dart';
import 'services/firestore_order_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Start Firebase init but don't block runApp — splash screen waits for it.
  final firebaseFuture = kUseFirebase
      ? Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
      : Future<void>.value();
  runApp(UniEatsVendorApp(firebaseReady: firebaseFuture));
}

class UniEatsVendorApp extends StatelessWidget {
  const UniEatsVendorApp({super.key, required this.firebaseReady});
  final Future<void> firebaseReady;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => VendorAuthProvider()),
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
            home: SplashScreen(firebaseReady: firebaseReady),
          );
        },
      ),
    );
  }
}
