import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../widgets/custom_painters.dart';
import '../api/healthcare_api.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _splashController;
  late Animation<double> _leftToRightProgress;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _splashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    // Initial splash motion goes strictly FROM LEFT TO RIGHT
    _leftToRightProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _splashController,
        curve: const Interval(0.0, 0.75, curve: Curves.easeInOutCubic),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _splashController,
        curve: const Interval(0.3, 0.85, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _splashController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _splashController.forward();

    // Navigate to next screen after splash animation completes
    _splashController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToNextScreen();
      }
    });

    _preloadData();
  }

  Future<void> _preloadData() async {
    try {
      final config = await HealthcareApi.instance.config.getConfig();
      HealthcareApi.instance.activeConfig = config;
    } catch (_) {}
  }

  void _navigateToNextScreen() {
    if (!mounted) return;
    if (HealthcareApi.instance.currentChild != null || HealthcareApi.instance.apiClient.authToken != null) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  @override
  void dispose() {
    _splashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF00A2E8),
      body: Stack(
        children: [
          // Left-to-Right Animated Liquid Splash Background Wave
          AnimatedBuilder(
            animation: _leftToRightProgress,
            builder: (context, child) {
              return CustomPaint(
                size: size,
                painter: _LeftToRightSplashPainter(
                  progress: _leftToRightProgress.value,
                ),
              );
            },
          ),

          // Main Hero Graphic & Title sliding from Left to Right
          AnimatedBuilder(
            animation: _splashController,
            builder: (context, child) {
              final double ltrValue = _leftToRightProgress.value;
              // Motion sweeps horizontally from left (-size.width * 0.8) to center (0)
              final double xTranslate = -size.width * (1.0 - ltrValue);

              return Transform.translate(
                offset: Offset(xTranslate, 0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Tooth Hero Graphic with bouncing scale effect
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 30,
                                spreadRadius: 5,
                              )
                            ],
                          ),
                          child: CustomPaint(
                            size: const Size(140, 160),
                            painter: ToothPainter(
                              expression: 'happy',
                              hasToothbrush: true,
                              brushAnimationValue: _splashController.value,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // App Title & Tagline fading in
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            const Text(
                              'دندون یار کوچولو',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'قهرمان مراقبت از دندان‌ها 🦷✨',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Custom painter for liquid splash motion strictly advancing from Left to Right.
class _LeftToRightSplashPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0

  _LeftToRightSplashPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Splash wave leading edge moves from left to right
    final double leadingX = w * 1.5 * progress - (w * 0.2);

    final Paint wavePaint = Paint()
      ..color = const Color(0xFF3498DB).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    final Paint accentWavePaint = Paint()
      ..color = const Color(0xFF2ECC71).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    // Secondary Accent Wave moving left to right
    final pathAccent = Path();
    pathAccent.moveTo(-w * 0.2, 0);
    pathAccent.lineTo(leadingX * 0.8, 0);
    for (double y = 0; y <= h; y += 20) {
      final double waveX = (leadingX * 0.8) + math.sin((y / h * 4 * math.pi) + (progress * 2 * math.pi)) * 30;
      pathAccent.lineTo(waveX, y);
    }
    pathAccent.lineTo(-w * 0.2, h);
    pathAccent.close();
    canvas.drawPath(pathAccent, accentWavePaint);

    // Primary Main Splash Wave moving left to right
    final pathMain = Path();
    pathMain.moveTo(-w * 0.2, 0);
    pathMain.lineTo(leadingX, 0);
    for (double y = 0; y <= h; y += 15) {
      final double waveX = leadingX + math.cos((y / h * 3 * math.pi) - (progress * 3 * math.pi)) * 40;
      pathMain.lineTo(waveX, y);
    }
    pathMain.lineTo(-w * 0.2, h);
    pathMain.close();
    canvas.drawPath(pathMain, wavePaint);

    // Flying Splash Droplets moving from left towards right
    final dropletPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final random = math.Random(42);
    for (int i = 0; i < 24; i++) {
      final double startX = (i % 6) * (w / 6);
      final double dropX = startX + (leadingX * 0.7) + (random.nextDouble() * 40);
      final double dropY = random.nextDouble() * h;
      final double radius = 3.0 + random.nextDouble() * 6.0;

      if (dropX > 0 && dropX < w) {
        canvas.drawCircle(Offset(dropX, dropY), radius, dropletPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LeftToRightSplashPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
