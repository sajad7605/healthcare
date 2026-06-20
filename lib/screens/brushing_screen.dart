import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/squish_pop.dart';

enum BrushingStage {
  chooseBrush,
  brushTeethOutside,
  brushTeethInside,
  cleanMouthDone,
}

class InteractiveBrushScreen extends StatefulWidget {
  const InteractiveBrushScreen({super.key});

  @override
  State<InteractiveBrushScreen> createState() => _InteractiveBrushScreenState();
}

class _InteractiveBrushScreenState extends State<InteractiveBrushScreen> with TickerProviderStateMixin {
  BrushingStage _currentStage = BrushingStage.chooseBrush;
  int _selectedBrushIndex = -1;

  // Draggable brush state
  Offset _brushPosition = const Offset(200, 500);
  bool _isDragging = false;
  double _brushAngle = -math.pi / 6;

  // Particle systems
  final List<_FoamBubble> _bubbles = [];
  final List<_Sparkle> _sparkles = [];
  final List<_Confetti> _confetti = [];

  // Game entities
  List<_Germ> _germs = [];
  double _cleanlinessProgress = 0.0;
  int _totalGerms = 5;

  // Controllers
  late AnimationController _floatingController;
  late AnimationController _wiggleController;
  late AnimationController _celebrationController;
  Timer? _updateTimer;

  // Brushes asset paths
  final List<String> _brushes = [
    'assets/Gemini_Generated_Image_bmoqd1bmoqd1bmoq 1.png',
    'assets/Gemini_Generated_Image_bmoqd1bmoqd1bmoq 2.png',
    'assets/Gemini_Generated_Image_bmoqd1bmoqd1bmoq 3.png',
  ];

