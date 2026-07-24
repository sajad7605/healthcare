import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../widgets/squish_pop.dart';
import '../api/healthcare_api.dart';

enum MouthwashStage {
  gargle,
  spit,
  celebration,
}

class MouthwashScreen extends StatefulWidget {
  const MouthwashScreen({super.key});

  @override
  State<MouthwashScreen> createState() => _MouthwashScreenState();
}

class _MouthwashScreenState extends State<MouthwashScreen> with TickerProviderStateMixin {
  MouthwashStage _currentStage = MouthwashStage.gargle;

  late AnimationController _gargleController;
  late AnimationController _cheekPuffController;
  bool _isGarglingHolding = false;
  double _gargleProgress = 0.0; 
  Timer? _gargleTimer;

  late AnimationController _spitController;
  final List<_SplashDroplet> _spitDroplets = [];
  bool _isSpittingAnimationRunning = false;

  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _gargleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat(reverse: true);

    _cheekPuffController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    )..repeat(reverse: true);

    _spitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _spitController.addListener(() {
      if (_spitController.value > 0.2 && _spitDroplets.isEmpty) {
        _spawnSpitDroplets();
      }
      _updateSpitDroplets();
    });

    _spitController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _currentStage = MouthwashStage.celebration;
        });
        _showFreshBreathCelebration();
      }
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    _gargleController.dispose();
    _cheekPuffController.dispose();
    _spitController.dispose();
    _gargleTimer?.cancel();
    super.dispose();
  }

  void _startGargling() {
    if (_currentStage != MouthwashStage.gargle) return;

    setState(() {
      _isGarglingHolding = true;
    });

    _gargleTimer?.cancel();
    _gargleTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (_gargleProgress < 1.0) {
        setState(() {
          _gargleProgress += 0.018;
          if (_gargleProgress > 1.0) _gargleProgress = 1.0;
        });
      } else {
        _gargleTimer?.cancel();
        _finishGarglePhase();
      }
    });
  }

  void _stopGargling() {
    if (_currentStage != MouthwashStage.gargle) return;
    _gargleTimer?.cancel();
    setState(() {
      _isGarglingHolding = false;
    });
  }

  void _finishGarglePhase() {
    _gargleTimer?.cancel();
    setState(() {
      _isGarglingHolding = false;
      _currentStage = MouthwashStage.spit;
    });
  }

  void _triggerSpitAction() {
    if (_isSpittingAnimationRunning || _currentStage != MouthwashStage.spit) return;

    setState(() {
      _isSpittingAnimationRunning = true;
    });

    _spitController.forward(from: 0.0);
  }

  void _spawnSpitDroplets() {
    final random = math.Random();
    _spitDroplets.clear();
    for (int i = 0; i < 25; i++) {
      _spitDroplets.add(
        _SplashDroplet(
          x: 0.0,
          y: 0.0,
          vx: (random.nextDouble() - 0.5) * 14.0,
          vy: -2.0 - random.nextDouble() * 10.0,
          radius: 3.0 + random.nextDouble() * 5.0,
          color: const Color(0xFF2ECC71).withValues(alpha: 0.85),
        ),
      );
    }
  }

  void _updateSpitDroplets() {
    if (_spitDroplets.isEmpty) return;
    setState(() {
      for (var droplet in _spitDroplets) {
        droplet.x += droplet.vx;
        droplet.y += droplet.vy;
        droplet.vy += 0.8; 
      }
    });
  }

  void _showFreshBreathCelebration() {
    final activeChild = HealthcareApi.instance.currentChild;
    if (activeChild != null) {
      HealthcareApi.instance.children.logActivity(
        activeChild.id,
        ActivityLogRequest(
          activityType: 'mouthwash',
          durationSeconds: 30,
          completedSteps: const ['gargle', 'spit'],
        ),
      ).then((res) {
        final oldStars = HealthcareApi.instance.currentChild?.stars ?? 0;
        HealthcareApi.instance.currentChild = ChildProfile(
          id: activeChild.id,
          childName: activeChild.childName,
          childAge: activeChild.childAge,
          avatarUrl: activeChild.avatarUrl,
          stars: oldStars + res.starsEarned,
          createdAt: activeChild.createdAt,
        );
      }).catchError((err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطا در ثبت فعالیت: $err'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 6),
            ),
          );
        }
      });
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text(
              'به‌به! کودک عزیز دندان‌های تمیز داری! 🍃✨',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2ECC71), fontSize: 20),
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.face_retouching_natural_rounded, size: 80, color: Color(0xFF2ECC71)),
                SizedBox(height: 16),
                Text(
                  'آفرین قهرمان! دهان‌شویه رو غرغره کردی و بیرون ریختی! دهانت کاملاً ضدعفونی شد و نفست بوی طراوت و نعناع میده! 🧒🦷🍃',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF2C3E50)),
                ),
              ],
            ),
            actions: [
              Center(
                child: SquishPopButton(
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _currentStage = MouthwashStage.gargle;
                      _gargleProgress = 0.0;
                      _isGarglingHolding = false;
                      _isSpittingAnimationRunning = false;
                      _spitDroplets.clear();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2ECC71),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'متوجه شدم 🟢',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _WavePainter(
                      waveAnimation: _waveController.value,
                      fillLevel: _currentStage == MouthwashStage.gargle ? _gargleProgress * 0.4 : 0.05,
                    ),
                  );
                },
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SquishPopButton(
                          onTap: () => Navigator.of(context).pop(),
                          child: const CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Icon(Icons.arrow_back, color: Color(0xFF2C3E50)),
                          ),
                        ),
                        Text(
                          _currentStage == MouthwashStage.gargle
                              ? 'مرحله ۱: غرغره کودک 🧪'
                              : 'مرحله ۲: تف کردن دهان‌شویه 💦',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _currentStage == MouthwashStage.gargle
                                ? Icons.water_drop
                                : Icons.cleaning_services,
                            color: const Color(0xFF2ECC71),
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _currentStage == MouthwashStage.gargle
                                  ? 'دکمه زیر رو نگه‌دار تا کودک دهان‌شویه رو تو دهانش غرغره کنه! 🧒🟢'
                                  : 'حالا دکمه تف کردن رو بزن تا کودک دهان‌شویه رو تو سینک خالی کنه! 💦',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2C3E50),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  SizedBox(
                    height: 340,
                    width: size.width,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        
                        if (_currentStage == MouthwashStage.gargle)
                          AnimatedBuilder(
                            animation: Listenable.merge([_cheekPuffController, _gargleController]),
                            builder: (context, child) {
                              final double puff = _isGarglingHolding
                                  ? math.sin(_cheekPuffController.value * math.pi) * 16.0
                                  : 0.0;
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  
                                  if (_isGarglingHolding)
                                    Container(
                                      width: 240 + (math.sin(_gargleController.value * math.pi * 2) * 15),
                                      height: 240 + (math.sin(_gargleController.value * math.pi * 2) * 15),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF2ECC71).withValues(alpha: 0.25),
                                      ),
                                    ),

                                  CustomPaint(
                                    size: const Size(200, 240),
                                    painter: _GarglingKidPainter(
                                      isGargling: _isGarglingHolding,
                                      puffAmount: puff,
                                      bubbleAnim: _gargleController.value,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),

                        if (_currentStage == MouthwashStage.spit || _currentStage == MouthwashStage.celebration)
                          AnimatedBuilder(
                            animation: _spitController,
                            builder: (context, child) {
                              return CustomPaint(
                                size: Size(size.width, 340),
                                painter: _SpittingKidScenePainter(
                                  spitProgress: _spitController.value,
                                  droplets: _spitDroplets,
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  if (_currentStage == MouthwashStage.gargle)
                    Column(
                      children: [
                        Text(
                          'میزان غرغره کودک: ${(_gargleProgress * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF27AE60),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 50),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _gargleProgress,
                              minHeight: 14,
                              backgroundColor: Colors.grey.shade300,
                              color: const Color(0xFF2ECC71),
                            ),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 20),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: _currentStage == MouthwashStage.gargle
                        ? GestureDetector(
                            onTapDown: (_) => _startGargling(),
                            onTapUp: (_) => _stopGargling(),
                            onTapCancel: () => _stopGargling(),
                            child: SquishPopButton(
                              squishScale: 0.88,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2ECC71),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2ECC71).withValues(alpha: 0.4),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    )
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _isGarglingHolding ? Icons.loop : Icons.touch_app,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isGarglingHolding ? 'کودک در حال غرغره... 🧪' : 'نگه‌دار تا کودک غرغره کند! 🟢',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : SquishPopButton(
                            onTap: _triggerSpitAction,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 18),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3498DB),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF3498DB).withValues(alpha: 0.4),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  )
                                ],
                              ),
                              child: const Text(
                                'حالا کودک تف کند! 💦',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
  }
}

