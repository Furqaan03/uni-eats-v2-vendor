import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/nav_provider.dart';
import 'core/providers/vendor_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/utils/page_transitions.dart';
import 'features/orders/order_detail_screen.dart';
import 'features/splash/splash_screen.dart';
import 'firebase_options.dart';
import 'services/firestore_order_service.dart';
import 'services/push/notification_service.dart';

/// Drives notification-tap navigation from outside the widget tree.
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Start Firebase init but don't block runApp — splash screen waits for it.
  final firebaseFuture = kUseFirebase
      ? Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
          // Set up FCM receipt + local-notification display once Firebase is
          // ready. Token is saved when the active restaurant is set.
          .then((_) => NotificationService.instance.init())
      : Future<void>.value();

  // Tapping a notification opens that order's detail screen.
  NotificationService.instance.onNotificationTap = _openOrderFromNotification;

  runApp(UniEatsVendorApp(firebaseReady: firebaseFuture));
}

void _openOrderFromNotification(Map<String, dynamic> data) {
  final orderId = data['orderId']?.toString();
  if (orderId == null || orderId.isEmpty) return;
  rootNavigatorKey.currentState?.push(fadeSlidePage(OrderDetailScreen(orderId: orderId)));
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
            navigatorKey: rootNavigatorKey,
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
