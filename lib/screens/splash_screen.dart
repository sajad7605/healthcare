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

  bool _isAutoLoggedIn = false;
  bool _isLoadingSession = true;

  @override
  void initState() {
    super.initState();

    _splashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

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

    _splashController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _checkAndNavigate();
      }
    });

    _preloadData();
  }

  Future<void> _preloadData() async {
    try {
      final hasSession = await SessionManager.loadSession();
      if (hasSession && HealthcareApi.instance.apiClient.authToken != null) {
        _isAutoLoggedIn = true;
        
        try {
          final parent = await HealthcareApi.instance.auth.getParentProfile();
          HealthcareApi.instance.currentParent = parent;
          final kids = await HealthcareApi.instance.children.listChildren();
          HealthcareApi.instance.childrenList = kids;
          if (kids.isNotEmpty) {
            HealthcareApi.instance.currentChild = kids.first;
          }
          await SessionManager.saveSession(
            token: HealthcareApi.instance.apiClient.authToken!,
            parent: parent,
            child: HealthcareApi.instance.currentChild,
            childrenList: kids,
          );
        } catch (_) {}
      }

      final config = await HealthcareApi.instance.config.getConfig();
      HealthcareApi.instance.activeConfig = config;
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingSession = false;
        });
        if (_splashController.isCompleted) {
          _checkAndNavigate();
        }
      }
    }
  }

  void _checkAndNavigate() {
    if (!mounted || _isLoadingSession) return;
    if (_isAutoLoggedIn || HealthcareApi.instance.apiClient.authToken != null) {
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

          AnimatedBuilder(
            animation: _splashController,
            builder: (context, child) {
              final double ltrValue = _leftToRightProgress.value;
              final double xTranslate = -size.width * (1.0 - ltrValue);

              return Transform.translate(
                offset: Offset(xTranslate, 0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      
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
                            const SizedBox(height: 24),
                            
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _isAutoLoggedIn ? 'در حال ورود قهرمان... 🚀' : 'در حال بارگذاری اطلاعات... ✨',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
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

class _LeftToRightSplashPainter extends CustomPainter {
  final double progress; 

  _LeftToRightSplashPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final double leadingX = w * 1.5 * progress - (w * 0.2);

    final Paint wavePaint = Paint()
      ..color = const Color(0xFF3498DB).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    final Paint accentWavePaint = Paint()
      ..color = const Color(0xFF2ECC71).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

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
