import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/custom_painters.dart';
import '../widgets/squish_pop.dart';
import '../api/healthcare_api.dart';

class FlossScreen extends StatefulWidget {
  const FlossScreen({super.key});

  @override
  State<FlossScreen> createState() => _FlossScreenState();
}

class _FlossScreenState extends State<FlossScreen>
    with TickerProviderStateMixin {
  Offset _touchPos = const Offset(180, 250);
  bool _isDragging = false;
  bool _isSuccess = false;

  List<_StuckItem> _items = [];
  final List<_Sparkle> _sparkles = [];
  final List<_Confetti> _confetti = [];
  final List<Offset> _dragHistory = [];

  double _cleanlinessProgress = 0.0;
  int _totalItems = 7;
  String _tooltipText = '';
  Timer? _tooltipTimer;

  late AnimationController _floatingController;
  late AnimationController _wiggleController;
  late AnimationController _celebrationController;
  Timer? _updateTimer;

  Rect _boardBounds = Rect.zero;
  double _distanceWithoutHit = 0.0;

  @override
  void initState() {
    super.initState();

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _initGame();

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
    _tooltipTimer?.cancel();
    super.dispose();
  }

  void _initGame() {
    _items = [
      // Gap 1 (Left Gap: between Left Tooth and Center Tooth)
      _StuckItem(
        id: 1,
        gapIndex: 1,
        normalizedY: 0.35,
        type: 'germ',
        color: Colors.purpleAccent.shade400,
      ),
      _StuckItem(
        id: 2,
        gapIndex: 1,
        normalizedY: 0.52,
        type: 'food',
        foodType: 'leaf',
        color: Colors.lightGreenAccent.shade700,
      ),
      _StuckItem(
        id: 3,
        gapIndex: 1,
        normalizedY: 0.68,
        type: 'food',
        foodType: 'meat',
        color: Colors.redAccent.shade400,
      ),
      _StuckItem(
        id: 4,
        gapIndex: 1,
        normalizedY: 0.82,
        type: 'germ',
        color: Colors.cyanAccent.shade700,
      ),

      // Gap 2 (Right Gap: between Center Tooth and Right Tooth)
      _StuckItem(
        id: 5,
        gapIndex: 2,
        normalizedY: 0.38,
        type: 'food',
        foodType: 'cheese',
        color: Colors.amber.shade700,
      ),
      _StuckItem(
        id: 6,
        gapIndex: 2,
        normalizedY: 0.58,
        type: 'germ',
        color: Colors.pinkAccent.shade400,
      ),
      _StuckItem(
        id: 7,
        gapIndex: 2,
        normalizedY: 0.76,
        type: 'food',
        foodType: 'leaf',
        color: Colors.green.shade600,
      ),
    ];

    _totalItems = _items.length;
    _cleanlinessProgress = 0.0;
    _isSuccess = false;
    _sparkles.clear();
    _confetti.clear();
    _celebrationController.stop();
  }

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

    for (int i = 0; i < 70; i++) {
      _confetti.add(
        _Confetti(
          position: Offset(
            random.nextDouble() * 400 - 50,
            random.nextDouble() * -400 - 50,
          ),
          vx: random.nextDouble() * 3 - 1.5,
          vy: random.nextDouble() * 4 + 2,
          size: random.nextDouble() * 10 + 6,
          color: colors[random.nextInt(colors.length)],
          rotation: random.nextDouble() * math.pi,
          rotationSpeed: random.nextDouble() * 0.1 - 0.05,
        ),
      );
    }
    _celebrationController.repeat(reverse: true);
  }

  void _updateGameLoop() {
    setState(() {
      for (int i = _sparkles.length - 1; i >= 0; i--) {
        final sparkle = _sparkles[i];
        sparkle.progress += 0.035;
        sparkle.position += Offset(sparkle.vx, sparkle.vy);
        if (sparkle.progress >= 1.0) {
          _sparkles.removeAt(i);
        }
      }

      if (_isSuccess) {
        for (var conf in _confetti) {
          conf.position += Offset(conf.vx, conf.vy);
          conf.rotation += conf.rotationSpeed;

          if (conf.position.dy > 800) {
            conf.position = Offset(math.Random().nextDouble() * 400 - 50, -50);
            conf.vy = math.Random().nextDouble() * 4 + 2;
          }
        }

        if (math.Random().nextDouble() < 0.15 && _sparkles.length < 20) {
          _sparkles.add(
            _Sparkle(
              position: Offset(
                math.Random().nextDouble() * 360,
                200 + math.Random().nextDouble() * 300,
              ),
              vx: 0,
              vy: 0,
              size: math.Random().nextDouble() * 18 + 8,
              color: Colors.white,
              isStar: true,
            ),
          );
        }
      }
    });
  }

  void _onPanStart(DragStartDetails details, BoxConstraints constraints) {
    if (_isSuccess) return;
    setState(() {
      _isDragging = true;
      _touchPos = details.localPosition;
      _dragHistory.clear();
      _dragHistory.add(_touchPos);
    });
    _checkFlossHit();
  }

  void _onPanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    if (_isSuccess) return;
    setState(() {
      final double dx = details.delta.dx;
      final double dy = details.delta.dy;
      final double dist = math.sqrt(dx * dx + dy * dy);

      _touchPos = details.localPosition;
      _dragHistory.add(_touchPos);
      if (_dragHistory.length > 15) {
        _dragHistory.removeAt(0);
      }

      _checkFlossHit(dragDistance: dist);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      for (var item in _items) {
        item.isShaking = false;
      }
    });
  }

  void _checkFlossHit({double dragDistance = 0.0}) {
    if (_boardBounds == Rect.zero) return;

    final double w = _boardBounds.width;
    final double h = _boardBounds.height;

    // Calculate X coordinates for Gap 1 and Gap 2
    final double gap1X = _boardBounds.left + w * 0.35;
    final double gap2X = _boardBounds.left + w * 0.65;

    bool hitAny = false;
    final random = math.Random();

    for (var item in _items) {
      if (item.health <= 0.0) continue;

      final double itemX = item.gapIndex == 1 ? gap1X : gap2X;
      final double itemY = _boardBounds.top + item.normalizedY * h;
      final Offset itemPos = Offset(itemX, itemY);

      final double distance = (_touchPos - itemPos).distance;

      // Check if floss is pulling against this item in the interdental gap
      if (distance < 50.0) {
        hitAny = true;
        setState(() {
          item.isShaking = true;
          // Apply sawing/pulling damage
          double damage = 0.04 + (dragDistance * 0.012);
          item.health = (item.health - damage).clamp(0.0, 1.0);
        });

        if (random.nextDouble() < 0.4) {
          _sparkles.add(
            _Sparkle(
              position: itemPos + Offset(random.nextDouble() * 20 - 10, random.nextDouble() * 20 - 10),
              vx: random.nextDouble() * 4 - 2,
              vy: random.nextDouble() * 4 - 2,
              size: random.nextDouble() * 10 + 5,
              color: item.color,
            ),
          );
        }

        HapticFeedback.lightImpact();

        if (item.health <= 0.0) {
          HapticFeedback.mediumImpact();
          // Burst into stars & crumbs
          for (int k = 0; k < 12; k++) {
            final angle = k * (2 * math.pi / 12);
            final speed = random.nextDouble() * 4 + 2;
            _sparkles.add(
              _Sparkle(
                position: itemPos,
                vx: math.cos(angle) * speed,
                vy: math.sin(angle) * speed,
                size: random.nextDouble() * 14 + 8,
                color: item.color,
                isStar: true,
              ),
            );
          }
          _checkProgress();
        }
      } else {
        setState(() {
          item.isShaking = false;
        });
      }
    }

    if (!hitAny && _isDragging && dragDistance > 2.0) {
      _distanceWithoutHit += dragDistance;
      if (_distanceWithoutHit > 200.0) {
        _distanceWithoutHit = 0.0;
        _showTooltip("نخ دندان را داخل فاصله بین دندان‌ها (بالا و پایین) بکش! ⬇️⬆️");
      }
    } else if (hitAny) {
      _distanceWithoutHit = 0.0;
    }
  }

  void _checkProgress() {
    final activeCount = _items.where((i) => i.health > 0.0).length;
    setState(() {
      _cleanlinessProgress = _totalItems > 0
          ? (1.0 - (activeCount / _totalItems))
          : 1.0;
    });

    if (activeCount == 0 && !_isSuccess) {
      setState(() {
        _isSuccess = true;
        _initCelebration();
      });
      HapticFeedback.vibrate();
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          _showVictoryDialog();
        }
      });
    }
  }

  void _showTooltip(String message) {
    if (_tooltipText == message) return;
    setState(() {
      _tooltipText = message;
    });
    _tooltipTimer?.cancel();
    _tooltipTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _tooltipText = '';
        });
      }
    });
  }

  void _showVictoryDialog() {
    final activeChild = HealthcareApi.instance.currentChild;
    if (activeChild != null) {
      HealthcareApi.instance.children.logActivity(
        activeChild.id,
        ActivityLogRequest(
          activityType: 'flossing',
          durationSeconds: 60,
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

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, a1, a2) => const SizedBox(),
      transitionBuilder: (context, anim, secAnim, child) {
        final scale = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.elasticOut));
        return Transform.scale(
          scale: scale.value,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 10,
              backgroundColor: Colors.white,
              title: const Text(
                'آفرین قهرمان نخ دندان! 🌟👑',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFA801),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'صد آفرین دوست تمیز من! تمام غذاها و میکروب‌های گیرکرده بین دندان‌ها رو با موفقیت پاک کردی. دندون‌هات از خوشحالی می‌خندن! 😁✨',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 32 + (index == 1 ? 12.0 : 0.0),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                SquishPopButton(
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _initGame();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA801),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFA801).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'بازی دوباره 🧵',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SquishPopButton(
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
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
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFF3E0),
                Color(0xFFFFF8E1),
              ],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Column(
                      children: [
                        _buildAppBar(),
                        const SizedBox(height: 10),
                        _buildHeaderCard(constraints),
                        const SizedBox(height: 10),
                        if (_tooltipText.isNotEmpty) _buildTooltip(),
                        const Spacer(),
                        _buildInteractiveBoard(constraints),
                        const Spacer(),
                        _buildResetButton(),
                        const SizedBox(height: 16),
                      ],
                    ),

                    // Particle layer
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _FlossParticlesPainter(sparkles: _sparkles),
                        ),
                      ),
                    ),

                    // Confetti layer
                    if (_isSuccess)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _FlossConfettiPainter(confetti: _confetti),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SquishPopButton(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Color(0xFF2C3E50),
                size: 24,
              ),
            ),
          ),
          const Text(
            'بازی با نخ دندان 🧵',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(BoxConstraints constraints) {
    final int remainingCount = _items.where((i) => i.health > 0.0).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _isSuccess
                ? 'دندان‌ها از تمیزی دارن برق می‌زنن! 😍✨'
                : 'نخ دندان را لای دندان‌ها بکش تا غذاها و میکروب‌ها پاک شوند! 🦷',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _isSuccess ? const Color(0xFF2ECC71) : const Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: (constraints.maxWidth - 120) * _cleanlinessProgress,
                      height: 18,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFA801), Color(0xFFFFC312)],
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
                  color: Color(0xFFFFA801),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          if (!_isSuccess) ...[
            const SizedBox(height: 6),
            Text(
              'موارد باقی‌مانده در لای دندان‌ها: $remainingCount مورد',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTooltip() {
    return AnimatedOpacity(
      opacity: _tooltipText.isNotEmpty ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.shade800.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _tooltipText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveBoard(BoxConstraints constraints) {
    final double boardWidth = constraints.maxWidth - 20;
    final double boardHeight = 360.0;

    return Center(
      child: Container(
        width: boardWidth,
        height: boardHeight,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),
        ),
        child: LayoutBuilder(
          builder: (context, boardConstraints) {
            _boardBounds = Rect.fromLTWH(0, 0, boardConstraints.maxWidth, boardConstraints.maxHeight);
            final double w = boardConstraints.maxWidth;
            final double h = boardConstraints.maxHeight;

            final double toothWidth = w * 0.28;
            final double toothHeight = h * 0.75;

            // X centers for 3 adjacent teeth
            final double leftToothX = w * 0.17;
            final double centerToothX = w * 0.50;
            final double rightToothX = w * 0.83;

            // Gap X centers
            final double gap1X = w * 0.35;
            final double gap2X = w * 0.65;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (d) => _onPanStart(d, constraints),
              onPanUpdate: (d) => _onPanUpdate(d, constraints),
              onPanEnd: _onPanEnd,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Gums background arch at the top
                  Positioned(
                    top: 0,
                    left: w * 0.05,
                    right: w * 0.05,
                    height: h * 0.28,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFFFF8A8A).withValues(alpha: 0.8),
                            const Color(0xFFFFB5C5).withValues(alpha: 0.3),
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(100),
                        ),
                      ),
                    ),
                  ),

                  // Left Tooth
                  Positioned(
                    left: leftToothX - (toothWidth / 2),
                    top: h * 0.12,
                    width: toothWidth,
                    height: toothHeight,
                    child: AnimatedBuilder(
                      animation: _floatingController,
                      builder: (context, child) {
                        final offset = math.sin(_floatingController.value * math.pi * 2) * 4.0;
                        return Transform.translate(
                          offset: Offset(0, offset),
                          child: CustomPaint(
                            painter: ToothPainter(
                              expression: _isSuccess ? 'winking' : 'happy',
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Center Tooth
                  Positioned(
                    left: centerToothX - (toothWidth / 2),
                    top: h * 0.12,
                    width: toothWidth,
                    height: toothHeight,
                    child: AnimatedBuilder(
                      animation: _floatingController,
                      builder: (context, child) {
                        final offset = math.sin((_floatingController.value * math.pi * 2) + 1.0) * 4.0;
                        return Transform.translate(
                          offset: Offset(0, offset),
                          child: CustomPaint(
                            painter: ToothPainter(
                              expression: _isSuccess ? 'happy' : 'brushing',
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Right Tooth
                  Positioned(
                    left: rightToothX - (toothWidth / 2),
                    top: h * 0.12,
                    width: toothWidth,
                    height: toothHeight,
                    child: AnimatedBuilder(
                      animation: _floatingController,
                      builder: (context, child) {
                        final offset = math.sin((_floatingController.value * math.pi * 2) + 2.0) * 4.0;
                        return Transform.translate(
                          offset: Offset(0, offset),
                          child: CustomPaint(
                            painter: ToothPainter(
                              expression: _isSuccess ? 'winking' : 'happy',
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Stuck items inside interdental Gaps (Gap 1 & Gap 2)
                  ..._items.map((item) {
                    if (item.health <= 0.0) return const SizedBox.shrink();

                    final double itemX = item.gapIndex == 1 ? gap1X : gap2X;
                    final double itemY = item.normalizedY * h;

                    return AnimatedBuilder(
                      animation: _wiggleController,
                      builder: (context, child) {
                        double shakeX = 0.0;
                        double shakeY = 0.0;
                        if (item.isShaking) {
                          shakeX = (math.Random().nextDouble() * 8 - 4);
                          shakeY = (math.Random().nextDouble() * 8 - 4);
                        } else {
                          shakeY = math.sin(_wiggleController.value * math.pi * 2 + item.id) * 3.0;
                        }

                        return Positioned(
                          left: itemX - 22 + shakeX,
                          top: itemY - 22 + shakeY,
                          child: Transform.scale(
                            scale: 0.6 + (0.4 * item.health),
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: CustomPaint(
                                painter: _StuckItemPainter(item: item),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }),

                  // Floss String and Anchors (Custom Painter)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _FlossStringPainter(
                          touchPos: _touchPos,
                          isDragging: _isDragging,
                          isSuccess: _isSuccess,
                        ),
                      ),
                    ),
                  ),

                  // Guide gesture finger hint if not dragging and not success
                  if (!_isDragging && !_isSuccess && _cleanlinessProgress == 0.0)
                    Positioned(
                      left: gap1X - 25,
                      top: h * 0.45,
                      child: AnimatedBuilder(
                        animation: _floatingController,
                        builder: (context, child) {
                          final offset = math.sin(_floatingController.value * math.pi * 2) * 15.0;
                          return Transform.translate(
                            offset: Offset(0, offset),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.touch_app,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    return SquishPopButton(
      onTap: () {
        HapticFeedback.mediumImpact();
        setState(() {
          _initGame();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFFA801).withValues(alpha: 0.4),
            width: 2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh, color: Color(0xFFFFA801)),
            SizedBox(width: 8),
            Text(
              'شروع مجدد بازی 🔄',
              style: TextStyle(
                color: Color(0xFFFFA801),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StuckItem {
  final int id;
  final int gapIndex;
  final double normalizedY;
  final String type;
  final String foodType;
  final Color color;
  double health = 1.0;
  bool isShaking = false;

  _StuckItem({
    required this.id,
    required this.gapIndex,
    required this.normalizedY,
    required this.type,
    this.foodType = '',
    required this.color,
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

class _StuckItemPainter extends CustomPainter {
  final _StuckItem item;

  _StuckItemPainter({required this.item});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final Offset center = Offset(w / 2, h / 2);

    final Paint bodyPaint = Paint()
      ..color = item.color
      ..style = PaintingStyle.fill;

    if (item.type == 'germ') {
      // Draw cute monster germ
      final Path path = Path();
      path.addOval(Rect.fromCenter(center: center, width: w * 0.9, height: h * 0.8));
      canvas.drawPath(path, bodyPaint);

      // Spikes/teeth around germ
      final Paint spikePaint = Paint()..color = item.color.withValues(alpha: 0.8);
      for (int i = 0; i < 6; i++) {
        final double angle = i * (math.pi / 3);
        final double sx = center.dx + math.cos(angle) * (w * 0.45);
        final double sy = center.dy + math.sin(angle) * (h * 0.45);
        canvas.drawCircle(Offset(sx, sy), 5, spikePaint);
      }

      // Eyes
      final Paint eyeWhite = Paint()..color = Colors.white;
      final Paint eyePupil = Paint()..color = Colors.black;
      canvas.drawCircle(Offset(w * 0.35, h * 0.42), 6, eyeWhite);
      canvas.drawCircle(Offset(w * 0.37, h * 0.42), 3, eyePupil);
      canvas.drawCircle(Offset(w * 0.65, h * 0.42), 6, eyeWhite);
      canvas.drawCircle(Offset(w * 0.63, h * 0.42), 3, eyePupil);

      // Angry/struggling brow
      final Paint browPaint = Paint()
        ..color = Colors.black87
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(w * 0.25, h * 0.30), Offset(w * 0.45, h * 0.35), browPaint);
      canvas.drawLine(Offset(w * 0.75, h * 0.30), Offset(w * 0.55, h * 0.35), browPaint);

      // Mouth
      final Path mouthPath = Path();
      mouthPath.moveTo(w * 0.35, h * 0.65);
      mouthPath.quadraticBezierTo(w * 0.5, h * 0.55, w * 0.65, h * 0.65);
      canvas.drawPath(mouthPath, browPaint);
    } else {
      // Food bits (leaf, cheese, meat chunk)
      if (item.foodType == 'leaf') {
        // Herb / spinach leaf shape
        final Path leafPath = Path();
        leafPath.moveTo(w * 0.1, h * 0.5);
        leafPath.quadraticBezierTo(w * 0.5, h * 0.05, w * 0.9, h * 0.5);
        leafPath.quadraticBezierTo(w * 0.5, h * 0.95, w * 0.1, h * 0.5);
        leafPath.close();
        canvas.drawPath(leafPath, bodyPaint);

        // Leaf veins
        final Paint veinPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.6)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(w * 0.2, h * 0.5), Offset(w * 0.8, h * 0.5), veinPaint);
        canvas.drawLine(Offset(w * 0.4, h * 0.5), Offset(w * 0.55, h * 0.35), veinPaint);
        canvas.drawLine(Offset(w * 0.5, h * 0.5), Offset(w * 0.65, h * 0.65), veinPaint);
      } else if (item.foodType == 'cheese') {
        // Cheese/corn triangle bit
        final Path triPath = Path();
        triPath.moveTo(w * 0.5, h * 0.1);
        triPath.lineTo(w * 0.9, h * 0.85);
        triPath.lineTo(w * 0.1, h * 0.85);
        triPath.close();
        canvas.drawPath(triPath, bodyPaint);

        // Cheese holes
        final Paint holePaint = Paint()..color = Colors.orange.shade900.withValues(alpha: 0.3);
        canvas.drawCircle(Offset(w * 0.5, h * 0.55), 4, holePaint);
        canvas.drawCircle(Offset(w * 0.35, h * 0.7), 3, holePaint);
        canvas.drawCircle(Offset(w * 0.65, h * 0.75), 5, holePaint);
      } else {
        // Meat / berry round chunk
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.15, h * 0.15, w * 0.7, h * 0.7), const Radius.circular(12)),
          bodyPaint,
        );
        final Paint bonePaint = Paint()..color = Colors.white.withValues(alpha: 0.8);
        canvas.drawCircle(Offset(w * 0.35, h * 0.35), 4, bonePaint);
        canvas.drawCircle(Offset(w * 0.65, h * 0.65), 5, bonePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StuckItemPainter oldDelegate) {
    return oldDelegate.item.health != item.health ||
        oldDelegate.item.isShaking != item.isShaking;
  }
}

class _FlossStringPainter extends CustomPainter {
  final Offset touchPos;
  final bool isDragging;
  final bool isSuccess;

  _FlossStringPainter({
    required this.touchPos,
    required this.isDragging,
    required this.isSuccess,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (isSuccess) return;

    final double w = size.width;
    final double h = size.height;

    // Default resting floss horizontal line when not dragging
    Offset leftAnchor = Offset(w * 0.05, touchPos.dy.clamp(h * 0.2, h * 0.8));
    Offset rightAnchor = Offset(w * 0.95, touchPos.dy.clamp(h * 0.2, h * 0.8));
    Offset centerControl = touchPos;

    if (!isDragging) {
      leftAnchor = Offset(w * 0.05, h * 0.5);
      rightAnchor = Offset(w * 0.95, h * 0.5);
      centerControl = Offset(w * 0.5, h * 0.5);
    } else {
      leftAnchor = Offset(w * 0.05, (touchPos.dy - 30).clamp(h * 0.1, h * 0.9));
      rightAnchor = Offset(w * 0.95, (touchPos.dy - 30).clamp(h * 0.1, h * 0.9));
    }

    // Shadow of floss
    final Paint shadowPaint = Paint()
      ..color = const Color(0xFFFFA801).withValues(alpha: 0.3)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final Path stringPath = Path();
    stringPath.moveTo(leftAnchor.dx, leftAnchor.dy);
    stringPath.quadraticBezierTo(centerControl.dx, centerControl.dy, rightAnchor.dx, rightAnchor.dy);

    canvas.drawPath(stringPath, shadowPaint);

    // Main white floss string
    final Paint stringPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(stringPath, stringPaint);

    // Left and Right floss spool handle clips
    _drawHandle(canvas, leftAnchor);
    _drawHandle(canvas, rightAnchor);

    // If dragging, draw little glowing ring at touch position (where finger is pulling)
    if (isDragging) {
      final Paint ringPaint = Paint()
        ..color = const Color(0xFFFFA801).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(touchPos, 18, ringPaint);
    }
  }

  void _drawHandle(Canvas canvas, Offset pos) {
    final Paint handlePaint = Paint()
      ..color = const Color(0xFFFFA801)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: pos, width: 20, height: 28),
        const Radius.circular(6),
      ),
      handlePaint,
    );

    final Paint detailPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, 4, detailPaint);
  }

  @override
  bool shouldRepaint(covariant _FlossStringPainter oldDelegate) {
    return oldDelegate.touchPos != touchPos ||
        oldDelegate.isDragging != isDragging ||
        oldDelegate.isSuccess != isSuccess;
  }
}

class _FlossParticlesPainter extends CustomPainter {
  final List<_Sparkle> sparkles;

  _FlossParticlesPainter({required this.sparkles});

  @override
  void paint(Canvas canvas, Size size) {
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
  bool shouldRepaint(covariant _FlossParticlesPainter oldDelegate) => true;
}

class _FlossConfettiPainter extends CustomPainter {
  final List<_Confetti> confetti;

  _FlossConfettiPainter({required this.confetti});

  @override
  void paint(Canvas canvas, Size size) {
    for (var conf in confetti) {
      final paint = Paint()
        ..color = conf.color
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(conf.position.dx, conf.position.dy);
      canvas.rotate(conf.rotation);

      if (conf.size.toInt() % 2 == 0) {
        canvas.drawRect(
          Rect.fromLTWH(-conf.size / 2, -conf.size / 4, conf.size, conf.size / 2),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, conf.size / 2, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _FlossConfettiPainter oldDelegate) => true;
}