class _SplashDroplet {
  double x;
  double y;
  double vx;
  double vy;
  double radius;
  Color color;

  _SplashDroplet({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.color,
  });
}

class _GarglingKidPainter extends CustomPainter {
  final bool isGargling;
  final double puffAmount;
  final double bubbleAnim;

  _GarglingKidPainter({
    required this.isGargling,
    required this.puffAmount,
    required this.bubbleAnim,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Offset headCenter = Offset(w * 0.5, h * 0.44);
    final double headRadius = w * 0.32;

    final paint = Paint();

    paint.color = const Color(0xFFFFD2A6);
    final double earPuff = isGargling ? puffAmount * 0.4 : 0.0;
    canvas.drawCircle(Offset(headCenter.dx - headRadius - earPuff, headCenter.dy), 14, paint);
    canvas.drawCircle(Offset(headCenter.dx + headRadius + earPuff, headCenter.dy), 14, paint);

    paint.color = const Color(0xFFFFB5C5).withValues(alpha: 0.5);
    canvas.drawCircle(Offset(headCenter.dx - headRadius - earPuff, headCenter.dy), 7, paint);
    canvas.drawCircle(Offset(headCenter.dx + headRadius + earPuff, headCenter.dy), 7, paint);

    paint.color = const Color(0xFF2980B9);
    final shirtPath = Path();
    shirtPath.moveTo(headCenter.dx - w * 0.36, h * 0.84);
    shirtPath.lineTo(headCenter.dx + w * 0.36, h * 0.84);
    shirtPath.lineTo(headCenter.dx + w * 0.45, h);
    shirtPath.lineTo(headCenter.dx - w * 0.45, h);
    shirtPath.close();
    canvas.drawPath(shirtPath, paint);

    paint.color = Colors.white;
    final collarPath = Path();
    collarPath.moveTo(headCenter.dx - 22, h * 0.84);
    collarPath.lineTo(headCenter.dx, h * 0.92);
    collarPath.lineTo(headCenter.dx + 22, h * 0.84);
    collarPath.close();
    canvas.drawPath(collarPath, paint);

    final starPaint = Paint()..color = Colors.amber;
    canvas.drawCircle(Offset(headCenter.dx + 26, h * 0.92), 7, starPaint);

    paint.color = const Color(0xFFFFD2A6);
    final double puffX = isGargling ? puffAmount * 2.0 : 0.0;
    final Rect headRect = Rect.fromCenter(
      center: headCenter,
      width: (headRadius * 2.0) + puffX,
      height: headRadius * 1.9,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(headRect, Radius.circular(headRadius * 0.9)),
      paint,
    );

    paint.color = const Color(0xFF5D4037);
    final hairPath = Path();
    hairPath.moveTo(headCenter.dx - headRadius * 1.0, headCenter.dy - headRadius * 0.1);
    hairPath.quadraticBezierTo(headCenter.dx - headRadius * 0.6, headCenter.dy - headRadius * 1.45, headCenter.dx, headCenter.dy - headRadius * 1.3);
    hairPath.quadraticBezierTo(headCenter.dx + headRadius * 0.6, headCenter.dy - headRadius * 1.45, headCenter.dx + headRadius * 1.0, headCenter.dy - headRadius * 0.1);
    hairPath.quadraticBezierTo(headCenter.dx + headRadius * 0.6, headCenter.dy - headRadius * 0.6, headCenter.dx, headCenter.dy - headRadius * 0.65);
    hairPath.quadraticBezierTo(headCenter.dx - headRadius * 0.6, headCenter.dy - headRadius * 0.6, headCenter.dx - headRadius * 1.0, headCenter.dy - headRadius * 0.1);
    canvas.drawPath(hairPath, paint);

    final tuft1 = Path();
    tuft1.moveTo(headCenter.dx - 25, headCenter.dy - headRadius * 0.65);
    tuft1.quadraticBezierTo(headCenter.dx - 10, headCenter.dy - headRadius * 1.1, headCenter.dx + 5, headCenter.dy - headRadius * 0.6);
    tuft1.close();
    canvas.drawPath(tuft1, paint);

    final tuft2 = Path();
    tuft2.moveTo(headCenter.dx - 5, headCenter.dy - headRadius * 0.65);
    tuft2.quadraticBezierTo(headCenter.dx + 15, headCenter.dy - headRadius * 1.15, headCenter.dx + 30, headCenter.dy - headRadius * 0.55);
    tuft2.close();
    canvas.drawPath(tuft2, paint);

    final eyePaint = Paint()..color = const Color(0xFF2C3E50);
    final irisPaint = Paint()..color = const Color(0xFF16A085);
    final reflect1 = Paint()..color = Colors.white;
    final reflect2 = Paint()..color = Colors.white.withValues(alpha: 0.7);

    final Offset leftEye = Offset(headCenter.dx - headRadius * 0.36, headCenter.dy - headRadius * 0.08);
    final Offset rightEye = Offset(headCenter.dx + headRadius * 0.36, headCenter.dy - headRadius * 0.08);

    canvas.drawCircle(leftEye, 10, eyePaint);
    canvas.drawCircle(leftEye, 8, irisPaint);
    canvas.drawCircle(Offset(leftEye.dx - 3, leftEye.dy - 3), 3.5, reflect1);
    canvas.drawCircle(Offset(leftEye.dx + 3, leftEye.dy + 3), 1.8, reflect2);

    canvas.drawCircle(rightEye, 10, eyePaint);
    canvas.drawCircle(rightEye, 8, irisPaint);
    canvas.drawCircle(Offset(rightEye.dx - 3, rightEye.dy - 3), 3.5, reflect1);
    canvas.drawCircle(Offset(rightEye.dx + 3, rightEye.dy + 3), 1.8, reflect2);

    final browPaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(leftEye.dx - 10, leftEye.dy - 16), Offset(leftEye.dx + 8, leftEye.dy - 18), browPaint);
    canvas.drawLine(Offset(rightEye.dx - 8, rightEye.dy - 18), Offset(rightEye.dx + 10, rightEye.dy - 16), browPaint);

    final nosePaint = Paint()
      ..color = const Color(0xFFE59866)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCenter(center: Offset(headCenter.dx, headCenter.dy + headRadius * 0.15), width: 8, height: 6), 0, math.pi, false, nosePaint);

