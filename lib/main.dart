import 'dart:ui';
import 'package:flutter/material.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/timer_screen.dart';
import 'screens/floss_screen.dart';
import 'screens/mouthwash_screen.dart';
import 'screens/gallery_screen.dart';
import 'screens/video_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/brushing_screen.dart';

void main() {
  runApp(const HealthcareApp());
}

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}

class HealthcareApp extends StatelessWidget {
  const HealthcareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'دندون یار کوچولو',
      scrollBehavior: AppScrollBehavior(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF00A2E8),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'YekanBakh',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF2C3E50)),
          bodyMedium: TextStyle(color: Color(0xFF2C3E50)),
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        Widget page;
        switch (settings.name) {
          case '/':
            page = const OnboardingScreen();
            break;
          case '/auth':
            page = const AuthScreen();
            break;
          case '/dashboard':
            page = const DashboardScreen();
            break;
          case '/timer':
            page = const TimerScreen();
            break;
          case '/floss':
            page = const FlossScreen();
            break;
          case '/mouthwash':
            page = const MouthwashScreen();
            break;
          case '/gallery':
            page = const GalleryScreen();
            break;
          case '/video':
            page = const VideoScreen();
            break;
          case '/settings':
            page = const SettingsScreen();
            break;
          case '/brushing':
            page = const InteractiveBrushScreen();
            break;

          default:
            page = const OnboardingScreen();
        }

        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            );
            final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            );

            return FadeTransition(
              opacity: fadeAnimation,
              child: ScaleTransition(scale: scaleAnimation, child: child),
            );
          },
          settings: settings,
        );
      },
    );
  }
}
