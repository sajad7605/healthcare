import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../widgets/custom_painters.dart';
import '../widgets/squish_pop.dart';
import '../api/healthcare_api.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with TickerProviderStateMixin {
  int _secondsLeft = 120; // 2 minutes
  Timer? _timer;
  bool _isRunning = false;

  late AnimationController _bubbleController;
  late AnimationController _brushingController;
  final List<_Bubble> _bubbles = [];

  @override
  void initState() {
    super.initState();

    // Brushing animation controller
    _brushingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    // Bubble animation controller
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addListener(() {
        _updateBubbles();
      })..repeat();

    // Initialize some bubbles
    for (int i = 0; i < 15; i++) {
      _bubbles.add(_Bubble.random());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _brushingController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _isRunning = false;
        });
        _showCelebrationDialog();
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _secondsLeft = 120;
      _isRunning = false;
    });
  }

  void _updateBubbles() {
    if (!_isRunning) return;
    setState(() {
      for (var bubble in _bubbles) {
        bubble.y -= bubble.speed;
        bubble.x += math.sin(bubble.y / 20) * 0.5;
        if (bubble.y < 0) {
          bubble.resetAtBottom();
        }
      }
    });
  }

  String _formatTime(int totalSeconds) {
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showCelebrationDialog() {
    // Log activity to API
    try {
      final activeChild = HealthcareApi.instance.currentChild;
      if (activeChild != null) {
        HealthcareApi.instance.children.logActivity(
          activeChild.id,
          ActivityLogRequest(
            activityType: 'brushing_timer',
            durationSeconds: 120,
          ),
        ).then((res) {
          final oldStars = HealthcareApi.instance.currentChild!.stars;
          HealthcareApi.instance.currentChild = ChildProfile(
            id: activeChild.id,
            childName: activeChild.childName,
            childAge: activeChild.childAge,
            avatarUrl: activeChild.avatarUrl,
            stars: oldStars + res.starsEarned,
            createdAt: activeChild.createdAt,
          );
        });
      }
    } catch (_) {}

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text(
              'آفرین قهرمان دندون‌ها! 🎉',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2ECC71)),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 120,
                  width: 120,
                  child: CustomPaint(
                    painter: ToothPainter(expression: 'happy'),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'مسواک زدنت با موفقیت تموم شد. دندون‌هات الان دارن از تمیزی برق می‌زنن! ⭐',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF2C3E50)),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 20),
                      SizedBox(width: 6),
                      Text(
                        '+۳ ستاره دریافت کردی!',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE67E22),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              Center(
                child: SquishPopButton(
                  onTap: () {
                    Navigator.of(context).pop(); // Dismiss Dialog
                    _resetTimer();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A2E8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'ممنون!',
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
    final double percent = _secondsLeft / 120;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFEDE7F6), // Soft light purple
                Color(0xFFE3F2FD), // Soft sky blue
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Custom App Bar
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
                        'مسواک بزنیم!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(width: 40), // Balanced placeholder
                    ],
                  ),
                ),

                const Spacer(),

                // Animated Tooth + Circular Progress Ring
                SizedBox(
                  width: 280,
                  height: 280,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Bubbles overlay
                      if (_isRunning)
                        ..._bubbles.map((bubble) {
                          return Positioned(
                            left: bubble.x * 2.8,
                            top: bubble.y * 2.8,
                            child: Opacity(
                              opacity: bubble.opacity,
                              child: Container(
                                width: bubble.size,
                                height: bubble.size,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFF35B8FF).withValues(alpha: 0.5), width: 1),
                                ),
                              ),
                            ),
                          );
                        }),

                      // Glowing background ring
                      Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.4),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF9B59B6).withValues(alpha: 0.1),
                              blurRadius: 20,
                              spreadRadius: 5,
                            )
                          ],
                        ),
                      ),

                      // Animated Tooth in center
                      SizedBox(
                        width: 150,
                        height: 150,
                        child: AnimatedBuilder(
                          animation: _brushingController,
                          builder: (context, child) {
                            final double yOffset = _isRunning ? math.sin(_brushingController.value * math.pi * 2) * 6 : 0;
                            return Transform.translate(
                              offset: Offset(0, yOffset),
                              child: CustomPaint(
                                painter: ToothPainter(
                                  expression: _isRunning ? 'brushing' : 'happy',
                                  hasToothbrush: _isRunning,
                                  brushAnimationValue: _brushingController.value,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Outer circular progress indicator
                      SizedBox(
                        width: 240,
                        height: 240,
                        child: CircularProgressIndicator(
                          value: percent,
                          strokeWidth: 10,
                          backgroundColor: Colors.white.withValues(alpha: 0.6),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF9B59B6)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Countdown Timer Text
                Text(
                  _formatTime(_secondsLeft),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isRunning ? 'میکروب‌ها دارن فرار می‌کنن! 🏃‍♂️' : 'آماده‌ای؟ دکمه شروع رو بزن!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _isRunning ? const Color(0xFF2ECC71) : Colors.grey.shade600,
                  ),
                ),

                const Spacer(),

                // Bottom Action buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Reset button
                      SquishPopButton(
                        onTap: _resetTimer,
                        child: Container(
                          height: 60,
                          width: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade200, width: 2),
                          ),
                          child: Icon(Icons.refresh, color: Colors.grey.shade600, size: 28),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Play/Pause button
                      SquishPopButton(
                        onTap: _isRunning ? _pauseTimer : _startTimer,
                        child: Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF9B59B6), Color(0xFF8E44AD)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF9B59B6).withValues(alpha: 0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              )
                            ],
                          ),
                          child: Icon(
                            _isRunning ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 44,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Fast-Forward cheat button (for quick testing/checking success dialog)
                      SquishPopButton(
                        onTap: () {
                          setState(() {
                            _secondsLeft = 3;
                          });
                        },
                        child: Container(
                          height: 60,
                          width: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade200, width: 2),
                          ),
                          child: const Icon(Icons.fast_forward, color: Color(0xFF9B59B6), size: 26),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Simple Bubble structure for particle simulation
class _Bubble {
  double x;
  double y;
  double size;
  double speed;
  double opacity;

  _Bubble({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });

  factory _Bubble.random() {
    final random = math.Random();
    return _Bubble(
      x: 35.0 + random.nextDouble() * 30.0, // center it around tooth
      y: 40.0 + random.nextDouble() * 40.0,
      size: 5.0 + random.nextDouble() * 10.0,
      speed: 1.0 + random.nextDouble() * 1.5,
      opacity: 0.3 + random.nextDouble() * 0.5,
    );
  }

  void resetAtBottom() {
    final random = math.Random();
    x = 35.0 + random.nextDouble() * 30.0;
    y = 80.0;
    size = 5.0 + random.nextDouble() * 10.0;
    speed = 1.0 + random.nextDouble() * 1.5;
    opacity = 0.3 + random.nextDouble() * 0.5;
  }
}