    final blushPaint = Paint()
      ..color = const Color(0xFFFF8A80).withValues(alpha: 0.65)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(headCenter.dx - headRadius * 0.65 - (puffAmount * 0.5), headCenter.dy + 16), 18, blushPaint);
    canvas.drawCircle(Offset(headCenter.dx + headRadius * 0.65 + (puffAmount * 0.5), headCenter.dy + 16), 18, blushPaint);

    if (isGargling) {
      final liquidPaint = Paint()
        ..color = const Color(0xFF2ECC71)
        ..style = PaintingStyle.fill;

      final Rect mouthRect = Rect.fromCenter(
        center: Offset(headCenter.dx, headCenter.dy + headRadius * 0.42),
        width: 48 + (puffAmount * 1.1),
        height: 32,
      );
      canvas.drawOval(mouthRect, liquidPaint);

      final bubblePaint = Paint()..color = Colors.white.withValues(alpha: 0.92);
      final random = math.Random(101);
      for (int i = 0; i < 9; i++) {
        final double bx = headCenter.dx - 20 + (random.nextDouble() * 40);
        final double by = headCenter.dy + headRadius * 0.36 + (random.nextDouble() * 16) + (math.sin(bubbleAnim * math.pi * 2 + i) * 3);
        final double r = 3.0 + random.nextDouble() * 4.5;
        canvas.drawCircle(Offset(bx, by), r, bubblePaint);
      }
    } else {
      
      final smilePaint = Paint()
        ..color = const Color(0xFF2C3E50)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;
      final smilePath = Path();
      smilePath.moveTo(headCenter.dx - 16, headCenter.dy + headRadius * 0.4);
      smilePath.quadraticBezierTo(headCenter.dx, headCenter.dy + headRadius * 0.62, headCenter.dx + 16, headCenter.dy + headRadius * 0.4);
      canvas.drawPath(smilePath, smilePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GarglingKidPainter oldDelegate) {
    return oldDelegate.isGargling != isGargling ||
        oldDelegate.puffAmount != puffAmount ||
        oldDelegate.bubbleAnim != bubbleAnim;
  }
}

