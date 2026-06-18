import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../widgets/custom_painters.dart';
import '../widgets/squish_pop.dart';

class MouthwashScreen extends StatefulWidget {
  const MouthwashScreen({super.key});

  @override
  State<MouthwashScreen> createState() => _MouthwashScreenState();
}

class _MouthwashScreenState extends State<MouthwashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  bool _isHolding = false;
  double _fillLevel = 0.0; // 0.0 to 1.0
  Timer? _fillTimer;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    _fillTimer?.cancel();
    super.dispose();
  }

  void _startFilling() {
    setState(() {
      _isHolding = true;
    });

    _fillTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_fillLevel < 1.0) {
        setState(() {
          _fillLevel += 0.012;
        });
      } else {
        _fillTimer?.cancel();
        _showFreshBreathCelebration();
      }
    });
  }

  void _stopFilling() {
    _fillTimer?.cancel();
    setState(() {
      _isHolding = false;
    });
    // Drain level slowly if let go
    _fillTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (_fillLevel > 0.0 && !_isHolding) {
        setState(() {
          _fillLevel -= 0.015;
          if (_fillLevel < 0.0) _fillLevel = 0.0;
        });
      } else {
        _fillTimer?.cancel();
      }
    });
  }

  void _showFreshBreathCelebration() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text(
              'به‌به! عجب بوی خوبی! 🍃',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2ECC71)),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.clean_hands, size: 80, color: Color(0xFF2ECC71)),
                const SizedBox(height: 16),
                const Text(
                  'دهانت کاملاً ضدعفونی شد و نفست بوی طراوت و نعناع میده! دندان‌ها حسابی تمیز شدن. 🦷✨',
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
                      _fillLevel = 0.0;
                      _isHolding = false;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2ECC71),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'بستن',
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            // Wave animation background (fills from bottom)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _WavePainter(
                      waveAnimation: _waveController.value,
                      fillLevel: _fillLevel,
                    ),
                  );
                },
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // App Bar
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
                        const Text(
                          'دهان‌شویه جادویی',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30),
                    child: Text(
                      'دکمه سبز پایین رو نگه‌دار تا دهان‌شویه جادویی کل صفحه رو پر کنه و دندون‌ها رو تمیز و معطر کنه! 🧪',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF57606F),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Big Mouthwash Bottle
                  Center(
                    child: SizedBox(
                      width: 160,
                      height: 220,
                      child: CustomPaint(
                        painter: MouthwashBottlePainter(),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Animated Fill Percentage
                  Text(
                    'میزان شستشو: ${(_fillLevel * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF27AE60),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Hold Button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 50),
                    child: GestureDetector(
                      onTapDown: (_) => _startFilling(),
                      onTapUp: (_) => _stopFilling(),
                      onTapCancel: () => _stopFilling(),
                      child: SquishPopButton(
                        squishScale: 0.85,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
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
                          child: const Text(
                            'دهان‌شویه را نگه‌دار! 🟢',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
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

// Waves painter that fills the screen from the bottom
class _WavePainter extends CustomPainter {
  final double waveAnimation;
  final double fillLevel;

  _WavePainter({required this.waveAnimation, required this.fillLevel});

  @override
  void paint(Canvas canvas, Size size) {
    if (fillLevel <= 0.0) return;

    final double w = size.width;
    final double h = size.height;

    // Target fill height
    final double targetHeight = h * fillLevel;

    final Paint wavePaint = Paint()
      ..color = const Color(0xFF2ECC71).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final Paint wavePaint2 = Paint()
      ..color = const Color(0xFF27AE60).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    // Draw secondary background wave
    final path2 = Path();
    path2.moveTo(0, h);
    path2.lineTo(0, h - targetHeight);
    for (double i = 0; i <= w; i += 10) {
      final double y = h - targetHeight + math.sin((i / w * 2 * math.pi) + (waveAnimation * 2 * math.pi)) * 14;
      path2.lineTo(i, y);
    }
    path2.lineTo(w, h);
    path2.close();
    canvas.drawPath(path2, wavePaint2);

    // Draw primary foreground wave
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

    // Draw bubbles rising inside the filled wave
    final bubblePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    
    final random = math.Random(12345); // Fixed seed to keep bubbles positions coherent
    final int bubbleCount = (fillLevel * 30).toInt();
    for (int i = 0; i < bubbleCount; i++) {
      final double bx = random.nextDouble() * w;
      final double by = h - (random.nextDouble() * targetHeight);
      final double radius = 3.0 + random.nextDouble() * 8.0;
      canvas.drawCircle(Offset(bx, by), radius, bubblePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) {
    return oldDelegate.waveAnimation != waveAnimation || oldDelegate.fillLevel != fillLevel;
  }
}