  @override
  void initState() {
    super.initState();

    // Floating animation for Stage 1 (Choose Brush)
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // Wiggle/breathing animation for germs in Stages 2 & 3
    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    // Continuous celebration animation for Stage 4
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    // Start game tick loop
    _updateTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (mounted) {
        _updateGameLoop();
      }
    });
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _wiggleController.dispose();
    _celebrationController.dispose();
    _updateTimer?.cancel();
    super.dispose();
  }

  // Initialize germs for brushing stages
  void _initGerms(BrushingStage stage) {
    _germs.clear();
    if (stage == BrushingStage.brushTeethOutside) {
      _germs = [
        _Germ(id: 1, position: const Offset(0.35, 0.46), color: Colors.lightGreenAccent.shade700),
        _Germ(id: 2, position: const Offset(0.50, 0.49), color: Colors.redAccent.shade400),
        _Germ(id: 3, position: const Offset(0.65, 0.46), color: Colors.amber.shade700),
        _Germ(id: 4, position: const Offset(0.42, 0.40), color: Colors.purpleAccent.shade400),
        _Germ(id: 5, position: const Offset(0.58, 0.40), color: Colors.cyanAccent.shade700),
      ];
    } else if (stage == BrushingStage.brushTeethInside) {
      _germs = [
        _Germ(id: 1, position: const Offset(0.28, 0.44), color: Colors.green.shade600),
        _Germ(id: 2, position: const Offset(0.40, 0.48), color: Colors.orange.shade700),
        _Germ(id: 3, position: const Offset(0.58, 0.48), color: Colors.red.shade600),
        _Germ(id: 4, position: const Offset(0.70, 0.44), color: Colors.pink.shade700),
        _Germ(id: 5, position: const Offset(0.50, 0.38), color: Colors.deepPurple.shade600),
      ];
    }
    _totalGerms = _germs.length;
    setState(() {
      _cleanlinessProgress = 0.0;
    });
  }

  // Set up Stage 4 Confetti
  void _initCelebration() {
    _confetti.clear();
    final random = math.Random();
    final colors = [
      Colors.pinkAccent,
      Colors.blueAccent,
      Colors.yellowAccent,
      Colors.greenAccent,
      Colors.purpleAccent,
      Colors.orangeAccent,
    ];

    // Create 100 colorful confetti falling from various heights
    for (int i = 0; i < 90; i++) {
      _confetti.add(_Confetti(
        position: Offset(
          random.nextDouble() * 400 - 50, // width spread
          random.nextDouble() * -400 - 50, // start above screen
        ),
        vx: random.nextDouble() * 3 - 1.5,
        vy: random.nextDouble() * 4 + 2,
        size: random.nextDouble() * 10 + 6,
        color: colors[random.nextInt(colors.length)],
        rotation: random.nextDouble() * math.pi,
        rotationSpeed: random.nextDouble() * 0.1 - 0.05,
      ));
    }
    _celebrationController.repeat(reverse: true);
  }

  // Central Game Loop for animations
  void _updateGameLoop() {
    setState(() {
      // 1. Update bubbles physics
      for (int i = _bubbles.length - 1; i >= 0; i--) {
        final bubble = _bubbles[i];
        bubble.position += Offset(bubble.vx, bubble.vy);
        bubble.life -= 0.02;
        if (bubble.life <= 0.0) {
          _bubbles.removeAt(i);
        }
      }

      // 2. Update sparkles physics
      for (int i = _sparkles.length - 1; i >= 0; i--) {
        final sparkle = _sparkles[i];
        sparkle.progress += 0.03;
        sparkle.position += Offset(sparkle.vx, sparkle.vy);
        if (sparkle.progress >= 1.0) {
          _sparkles.removeAt(i);
        }
      }

      // 3. Update confetti physics in Stage 4
      if (_currentStage == BrushingStage.cleanMouthDone) {
        for (var conf in _confetti) {
          conf.position += Offset(conf.vx, conf.vy);
          conf.rotation += conf.rotationSpeed;
          // Loop confetti back to top when it falls off
          if (conf.position.dy > 900) {
            conf.position = Offset(
              math.Random().nextDouble() * 400 - 50,
              -50,
            );
            conf.vy = math.Random().nextDouble() * 4 + 2;
          }
        }

        // Add random glittering sparkles on teeth in Stage 4
        if (math.Random().nextDouble() < 0.1 && _sparkles.length < 15) {
          final randomX = 0.2 + math.Random().nextDouble() * 0.6;
          final randomY = 0.38 + math.Random().nextDouble() * 0.18;
          _sparkles.add(_Sparkle(
            position: Offset(randomX * 360, randomY * 800),
            vx: 0,
            vy: 0,
            size: math.Random().nextDouble() * 20 + 10,
            color: Colors.white,
            isStar: true,
          ));
        }
      }
    });
  }

  // Handle collision / brushing logic
  void _handleBrushing(Offset localPos, BoxConstraints constraints) {
    setState(() {
      final double dx = localPos.dx - _brushPosition.dx;
      if (dx.abs() > 1.0) {
        _brushAngle = dx > 0 ? -math.pi / 4 : -math.pi / 12;
      }
      _brushPosition = localPos;
      _isDragging = true;
    });

    // The brush tip is offset vertically (near bristles)
    final Offset brushTip = Offset(localPos.dx, localPos.dy - 70);

    // Emit custom bubble foam from bristles while moving
    final random = math.Random();
    if (random.nextDouble() < 0.3) {
      _bubbles.add(_FoamBubble(
        position: brushTip + Offset(random.nextDouble() * 30 - 15, random.nextDouble() * 20 - 10),
        vx: random.nextDouble() * 1.5 - 0.75,
        vy: random.nextDouble() * -1.5 - 0.5,
        radius: random.nextDouble() * 8 + 4,
      ));
    }

    // Check collision with germs
    for (var germ in _germs) {
      if (germ.health > 0) {
        final double absoluteX = germ.position.dx * constraints.maxWidth;
        final double absoluteY = germ.position.dy * constraints.maxHeight;
        final Offset germOffset = Offset(absoluteX, absoluteY);

        final double distance = (brushTip - germOffset).distance;
        if (distance < 50.0) {
          // Contact! Decrease health
          germ.health -= 0.02;
          germ.isShaking = true;

          // Emit hit effects
          if (random.nextDouble() < 0.4) {
            // Star sparkles shooting out
            _sparkles.add(_Sparkle(
              position: germOffset,
              vx: random.nextDouble() * 4 - 2,
              vy: random.nextDouble() * 4 - 2,
              size: random.nextDouble() * 12 + 6,
              color: Colors.amberAccent,
            ));
          }

          // Haptic impact for premium feel
          HapticFeedback.lightImpact();

          // Check if dead
          if (germ.health <= 0) {
            HapticFeedback.mediumImpact();
            // Explosion particles
            for (int k = 0; k < 12; k++) {
              final angle = k * (2 * math.pi / 12);
              final speed = random.nextDouble() * 3 + 2;
              _sparkles.add(_Sparkle(
                position: germOffset,
                vx: math.cos(angle) * speed,
                vy: math.sin(angle) * speed,
                size: random.nextDouble() * 14 + 8,
                color: germ.color,
                isStar: true,
              ));
            }
            _checkStageProgress();
          }
        } else {
          germ.isShaking = false;
        }
      }
    }
  }

  // Update overall stage progress
  void _checkStageProgress() {
    final activeGermsCount = _germs.where((g) => g.health > 0).length;
    _cleanlinessProgress = 1.0 - (activeGermsCount / _totalGerms);

    if (activeGermsCount == 0) {
      // Transition delay
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (!mounted) return;
        if (_currentStage == BrushingStage.brushTeethOutside) {
          setState(() {
            _currentStage = BrushingStage.brushTeethInside;
            _initGerms(BrushingStage.brushTeethInside);
            _bubbles.clear();
            _sparkles.clear();
            // Move brush back to standard start position
            _brushPosition = const Offset(200, 500);
          });
        } else if (_currentStage == BrushingStage.brushTeethInside) {
          setState(() {
            _currentStage = BrushingStage.cleanMouthDone;
            _bubbles.clear();
            _sparkles.clear();
            _initCelebration();
          });
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) {
              _showCelebrationDialog();
            }
          });
        }
      });
    }
  }

  // Display celebratory victory card
  void _showCelebrationDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (context, a1, a2) => const SizedBox(),
      transitionBuilder: (context, anim, secAnim, child) {
        final scale = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: anim, curve: Curves.elasticOut),
        );
        return Transform.scale(
          scale: scale.value,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              elevation: 10,
              backgroundColor: Colors.white,
              title: const Text(
                'تو قهرمان دندون‌ها شدی! 👑✨',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2ECC71),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'صد آفرین دوست طلایی! دندون‌هات رو حسابی تمیز و درخشان کردی. حالا تمام میکروب‌ها فرار کردن! 🦷💎',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Animated Sparkles
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.star, color: Colors.amber, size: 30 + (index == 1 ? 12.0 : 0.0)),
                      ),
                    ),
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                SquishPopButton(
                  onTap: () {
                    Navigator.of(context).pop(); // Dismiss Dialog
                    _celebrationController.stop();
                    setState(() {
                      _currentStage = BrushingStage.chooseBrush;
                      _selectedBrushIndex = -1;
                      _bubbles.clear();
                      _sparkles.clear();
                      _confetti.clear();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9B59B6),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF9B59B6).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'بازی دوباره 🪥',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SquishPopButton(
                  onTap: () {
                    _celebrationController.stop();
                    Navigator.of(context).pop(); // Dismiss Dialog
                    Navigator.of(context).pop(); // Back to Dashboard
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2ECC71),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2ECC71).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'بازگشت به خانه 🏠',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
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
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Fixed Background image
                Positioned.fill(
                  child: Image.asset(
                    'assets/Gemini_Generated_Image_5zdvov5zdvov5zdv 1.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),

                // 1.5. Stage-specific object (teeth)
                Positioned.fill(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    child: _currentStage == BrushingStage.chooseBrush
                        ? const SizedBox(key: ValueKey('empty_stage'))
                        : Center(
                            key: ValueKey<BrushingStage>(_currentStage),
                            child: Image.asset(
                              _getStageObject(),
                              fit: BoxFit.contain,
                            ),
                          ),
                  ),
                ),

                // 1.6 Shimmer lighting effect for last step
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      child: _currentStage == BrushingStage.cleanMouthDone
                          ? Center(
                              key: const ValueKey('shimmer_effect'),
                              child: AnimatedBuilder(
                                animation: _celebrationController,
                                builder: (context, child) {
                                  return Opacity(
                                    opacity: 0.5 + 0.5 * math.sin(_celebrationController.value * math.pi * 2),
                                    child: Image.asset(
                                      'assets/Gemini_Generated_Image_gv7eufgv7eufgv7e 1.png',
                                      fit: BoxFit.contain,
                                    ),
                                  );
                                },
                              ),
                            )
                          : const SizedBox(key: ValueKey('no_shimmer')),
                    ),
                  ),
                ),

                // 2. Custom header overlays (Progress and instructions)
                if (_currentStage != BrushingStage.chooseBrush) _buildGameHeader(constraints),

                // 3. Stage 1 Content: Choose brush
                if (_currentStage == BrushingStage.chooseBrush) _buildChooseBrushStage(constraints),

                // 4. Stages 2 & 3: Interactive cleaning elements
                if (_currentStage == BrushingStage.brushTeethOutside || _currentStage == BrushingStage.brushTeethInside)
                  _buildBrushingStage(constraints),

                // 5. Particles layers (bubbles & sparkles)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _ParticlesPainter(
                        bubbles: _bubbles,
                        sparkles: _sparkles,
                      ),
                    ),
                  ),
                ),

                // 6. Confetti layer for success stage
                if (_currentStage == BrushingStage.cleanMouthDone)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _ConfettiPainter(confetti: _confetti),
                      ),
                    ),
                  ),

                // 7. Back button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  right: 20,
                  child: SquishPopButton(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back, color: Color(0xFF2C3E50), size: 24),
                    ),
                  ),
                ),

                // 8. Link to simple countdown timer (available on selection screen)
                if (_currentStage == BrushingStage.chooseBrush)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 10,
                    left: 20,
                    child: SquishPopButton(
                      onTap: () => Navigator.pushNamed(context, '/timer'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer_outlined, color: Color(0xFF9B59B6), size: 18),
                            SizedBox(width: 6),
                            Text(
                              'تایمر ساده',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF9B59B6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Get object asset path based on stage
  String _getStageObject() {
    switch (_currentStage) {
      case BrushingStage.chooseBrush:
        return '';
      case BrushingStage.brushTeethOutside:
        return 'assets/Group 2.png';
      case BrushingStage.brushTeethInside:
        return 'assets/Group 2(2).png';
      case BrushingStage.cleanMouthDone:
        return 'assets/Group 3.png';
    }
  }

  // Build the HUD header with progress bar and instructions
  Widget _buildGameHeader(BoxConstraints constraints) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 70,
      left: 20,
      right: 20,
      child: Column(
        children: [
          // Instructional Text
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
              ],
            ),
            child: Text(
              _getInstructionText(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Cleanliness progress bar
          if (_currentStage != BrushingStage.cleanMouthDone)
            Row(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: (constraints.maxWidth - 40) * _cleanlinessProgress,
                        height: 18,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
                          ),
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(_cleanlinessProgress * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    shadows: [
                      Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(1, 1)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _getInstructionText() {
    switch (_currentStage) {
      case BrushingStage.brushTeethOutside:
        return 'مسواک را روی میکروب‌ها بکش تا نابود شوند! 🦠✨';
      case BrushingStage.brushTeethInside:
        return 'آفرین! حالا دندون‌های داخل دهان رو تمیز کن! 👅🧼';
      case BrushingStage.cleanMouthDone:
        return 'دندون‌هات از تمیزی دارن برق می‌زنن! 😍⭐';
      default:
        return '';
    }
  }

  // Stage 1: Choose Brush Screen UI
  Widget _buildChooseBrushStage(BoxConstraints constraints) {
    return Positioned.fill(
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 80),
            // Floating title banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: const Text(
                'یک مسواک قشنگ انتخاب کن! 🪥',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF9B59B6),
                ),
              ),
            ),
            const Spacer(),

            // floating toothbrushes display area
            SizedBox(
              height: 320,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_brushes.length, (index) {
                  return AnimatedBuilder(
                    animation: _floatingController,
                    builder: (context, child) {
                      // Apply staggered floating using index-based phase offset
                      final offset = math.sin((_floatingController.value * math.pi * 2) + index) * 15.0;
                      final isSelected = _selectedBrushIndex == index;

                      return Transform.translate(
                        offset: Offset(0, offset),
                        child: SquishPopButton(
                          onTap: () {
                            setState(() {
                              _selectedBrushIndex = index;
                            });
                            // Short delay before stage transition for feedback animation
                            HapticFeedback.mediumImpact();
                            Future.delayed(const Duration(milliseconds: 500), () {
                              if (mounted) {
                                setState(() {
                                  _currentStage = BrushingStage.brushTeethOutside;
                                  _initGerms(BrushingStage.brushTeethOutside);
                                });
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white.withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF9B59B6) : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF9B59B6).withValues(alpha: 0.3),
                                        blurRadius: 16,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 6),
                                      ),
                                    ]
                                  : [
                                      const BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
                                    ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  _brushes[index],
                                  height: 200,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF9B59B6) : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'مسواک ${index + 1}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : const Color(0xFF2C3E50),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
            ),
            const Spacer(),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  // Interactive Game Stage (germ monsters & draggable brush)
  Widget _buildBrushingStage(BoxConstraints constraints) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (details) => _handleBrushing(details.localPosition, constraints),
        onPanUpdate: (details) => _handleBrushing(details.localPosition, constraints),
        onPanEnd: (_) {
          setState(() {
            _isDragging = false;
          });
        },
        child: Stack(
          children: [
            // 1. Render Germ Monsters
            ..._germs.map((germ) {
              if (germ.health <= 0) return const SizedBox.shrink();

              // Calculate positions relative to screen sizes
              final double x = germ.position.dx * constraints.maxWidth;
              final double y = germ.position.dy * constraints.maxHeight;

              return AnimatedBuilder(
                animation: _wiggleController,
                builder: (context, child) {
                  // Shaking animation when hit, breathing/wiggling normally
                  double angle = 0.0;
                  double scaleOffset = 1.0;
                  if (germ.isShaking) {
                    angle = (math.Random().nextDouble() * 0.2 - 0.1);
                    scaleOffset = 0.95;
                  } else {
                    angle = math.sin(_wiggleController.value * math.pi * 2) * 0.05;
                    scaleOffset = 1.0 + (math.sin(_wiggleController.value * math.pi * 2) * 0.05);
                  }

                  return Positioned(
                    left: x - 30, // center on point
                    top: y - 30,
                    child: Transform.rotate(
                      angle: angle,
                      child: Transform.scale(
                        scale: scaleOffset * germ.health, // shrinks with health
                        child: SizedBox(
                          width: 60,
                          height: 60,
                          child: CustomPaint(
                            painter: CuteGermPainter(
                              color: germ.color,
                              health: germ.health,
                              animationValue: _wiggleController.value,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),

            // 2. Render chosen brush following dragging finger
            if (_selectedBrushIndex != -1)
              Positioned(
                left: _brushPosition.dx - 25,
                top: _brushPosition.dy - 190, // offset upwards so fingers don't block visual
                child: IgnorePointer(
                  child: AnimatedRotation(
                    turns: _isDragging ? (_brushAngle / (2 * math.pi)) : 0.0,
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      // Jiggle/vibrate the brush when dragging
                      transform: Matrix4.translationValues(
                        _isDragging ? (math.Random().nextDouble() * 4 - 2) : 0.0,
                        _isDragging ? (math.Random().nextDouble() * 4 - 2) : 0.0,
                        0.0,
                      ),
                      child: Image.asset(
                        _brushes[_selectedBrushIndex],
                        height: 220,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Particle details models
class _FoamBubble {
  Offset position;
  final double vx;
  final double vy;
  final double radius;
  double life = 1.0;

  _FoamBubble({
    required this.position,
    required this.vx,
    required this.vy,
    required this.radius,
  });
}

class _Sparkle {
  Offset position;
  final double vx;
  final double vy;
  final double size;
  final Color color;
  final bool isStar;
  double progress = 0.0;

  _Sparkle({
    required this.position,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    this.isStar = false,
  });
}

class _Confetti {
  Offset position;
  double vx;
  double vy;
  final double size;
  final Color color;
  double rotation;
  final double rotationSpeed;

  _Confetti({
    required this.position,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
  });
}

// Game entity
class _Germ {
  final int id;
  final Offset position;
  final Color color;
  double health = 1.0;
  bool isShaking = false;

  _Germ({
    required this.id,
    required this.position,
    required this.color,
  });
}

// Sparkles and Bubbles painter
class _ParticlesPainter extends CustomPainter {
  final List<_FoamBubble> bubbles;
  final List<_Sparkle> sparkles;

  _ParticlesPainter({required this.bubbles, required this.sparkles});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw bubbles
    final bubblePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final bubbleStroke = Paint()
      ..color = const Color(0xFF35B8FF).withValues(alpha: 0.4)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (var bubble in bubbles) {
      final opacity = bubble.life.clamp(0.0, 1.0);
      bubblePaint.color = Colors.white.withValues(alpha: opacity * 0.85);
      bubbleStroke.color = const Color(0xFF35B8FF).withValues(alpha: opacity * 0.4);
      
      canvas.drawCircle(bubble.position, bubble.radius, bubblePaint);
      canvas.drawCircle(bubble.position, bubble.radius, bubbleStroke);

      // Cute inner reflection dot
      final reflectPaint = Paint()..color = Colors.white.withValues(alpha: opacity * 0.9);
      canvas.drawCircle(
        bubble.position + Offset(-bubble.radius * 0.3, -bubble.radius * 0.3),
        bubble.radius * 0.2,
        reflectPaint,
      );
    }

    // 2. Draw sparkles (stars or circular pops)
    for (var sparkle in sparkles) {
      final opacity = (1.0 - sparkle.progress).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = sparkle.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      if (sparkle.isStar) {
        _drawStar(canvas, sparkle.position, sparkle.size * (1.0 - sparkle.progress), paint);
      } else {
        canvas.drawCircle(sparkle.position, sparkle.size * (1.0 - sparkle.progress), paint);
      }
    }
  }

  // Draw a 4-point star for sparkles
  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final Path path = Path();
    final double half = size / 2;

    path.moveTo(center.dx, center.dy - half);
    path.quadraticBezierTo(center.dx, center.dy, center.dx + half, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + half);
    path.quadraticBezierTo(center.dx, center.dy, center.dx - half, center.dy);
    path.quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - half);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) {
    return true; // Continuously animated
  }
}

// Confetti painter for Stage 4
class _ConfettiPainter extends CustomPainter {
  final List<_Confetti> confetti;

  _ConfettiPainter({required this.confetti});

  @override
  void paint(Canvas canvas, Size size) {
    for (var conf in confetti) {
      final paint = Paint()
        ..color = conf.color
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(conf.position.dx, conf.position.dy);
      canvas.rotate(conf.rotation);

      // Draw random rectangles or circles
      if (conf.size.toInt() % 2 == 0) {
        canvas.drawRect(Rect.fromLTWH(-conf.size / 2, -conf.size / 4, conf.size, conf.size / 2), paint);
      } else {
        canvas.drawCircle(Offset.zero, conf.size / 2, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return true; // physics-based continuous rendering
  }
}

// Cute germ custom painter
class CuteGermPainter extends CustomPainter {
  final Color color;
  final double health;
  final double animationValue;

  CuteGermPainter({
    required this.color,
    required this.health,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    canvas.save();

    final Paint bodyPaint = Paint()
      ..color = color.withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;

    // Wobble shape calculations
    final double wobble = math.sin(animationValue * math.pi * 2) * 2.5;

    // Main blob path
    final Path bodyPath = Path();
    bodyPath.moveTo(w * 0.2, h * 0.5 + wobble);
    bodyPath.cubicTo(w * 0.15, h * 0.15, w * 0.85, h * 0.15, w * 0.8, h * 0.5 + wobble);
    bodyPath.cubicTo(w * 0.95, h * 0.85, w * 0.05, h * 0.85, w * 0.2, h * 0.5 + wobble);
    bodyPath.close();
    canvas.drawPath(bodyPath, bodyPaint);

    // Draw little details like spikes or feet
    final Paint darkDetailPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.72), w * 0.08, darkDetailPaint);

    // White eyes
    final Paint eyeWhite = Paint()..color = Colors.white;
    final Paint eyePupil = Paint()..color = Colors.black;

    // Left Eye
    canvas.drawCircle(Offset(w * 0.38, h * 0.42), w * 0.11, eyeWhite);
    canvas.drawCircle(Offset(w * 0.39, h * 0.42), w * 0.05, eyePupil);

    // Right Eye
    canvas.drawCircle(Offset(w * 0.62, h * 0.42), w * 0.11, eyeWhite);
    canvas.drawCircle(Offset(w * 0.61, h * 0.42), w * 0.05, eyePupil);

    // Angry Brows
    final Paint browPaint = Paint()
      ..color = const Color(0xFF2C3E50)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w * 0.26, h * 0.30), Offset(w * 0.44, h * 0.36), browPaint);
    canvas.drawLine(Offset(w * 0.74, h * 0.30), Offset(w * 0.56, h * 0.36), browPaint);

    // Grumpy mouth
    final Paint mouthPaint = Paint()
      ..color = const Color(0xFF2C3E50)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    
    final Path mouthPath = Path();
    mouthPath.moveTo(w * 0.4, h * 0.64);
    mouthPath.quadraticBezierTo(w * 0.5, h * 0.56, w * 0.6, h * 0.64);
    canvas.drawPath(mouthPath, mouthPaint);

    // Cute fangs
    final Paint fangPaint = Paint()..color = Colors.white;
    final Path fang1 = Path();
    fang1.moveTo(w * 0.43, h * 0.61);
    fang1.lineTo(w * 0.46, h * 0.67);
    fang1.lineTo(w * 0.49, h * 0.61);
    fang1.close();
    canvas.drawPath(fang1, fangPaint);

    final Path fang2 = Path();
    fang2.moveTo(w * 0.51, h * 0.61);
    fang2.lineTo(w * 0.54, h * 0.67);
    fang2.lineTo(w * 0.57, h * 0.61);
    fang2.close();
    canvas.drawPath(fang2, fangPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CuteGermPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.health != health ||
        oldDelegate.animationValue != animationValue;
  }
}