class _SpittingKidScenePainter extends CustomPainter {
  final double spitProgress; 
  final List<_SplashDroplet> droplets;

  _SpittingKidScenePainter({
    required this.spitProgress,
    required this.droplets,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Offset kidHeadCenter = Offset(w * 0.5, 95);
    final double headRadius = 48;

    final paint = Paint();

    paint.color = const Color(0xFFFFD2A6);
    canvas.drawCircle(Offset(kidHeadCenter.dx - headRadius, kidHeadCenter.dy), 12, paint);
    canvas.drawCircle(Offset(kidHeadCenter.dx + headRadius, kidHeadCenter.dy), 12, paint);

    paint.color = const Color(0xFF2980B9);
    final shirtPath = Path();
    shirtPath.moveTo(kidHeadCenter.dx - 55, kidHeadCenter.dy + 42);
    shirtPath.lineTo(kidHeadCenter.dx + 55, kidHeadCenter.dy + 42);
    shirtPath.lineTo(kidHeadCenter.dx + 70, kidHeadCenter.dy + 95);
    shirtPath.lineTo(kidHeadCenter.dx - 70, kidHeadCenter.dy + 95);
    shirtPath.close();
    canvas.drawPath(shirtPath, paint);

    paint.color = Colors.white;
    final collar = Path();
    collar.moveTo(kidHeadCenter.dx - 20, kidHeadCenter.dy + 42);
    collar.lineTo(kidHeadCenter.dx, kidHeadCenter.dy + 56);
    collar.lineTo(kidHeadCenter.dx + 20, kidHeadCenter.dy + 42);
    collar.close();
    canvas.drawPath(collar, paint);

    paint.color = const Color(0xFFFFD2A6);
    canvas.drawCircle(kidHeadCenter, headRadius, paint);

    paint.color = const Color(0xFF5D4037);
    final hairPath = Path();
    hairPath.moveTo(kidHeadCenter.dx - headRadius * 1.0, kidHeadCenter.dy - headRadius * 0.1);
    hairPath.quadraticBezierTo(kidHeadCenter.dx - headRadius * 0.6, kidHeadCenter.dy - headRadius * 1.45, kidHeadCenter.dx, kidHeadCenter.dy - headRadius * 1.3);
    hairPath.quadraticBezierTo(kidHeadCenter.dx + headRadius * 0.6, kidHeadCenter.dy - headRadius * 1.45, kidHeadCenter.dx + headRadius * 1.0, kidHeadCenter.dy - headRadius * 0.1);
    hairPath.quadraticBezierTo(kidHeadCenter.dx + headRadius * 0.6, kidHeadCenter.dy - headRadius * 0.6, kidHeadCenter.dx, kidHeadCenter.dy - headRadius * 0.65);
    hairPath.quadraticBezierTo(kidHeadCenter.dx - headRadius * 0.6, kidHeadCenter.dy - headRadius * 0.6, kidHeadCenter.dx - headRadius * 1.0, kidHeadCenter.dy - headRadius * 0.1);
    canvas.drawPath(hairPath, paint);

    final tuft1 = Path();
    tuft1.moveTo(kidHeadCenter.dx - 22, kidHeadCenter.dy - headRadius * 0.65);
    tuft1.quadraticBezierTo(kidHeadCenter.dx - 8, kidHeadCenter.dy - headRadius * 1.1, kidHeadCenter.dx + 8, kidHeadCenter.dy - headRadius * 0.6);
    tuft1.close();
    canvas.drawPath(tuft1, paint);

    final eyePaint = Paint()..color = const Color(0xFF2C3E50);
    final irisPaint = Paint()..color = const Color(0xFF16A085);
    final reflect1 = Paint()..color = Colors.white;

    final Offset leftEye = Offset(kidHeadCenter.dx - 18, kidHeadCenter.dy - 8);
    final Offset rightEye = Offset(kidHeadCenter.dx + 18, kidHeadCenter.dy - 8);

    canvas.drawCircle(leftEye, 9, eyePaint);
    canvas.drawCircle(leftEye, 7, irisPaint);
    canvas.drawCircle(Offset(leftEye.dx - 2.5, leftEye.dy - 2.5), 3, reflect1);

    canvas.drawCircle(rightEye, 9, eyePaint);
    canvas.drawCircle(rightEye, 7, irisPaint);
    canvas.drawCircle(Offset(rightEye.dx - 2.5, rightEye.dy - 2.5), 3, reflect1);

    final blushPaint = Paint()
      ..color = const Color(0xFFFF8A80).withValues(alpha: 0.65)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(kidHeadCenter.dx - 32, kidHeadCenter.dy + 14), 14, blushPaint);
    canvas.drawCircle(Offset(kidHeadCenter.dx + 32, kidHeadCenter.dy + 14), 14, blushPaint);

    final Offset mouthPos = Offset(kidHeadCenter.dx, kidHeadCenter.dy + 24);
    if (spitProgress < 0.9) {
      final mouthPaint = Paint()..color = const Color(0xFFE74C3C);
      canvas.drawCircle(mouthPos, 12, mouthPaint);
    } else {
      final smilePaint = Paint()
        ..color = const Color(0xFF2ECC71)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round;
      final smilePath = Path();
      smilePath.moveTo(kidHeadCenter.dx - 18, kidHeadCenter.dy + 20);
      smilePath.quadraticBezierTo(kidHeadCenter.dx, kidHeadCenter.dy + 36, kidHeadCenter.dx + 18, kidHeadCenter.dy + 20);
      canvas.drawPath(smilePath, smilePaint);
    }

    final Paint sinkPaint = Paint()
      ..color = const Color(0xFFECF0F1)
      ..style = PaintingStyle.fill;

    final Paint sinkRimPaint = Paint()
      ..color = const Color(0xFFBDC3C7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    final Offset sinkCenter = Offset(w * 0.5, h * 0.82);
    final Rect sinkRect = Rect.fromCenter(center: sinkCenter, width: w * 0.68, height: 52);

    canvas.drawOval(sinkRect, sinkPaint);
    canvas.drawOval(sinkRect, sinkRimPaint);

    final Paint drainPaint = Paint()..color = const Color(0xFF7F8C8D);
    canvas.drawCircle(sinkCenter, 14, drainPaint);

    if (spitProgress > 0.05 && spitProgress < 0.95) {
      final Offset targetSink = Offset(w * 0.5, h * 0.8);

      final Path streamPath = Path();
      streamPath.moveTo(mouthPos.dx, mouthPos.dy);

      final Offset controlPoint = Offset(w * 0.65, (mouthPos.dy + targetSink.dy) / 2);

      final double streamLen = spitProgress.clamp(0.0, 1.0);
      final Offset currentEnd = Offset(
        mouthPos.dx + (targetSink.dx - mouthPos.dx) * streamLen + (math.sin(streamLen * math.pi) * 35),
        mouthPos.dy + (targetSink.dy - mouthPos.dy) * streamLen,
      );

      streamPath.quadraticBezierTo(controlPoint.dx, controlPoint.dy, currentEnd.dx, currentEnd.dy);

      final Paint streamPaint = Paint()
        ..color = const Color(0xFF2ECC71).withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 14 * (1.0 - streamLen * 0.3);

      canvas.drawPath(streamPath, streamPaint);
    }

    if (spitProgress > 0.25) {
      canvas.save();
      canvas.translate(sinkCenter.dx, sinkCenter.dy);
      for (var droplet in droplets) {
        final Paint dropPaint = Paint()..color = droplet.color;
        canvas.drawCircle(Offset(droplet.x, droplet.y), droplet.radius, dropPaint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _SpittingKidScenePainter oldDelegate) {
    return oldDelegate.spitProgress != spitProgress || oldDelegate.droplets != droplets;
  }
}

class _WavePainter extends CustomPainter {
  final double waveAnimation;
  final double fillLevel;

  _WavePainter({required this.waveAnimation, required this.fillLevel});

  @override
  void paint(Canvas canvas, Size size) {
    if (fillLevel <= 0.0) return;

    final double w = size.width;
    final double h = size.height;
    final double targetHeight = h * fillLevel;

    final Paint wavePaint = Paint()
      ..color = const Color(0xFF2ECC71).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, h);
    path.lineTo(0, h - targetHeight);
    for (double i = 0; i <= w; i += 10) {
      final double y = h - targetHeight + math.cos((i / w * 2 * math.pi) - (waveAnimation * 2 * math.pi)) * 12;
      path.lineTo(i, y);
    }
    path.lineTo(w, h);
    path.close();
    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.waveAnimation != waveAnimation || oldDelegate.fillLevel != fillLevel;
  }
}
