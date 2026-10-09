import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/squish_pop.dart';
import '../api/healthcare_api.dart';

class FlossScreen extends StatefulWidget {
  const FlossScreen({super.key});

  @override
  State<FlossScreen> createState() => _FlossScreenState();
}

class _FlossScreenState extends State<FlossScreen> with TickerProviderStateMixin {
  Offset _touchPos = const Offset(200, 300);
  bool _isDragging = false;
  bool _isSuccess = false;
  bool _showTrashAnimation = false;

  List<_StuckItem> _items = [];
  final List<_Sparkle> _sparkles = [];
  final List<_FlyingMicrobe> _flyingMicrobes = [];

  double _cleanlinessProgress = 0.0;
  int _totalItems = 10;
  String _tooltipText = '';
  Timer? _tooltipTimer;

  late AnimationController _floatingController;
  late AnimationController _wiggleController;
  late AnimationController _celebrationController;
  late AnimationController _trashLidController;
  late AnimationController _microbesFlyController;
  late AnimationController _brightenController;
  late Animation<double> _brightenAnimation;
  late Animation<double> _gleamAnimation;
  Timer? _updateTimer;

  double _distanceWithoutHit = 0.0;

  // Track which gap the floss is currently in (for deep cleaning mechanic)
  int _currentFlossGap = -1;
  double _flossDepthInGap = 0.0; // 0.0 = top, 1.0 = deep bottom

  @override
  void initState() {
    super.initState();

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..repeat(reverse: true);

    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _trashLidController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _microbesFlyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _brightenController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _brightenAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _brightenController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );

    _gleamAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _brightenController,
        curve: const Interval(0.12, 0.88, curve: Curves.easeInOutCubic),
      ),
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
    _trashLidController.dispose();
    _microbesFlyController.dispose();
    _brightenController.dispose();
    _updateTimer?.cancel();
    _tooltipTimer?.cancel();
    super.dispose();
  }

  void _initGame() {
    // Exact image resolution of natural_teeth.jpg: 1376 x 768
    // User requested germs at exact pixel coordinates (px):
    // 1) 229, 367
    // 2) 425, 374
    // 3) 701, 385
    // 4) 960, 379
    // 5) 1149, 370
    // Food particles are placed deep in the gaps and require reaching depth to clean.
    _items = [
      // --- Gap 1 (px: 229) ---
      _StuckItem(
        id: 1,
        gapIndex: 1,
        normalizedX: 229.0 / 1376.0,
        normalizedY: 367.0 / 768.0,
        type: 'germ',
        color: const Color(0xFF9B59B6),
        label: 'میکروب ۱',
        depthRequired: 0.40,
      ),
      _StuckItem(
        id: 2,
        gapIndex: 1,
        normalizedX: 229.0 / 1376.0,
        normalizedY: 455.0 / 768.0,
        type: 'food',
        foodType: 'leaf',
        color: const Color(0xFF27AE60),
        label: 'اسفناج در عمق دندان',
        depthRequired: 0.65,
      ),

      // --- Gap 2 (px: 425) ---
      _StuckItem(
        id: 3,
        gapIndex: 2,
        normalizedX: 425.0 / 1376.0,
        normalizedY: 374.0 / 768.0,
        type: 'germ',
        color: const Color(0xFFE74C3C),
        label: 'میکروب ۲',
        depthRequired: 0.42,
      ),
      _StuckItem(
        id: 4,
        gapIndex: 2,
        normalizedX: 425.0 / 1376.0,
        normalizedY: 465.0 / 768.0,
        type: 'food',
        foodType: 'cheese',
        color: const Color(0xFFF1C40F),
        label: 'پنیر در عمق دندان',
        depthRequired: 0.68,
      ),

      // --- Gap 3 (px: 701) ---
      _StuckItem(
        id: 5,
        gapIndex: 3,
        normalizedX: 701.0 / 1376.0,
        normalizedY: 385.0 / 768.0,
        type: 'germ',
        color: const Color(0xFF2ECC71),
        label: 'میکروب ۳',
        depthRequired: 0.45,
      ),
      _StuckItem(
        id: 6,
        gapIndex: 3,
        normalizedX: 701.0 / 1376.0,
        normalizedY: 475.0 / 768.0,
        type: 'food',
        foodType: 'meat',
        color: const Color(0xFFE67E22),
        label: 'گوشت در عمق دندان',
        depthRequired: 0.70,
      ),

      // --- Gap 4 (px: 960) ---
      _StuckItem(
        id: 7,
        gapIndex: 4,
        normalizedX: 960.0 / 1376.0,
        normalizedY: 379.0 / 768.0,
        type: 'germ',
        color: const Color(0xFF1ABC9C),
        label: 'میکروب ۴',
        depthRequired: 0.42,
      ),
      _StuckItem(
        id: 8,
        gapIndex: 4,
        normalizedX: 960.0 / 1376.0,
        normalizedY: 465.0 / 768.0,
        type: 'food',
        foodType: 'seed',
        color: const Color(0xFFD35400),
        label: 'تخمه در عمق دندان',
        depthRequired: 0.68,
      ),

      // --- Gap 5 (px: 1149) ---
      _StuckItem(
        id: 9,
        gapIndex: 5,
        normalizedX: 1149.0 / 1376.0,
        normalizedY: 370.0 / 768.0,
        type: 'germ',
        color: const Color(0xFFFD79A8),
        label: 'میکروب ۵',
        depthRequired: 0.40,
      ),
      _StuckItem(
        id: 10,
        gapIndex: 5,
        normalizedX: 1149.0 / 1376.0,
        normalizedY: 455.0 / 768.0,
        type: 'food',
        foodType: 'apple',
        color: const Color(0xFFE74C3C),
        label: 'سیب در عمق دندان',
        depthRequired: 0.65,
      ),
    ];

    _totalItems = _items.length;
    _cleanlinessProgress = 0.0;
    _isSuccess = false;
    _showTrashAnimation = false;
    _sparkles.clear();
    _flyingMicrobes.clear();
    _celebrationController.stop();
    _trashLidController.reset();
    _microbesFlyController.reset();
    _brightenController.reset();
    _currentFlossGap = -1;
    _flossDepthInGap = 0.0;
  }

  void _startTrashAnimation() {
    _flyingMicrobes.clear();

    final screenSize = MediaQuery.of(context).size;
    const double imageAspect = 1376.0 / 768.0;
    final double maxAvailableWidth = screenSize.width - 24;
    final double maxAvailableHeight = (screenSize.height * 0.52).clamp(240.0, 440.0);

    double boardWidth = maxAvailableWidth;
    double boardHeight = boardWidth / imageAspect;
    if (boardHeight > maxAvailableHeight) {
      boardHeight = maxAvailableHeight;
      boardWidth = boardHeight * imageAspect;
    }

    final double boardLeft = (screenSize.width - boardWidth) / 2;
    final double boardTop = (screenSize.height - boardHeight) / 2 - 20;

    // 5 exact germ positions on natural_teeth.jpg (1376 x 768)
    final germCoords = [
      const Offset(229.0 / 1376.0, 367.0 / 768.0),
      const Offset(425.0 / 1376.0, 374.0 / 768.0),
      const Offset(701.0 / 1376.0, 385.0 / 768.0),
      const Offset(960.0 / 1376.0, 379.0 / 768.0),
      const Offset(1149.0 / 1376.0, 370.0 / 768.0),
    ];

    final microbeImages = [
      'microbe_green',
      'microbe_purple',
      'microbe_green',
      'microbe_purple',
      'microbe_green',
    ];
    final microbeColors = [
      const Color(0xFF9B59B6),
      const Color(0xFFE74C3C),
      const Color(0xFF2ECC71),
      const Color(0xFF1ABC9C),
      const Color(0xFFFD79A8),
    ];

    for (int i = 0; i < 5; i++) {
      final startX = boardLeft + germCoords[i].dx * boardWidth;
      final startY = boardTop + germCoords[i].dy * boardHeight;

      _flyingMicrobes.add(
        _FlyingMicrobe(
          startX: startX,
          startY: startY,
          color: microbeColors[i],
          imageType: microbeImages[i],
          delay: i * 0.12,
          size: 42,
        ),
      );
    }

    setState(() {
      _showTrashAnimation = true;
    });

    _microbesFlyController.forward(from: 0.0);

    // After microbes land in trash, close the lid
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        _trashLidController.forward(from: 0.0);
      }
    });

    // Show victory dialog after full animation
    Future.delayed(const Duration(milliseconds: 3600), () {
      if (mounted) {
        _showVictoryDialog();
      }
    });
  }

  void _updateGameLoop() {
    setState(() {
      for (int i = _sparkles.length - 1; i >= 0; i--) {
        if (i >= _sparkles.length) continue;
        final sparkle = _sparkles[i];
        sparkle.progress += 0.035;
        sparkle.position += Offset(sparkle.vx, sparkle.vy);
        if (sparkle.progress >= 1.0) {
          _sparkles.removeAt(i);
        }
      }
    });
  }

  void _onPanStart(DragStartDetails details, Size boardSize) {
    if (_isSuccess) return;
    setState(() {
      _isDragging = true;
      _touchPos = details.localPosition;
    });
    _updateFlossDepth(boardSize);
    _checkFlossHit(boardSize);
  }

  void _onPanUpdate(DragUpdateDetails details, Size boardSize) {
    if (_isSuccess) return;
    setState(() {
      final double dx = details.delta.dx;
      final double dy = details.delta.dy;
      final double dist = math.sqrt(dx * dx + dy * dy);

      _touchPos = details.localPosition;
      _updateFlossDepth(boardSize);
      _checkFlossHit(boardSize, dragDistance: dist);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      _currentFlossGap = -1;
      _flossDepthInGap = 0.0;
      for (var item in _items) {
        item.isShaking = false;
      }
    });
  }

  void _updateFlossDepth(Size boardSize) {
    final double w = boardSize.width;
    final double h = boardSize.height;

    final gapXPositions = [
      w * (229.0 / 1376.0),
      w * (425.0 / 1376.0),
      w * (701.0 / 1376.0),
      w * (960.0 / 1376.0),
      w * (1149.0 / 1376.0),
    ];

    // Determine which gap the floss is in
    int closestGap = -1;
    double closestDist = double.infinity;

    for (int i = 0; i < gapXPositions.length; i++) {
      final dist = (_touchPos.dx - gapXPositions[i]).abs();
      if (dist < w * 0.09 && dist < closestDist) {
        closestDist = dist;
        closestGap = i + 1;
      }
    }

    _currentFlossGap = closestGap;

    if (closestGap > 0) {
      // Calculate depth based on Y position (gum top = 0.20, bottom edge = 0.75)
      final double teethTop = h * 0.20;
      final double teethBottom = h * 0.75;
      _flossDepthInGap = ((_touchPos.dy - teethTop) / (teethBottom - teethTop)).clamp(0.0, 1.0);
    } else {
      _flossDepthInGap = 0.0;
    }
  }

  void _checkFlossHit(Size boardSize, {double dragDistance = 0.0}) {
    if (boardSize.width <= 0 || boardSize.height <= 0) return;

    final double w = boardSize.width;
    final double h = boardSize.height;

    bool hitAny = false;
    final random = math.Random();

    for (var item in _items) {
      if (item.health <= 0.0) continue;

      final double itemX = item.normalizedX * w;
      final double itemY = item.normalizedY * h;
      final Offset itemPos = Offset(itemX, itemY);

      final double distance = (_touchPos - itemPos).distance;

      // Only damage items if floss has reached deep enough in this gap
      final bool isInCorrectGap = _currentFlossGap == item.gapIndex;
      final bool isDeepEnough = isInCorrectGap && _flossDepthInGap >= item.depthRequired;

      if (distance < 50.0 && isDeepEnough) {
        hitAny = true;
        setState(() {
          item.isShaking = true;
          double damage = 0.055 + (dragDistance * 0.018);
          item.health = (item.health - damage).clamp(0.0, 1.0);
        });

        if (random.nextDouble() < 0.45) {
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
          for (int k = 0; k < 14; k++) {
            final angle = k * (2 * math.pi / 14);
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
      } else if (distance < 50.0 && !isDeepEnough && isInCorrectGap) {
        // Near the item but not deep enough — shake to hint
        setState(() {
          item.isShaking = true;
        });
        if (_tooltipText.isEmpty) {
          _showTooltip("نخ دندان رو بیشتر به عمق فاصله دندان‌ها بکش! ⬇️");
        }
      } else {
        setState(() {
          item.isShaking = false;
        });
      }
    }

    if (!hitAny && _isDragging && dragDistance > 2.0) {
      _distanceWithoutHit += dragDistance;
      if (_distanceWithoutHit > 180.0) {
        _distanceWithoutHit = 0.0;
        _showTooltip("نخ دندان را بالا و پایین بین فاصله دندان‌ها حرکت بده! ⬇️⬆️");
      }
    } else if (hitAny) {
      _distanceWithoutHit = 0.0;
    }
  }

  void _checkProgress() {
    final activeCount = _items.where((i) => i.health > 0.0).length;
    setState(() {
      _cleanlinessProgress = _totalItems > 0 ? (1.0 - (activeCount / _totalItems)) : 1.0;
    });

    if (activeCount == 0 && !_isSuccess) {
      setState(() {
        _isSuccess = true;
      });
      HapticFeedback.vibrate();

      // 1) Immediately brighten teeth with gleaming white shine and sparkles
      _brightenController.forward(from: 0.0);
      _spawnTeethSparkles();

      // 2) Microbes cry and fly into the trash can after teeth shine
      Future.delayed(const Duration(milliseconds: 1300), () {
        if (mounted) {
          _startTrashAnimation();
        }
      });
    }
  }

  void _spawnTeethSparkles() {
    final random = math.Random();
    for (int i = 0; i < 22; i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final speed = random.nextDouble() * 5 + 2;
      _sparkles.add(
        _Sparkle(
          position: Offset(
            _touchPos.dx + (random.nextDouble() * 140 - 70),
            _touchPos.dy + (random.nextDouble() * 80 - 40),
          ),
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed,
          size: random.nextDouble() * 16 + 8,
          color: Colors.amber.shade200,
          isStar: true,
        ),
      );
    }
  }

  void _showTooltip(String message) {
    if (_tooltipText == message) return;
    setState(() {
      _tooltipText = message;
    });
    _tooltipTimer?.cancel();
    _tooltipTimer = Timer(const Duration(milliseconds: 2600), () {
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
        HealthcareApi.instance.currentChild = activeChild.copyWith(
          stars: oldStars + res.starsEarned,
        );
      }).catchError((_) {});
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 450),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 12,
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
                  // Show the closed trash can image in dialog
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/floss/trash_closed.jpg',
                      height: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'تمام میکروب‌ها گریه‌کنان به سطل آشغال رفتن و درب سطل بسته شد! 😁🗑️\nدندون‌هات حالا پاک و سالمه!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 36 + (index == 1 ? 12.0 : 0.0),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA801),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFA801).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'بازی دوباره 🧵',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SquishPopButton(
                  onTap: () {
                    Navigator.of(context).pop();
                    if (Navigator.canPop(context)) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2ECC71),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2ECC71).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'بازگشت به خانه 🏠',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
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
                        const SizedBox(height: 8),
                        _buildHeaderCard(constraints),
                        const SizedBox(height: 8),
                        if (_tooltipText.isNotEmpty) _buildTooltip(),
                        const Spacer(),
                        _buildInteractiveBoard(constraints),
                        const Spacer(),
                        _buildResetButton(),
                        const SizedBox(height: 14),
                      ],
                    ),

                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _FlossParticlesPainter(sparkles: List.of(_sparkles)),
                        ),
                      ),
                    ),

                    // Trash animation overlay
                    if (_showTrashAnimation)
                      Positioned.fill(
                        child: _buildTrashAnimationOverlay(),
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

  Widget _buildTrashAnimationOverlay() {
    return AnimatedBuilder(
      animation: Listenable.merge([_microbesFlyController, _trashLidController]),
      builder: (context, child) {
        final flyProgress = _microbesFlyController.value;
        final lidProgress = _trashLidController.value;

        return Container(
          color: Colors.black.withValues(alpha: 0.3 * flyProgress.clamp(0.0, 1.0)),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Trash can at the bottom center
              Positioned(
                bottom: 80,
                child: SizedBox(
                  width: 120,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Trash body (open initially, closed after lid animation)
                      Image.asset(
                        lidProgress > 0.8
                            ? 'assets/floss/trash_closed.jpg'
                            : 'assets/floss/trash_open.jpg',
                        width: 120,
                        height: 140,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),
              ),

              // Flying crying microbes
              ..._flyingMicrobes.map((microbe) {
                final adjustedProgress = ((flyProgress - microbe.delay) / (1.0 - microbe.delay)).clamp(0.0, 1.0);
                final curvedProgress = Curves.easeInQuad.transform(adjustedProgress);

                // Calculate screen center bottom for trash can target
                final screenSize = MediaQuery.of(context).size;
                final targetX = screenSize.width / 2;
                final targetY = screenSize.height - 160;

                final currentX = microbe.startX + (targetX - microbe.startX) * curvedProgress;
                final currentY = microbe.startY + (targetY - microbe.startY) * curvedProgress;

                final opacity = adjustedProgress < 0.9 ? 1.0 : (1.0 - (adjustedProgress - 0.9) * 10).clamp(0.0, 1.0);
                final rotation = curvedProgress * math.pi * 2;
                final scale = 1.0 - (curvedProgress * 0.5);

                if (adjustedProgress <= 0.0) return const SizedBox.shrink();

                return Positioned(
                  left: currentX - microbe.size / 2,
                  top: currentY - microbe.size / 2,
                  child: Opacity(
                    opacity: opacity,
                    child: Transform.rotate(
                      angle: rotation,
                      child: Transform.scale(
                        scale: scale,
                        child: _buildCryingMicrobeWidget(microbe),
                      ),
                    ),
                  ),
                );
              }),

              // "Microbes going to trash!" text
              if (flyProgress > 0.1 && flyProgress < 0.85)
                Positioned(
                  top: 120,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      '😭 میکروب‌ها گریه‌کنان به سطل آشغال می‌رن! 🗑️',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ),
                ),

              // Lid closing text
              if (lidProgress > 0.3)
                Positioned(
                  bottom: 230,
                  child: AnimatedOpacity(
                    opacity: lidProgress > 0.3 ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2ECC71).withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Text(
                        '🔒 درب سطل آشغال بسته شد!',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
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

  Widget _buildCryingMicrobeWidget(_FlyingMicrobe microbe) {
    return SizedBox(
      width: microbe.size,
      height: microbe.size,
      child: Stack(
        children: [
          // Use microbe image
          ClipOval(
            child: Image.asset(
              'assets/floss/${microbe.imageType}.jpg',
              width: microbe.size,
              height: microbe.size,
              fit: BoxFit.cover,
            ),
          ),
          // Tear drops
          Positioned(
            left: microbe.size * 0.2,
            top: microbe.size * 0.5,
            child: Icon(
              Icons.water_drop,
              color: Colors.blue.shade200,
              size: microbe.size * 0.25,
            ),
          ),
          Positioned(
            right: microbe.size * 0.2,
            top: microbe.size * 0.45,
            child: Icon(
              Icons.water_drop,
              color: Colors.blue.shade300,
              size: microbe.size * 0.2,
            ),
          ),
        ],
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
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.of(context).pop();
              }
            },
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
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
                ? 'میکروب‌ها گریه‌کنان به سطل آشغال رفتن! 😭🗑️'
                : 'نخ دندان را به عمق فاصله دندان‌ها بکش تا خرده‌ها پاک بشن! 🦷',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _isSuccess ? const Color(0xFF2ECC71) : const Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 10),
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
                      width: math.max(0, (constraints.maxWidth - 120) * _cleanlinessProgress),
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
            const SizedBox(height: 4),
            Text(
              'موارد باقی‌مانده: $remainingCount مورد',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
          // Depth indicator
          if (_isDragging && _currentFlossGap > 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.arrow_downward, size: 14, color: Color(0xFFFFA801)),
                const SizedBox(width: 4),
                Text(
                  'عمق نخ دندان: ${(_flossDepthInGap * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFFA801),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _flossDepthInGap,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _flossDepthInGap > 0.7 ? const Color(0xFF2ECC71) : const Color(0xFFFFA801),
                      ),
                    ),
                  ),
                ),
              ],
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
    const double imageAspect = 1376.0 / 768.0;
    final double maxAvailableWidth = constraints.maxWidth - 24;
    final double maxAvailableHeight = (constraints.maxHeight * 0.52).clamp(240.0, 440.0);

    double boardWidth = maxAvailableWidth;
    double boardHeight = boardWidth / imageAspect;

    if (boardHeight > maxAvailableHeight) {
      boardHeight = maxAvailableHeight;
      boardWidth = boardHeight * imageAspect;
    }

    final Size boardSize = Size(boardWidth, boardHeight);
    final double w = boardWidth;
    final double h = boardHeight;

    final gapXPositions = [
      w * (229.0 / 1376.0),
      w * (425.0 / 1376.0),
      w * (701.0 / 1376.0),
      w * (960.0 / 1376.0),
      w * (1149.0 / 1376.0),
    ];

    return Center(
      child: Container(
        width: boardWidth,
        height: boardHeight,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B0B17).withValues(alpha: 0.35),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (d) => _onPanStart(d, boardSize),
            onPanUpdate: (d) => _onPanUpdate(d, boardSize),
            onPanEnd: _onPanEnd,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Realistic teeth photo with brightening ColorFilter
                AnimatedBuilder(
                  animation: _brightenController,
                  builder: (context, child) {
                    final double brightVal = _brightenAnimation.value;
                    return ColorFiltered(
                      colorFilter: ColorFilter.matrix([
                        1.0 + 0.35 * brightVal, 0, 0, 0, 45 * brightVal,
                        0, 1.0 + 0.35 * brightVal, 0, 0, 45 * brightVal,
                        0, 0, 1.0 + 0.45 * brightVal, 0, 58 * brightVal,
                        0, 0, 0, 1.0, 0,
                      ]),
                      child: Image.asset(
                        'assets/floss/natural_teeth.jpg',
                        fit: BoxFit.fill,
                        width: w,
                        height: h,
                      ),
                    );
                  },
                ),

                // Luminous sheen, sweeping gleam beam, and sparkling stars
                AnimatedBuilder(
                  animation: _brightenController,
                  builder: (context, child) {
                    return _buildBrighteningTeethOverlay(w, h);
                  },
                ),

                // Semi-transparent overlay for gaps visibility
                Positioned.fill(
                  child: CustomPaint(
                    painter: _GapHighlightPainter(
                      gapPositions: gapXPositions,
                      boardWidth: w,
                      boardHeight: h,
                      currentFlossGap: _currentFlossGap,
                      flossDepth: _flossDepthInGap,
                      isDragging: _isDragging,
                    ),
                  ),
                ),

                // Stuck items (food & germs) deep between teeth
                ..._items.map((item) {
                  if (item.health <= 0.0) return const SizedBox.shrink();

                  final double itemX = item.normalizedX * w;
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

                      final double itemSize = item.type == 'germ' ? 36.0 : 30.0;

                      return Positioned(
                        left: itemX - (itemSize / 2) + shakeX,
                        top: itemY - (itemSize / 2) + shakeY,
                        child: Transform.scale(
                          scale: 0.65 + (0.35 * item.health),
                          child: SizedBox(
                            width: itemSize,
                            height: itemSize,
                            child: CustomPaint(
                              painter: _StuckItemPainter(item: item),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),

                // Floss string
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _FlossStringPainter(
                        touchPos: _touchPos,
                        isDragging: _isDragging,
                        isSuccess: _isSuccess,
                        currentGap: _currentFlossGap,
                        flossDepth: _flossDepthInGap,
                      ),
                    ),
                  ),
                ),

                // Touch hint indicator
                if (!_isDragging && !_isSuccess && _cleanlinessProgress == 0.0)
                  Positioned(
                    left: gapXPositions[0] - 25,
                    top: h * 0.45,
                    child: AnimatedBuilder(
                      animation: _floatingController,
                      builder: (context, child) {
                        final offset = math.sin(_floatingController.value * math.pi * 2) * 14.0;
                        return Transform.translate(
                          offset: Offset(0, offset),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.95),
                                  shape: BoxShape.circle,
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 8,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.touch_app,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'به عمق بکش!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrighteningTeethOverlay(double w, double h) {
    final double brightVal = _brightenAnimation.value;
    final double gleamVal = _gleamAnimation.value;

    return Stack(
      children: [
        // Luminous radiant aura over teeth
        if (brightVal > 0.01)
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: (brightVal * 0.42).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.0, 0.15),
                      radius: 0.85,
                      colors: [
                        Colors.white.withValues(alpha: 0.70),
                        Colors.lightBlue.shade100.withValues(alpha: 0.25),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Diagonal gleam beam shining across teeth
        if (_brightenController.isAnimating || _isSuccess)
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: (math.sin(gleamVal * math.pi) * 0.88).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-2.4 + 4.8 * gleamVal, -1.0),
                      end: Alignment(-1.4 + 4.8 * gleamVal, 1.0),
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.2),
                        Colors.white.withValues(alpha: 0.95),
                        Colors.white.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.42, 0.50, 0.58, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Glint sparkle stars at tooth highlight locations
        if (brightVal > 0.15)
          ..._buildToothSparkleStars(w, h, brightVal),
      ],
    );
  }

  List<Widget> _buildToothSparkleStars(double w, double h, double brightVal) {
    // 4 major enamel highlight reflection points
    final glintPoints = [
      Offset(w * (340.0 / 1376.0), h * (460.0 / 768.0)),
      Offset(w * (580.0 / 1376.0), h * (475.0 / 768.0)),
      Offset(w * (780.0 / 1376.0), h * (475.0 / 768.0)),
      Offset(w * (1030.0 / 1376.0), h * (460.0 / 768.0)),
    ];

    return List.generate(glintPoints.length, (idx) {
      final pt = glintPoints[idx];
      final delay = idx * 0.12;
      final glintProgress = ((brightVal - delay) / 0.55).clamp(0.0, 1.0);
      final double scale = math.sin(glintProgress * math.pi) * 1.35;
      final double rot = glintProgress * math.pi;

      if (glintProgress <= 0.0 || scale <= 0.0) return const SizedBox.shrink();

      return Positioned(
        left: pt.dx - 18,
        top: pt.dy - 18,
        child: IgnorePointer(
          child: Transform.rotate(
            angle: rot,
            child: Transform.scale(
              scale: scale,
              child: SizedBox(
                width: 36,
                height: 36,
                child: CustomPaint(
                  painter: _GlintStarPainter(),
                ),
              ),
            ),
          ),
        ),
      );
    });
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

// Painter to highlight the gaps between teeth where floss should go
class _GapHighlightPainter extends CustomPainter {
  final List<double> gapPositions;
  final double boardWidth;
  final double boardHeight;
  final int currentFlossGap;
  final double flossDepth;
  final bool isDragging;

  _GapHighlightPainter({
    required this.gapPositions,
    required this.boardWidth,
    required this.boardHeight,
    required this.currentFlossGap,
    required this.flossDepth,
    required this.isDragging,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isDragging) return;

    // Highlight the active gap
    for (int i = 0; i < gapPositions.length; i++) {
      final isActive = (i + 1) == currentFlossGap;
      if (!isActive) continue;

      final Paint glowPaint = Paint()
        ..color = const Color(0xFFFFA801).withValues(alpha: 0.15 + (flossDepth * 0.2))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      final double gapWidth = boardWidth * 0.06;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(gapPositions[i], boardHeight * 0.5),
            width: gapWidth,
            height: boardHeight * 0.7,
          ),
          const Radius.circular(12),
        ),
        glowPaint,
      );

      // Depth indicator line
      final depthY = boardHeight * 0.20 + (boardHeight * 0.55 * flossDepth);
      final Paint depthLinePaint = Paint()
        ..color = flossDepth > 0.7
            ? const Color(0xFF2ECC71).withValues(alpha: 0.8)
            : const Color(0xFFFFA801).withValues(alpha: 0.8)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(gapPositions[i] - gapWidth / 2, depthY),
        Offset(gapPositions[i] + gapWidth / 2, depthY),
        depthLinePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GapHighlightPainter oldDelegate) => true;
}

class _GlintStarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cx = size.width / 2;
    final double cy = size.height / 2;

    // Glowing halo
    final Paint glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(cx, cy), 7, glowPaint);

    final Paint starPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // 4-pointed diamond star
    final Path path = Path();
    path.moveTo(cx, 0);
    path.quadraticBezierTo(cx, cy, size.width, cy);
    path.quadraticBezierTo(cx, cy, cx, size.height);
    path.quadraticBezierTo(cx, cy, 0, cy);
    path.quadraticBezierTo(cx, cy, cx, 0);
    path.close();

    canvas.drawPath(path, starPaint);

    // Center bright core
    final Paint corePaint = Paint()..color = const Color(0xFFFFF9C4);
    canvas.drawCircle(Offset(cx, cy), 2.5, corePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StuckItem {
  final int id;
  final int gapIndex;
  final double normalizedX;
  final double normalizedY;
  final String type;
  final String foodType;
  final Color color;
  final String label;
  final double depthRequired; // How deep the floss needs to go (0-1)
  double health = 1.0;
  bool isShaking = false;

  _StuckItem({
    required this.id,
    required this.gapIndex,
    required this.normalizedX,
    required this.normalizedY,
    required this.type,
    this.foodType = '',
    required this.color,
    required this.label,
    this.depthRequired = 0.5,
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

class _FlyingMicrobe {
  final double startX;
  final double startY;
  final Color color;
  final String imageType;
  final double delay;
  final double size;

  _FlyingMicrobe({
    required this.startX,
    required this.startY,
    required this.color,
    required this.imageType,
    required this.delay,
    required this.size,
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
      // Germ with angry/evil face
      final Path path = Path();
      path.addOval(Rect.fromCenter(center: center, width: w * 0.85, height: h * 0.8));
      canvas.drawPath(path, bodyPaint);

      final Paint spikePaint = Paint()..color = item.color.withValues(alpha: 0.85);
      for (int i = 0; i < 6; i++) {
        final double angle = i * (math.pi / 3);
        final double sx = center.dx + math.cos(angle) * (w * 0.42);
        final double sy = center.dy + math.sin(angle) * (h * 0.42);
        canvas.drawCircle(Offset(sx, sy), 4.5, spikePaint);
      }

      final Paint eyeWhite = Paint()..color = Colors.white;
      final Paint eyePupil = Paint()..color = Colors.black;
      canvas.drawCircle(Offset(w * 0.35, h * 0.40), 5.5, eyeWhite);
      canvas.drawCircle(Offset(w * 0.37, h * 0.40), 2.5, eyePupil);
      canvas.drawCircle(Offset(w * 0.65, h * 0.40), 5.5, eyeWhite);
      canvas.drawCircle(Offset(w * 0.63, h * 0.40), 2.5, eyePupil);

      final Paint browPaint = Paint()
        ..color = Colors.black87
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(w * 0.25, h * 0.28), Offset(w * 0.45, h * 0.34), browPaint);
      canvas.drawLine(Offset(w * 0.75, h * 0.28), Offset(w * 0.55, h * 0.34), browPaint);

      final Path mouthPath = Path();
      mouthPath.moveTo(w * 0.35, h * 0.65);
      mouthPath.quadraticBezierTo(w * 0.5, h * 0.55, w * 0.65, h * 0.65);
      canvas.drawPath(mouthPath, browPaint);
    } else {
      // Food particles — more realistic looking
      if (item.foodType == 'leaf') {
        final Path leafPath = Path();
        leafPath.moveTo(w * 0.1, h * 0.5);
        leafPath.quadraticBezierTo(w * 0.5, h * 0.05, w * 0.9, h * 0.5);
        leafPath.quadraticBezierTo(w * 0.5, h * 0.95, w * 0.1, h * 0.5);
        leafPath.close();
        canvas.drawPath(leafPath, bodyPaint);

        final Paint veinPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.6)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(w * 0.2, h * 0.5), Offset(w * 0.8, h * 0.5), veinPaint);
      } else if (item.foodType == 'cheese') {
        final Path triPath = Path();
        triPath.moveTo(w * 0.5, h * 0.1);
        triPath.lineTo(w * 0.9, h * 0.85);
        triPath.lineTo(w * 0.1, h * 0.85);
        triPath.close();
        canvas.drawPath(triPath, bodyPaint);

        final Paint holePaint = Paint()..color = Colors.orange.shade900.withValues(alpha: 0.3);
        canvas.drawCircle(Offset(w * 0.5, h * 0.55), 4, holePaint);
        canvas.drawCircle(Offset(w * 0.35, h * 0.7), 3, holePaint);
      } else if (item.foodType == 'meat') {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.15, h * 0.15, w * 0.7, h * 0.7), const Radius.circular(10)),
          bodyPaint,
        );
        final Paint detailPaint = Paint()..color = Colors.white.withValues(alpha: 0.7);
        canvas.drawCircle(Offset(w * 0.35, h * 0.35), 4, detailPaint);
      } else {
        canvas.drawOval(Rect.fromLTWH(w * 0.2, h * 0.2, w * 0.6, h * 0.6), bodyPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StuckItemPainter oldDelegate) {
    return oldDelegate.item.health != item.health || oldDelegate.item.isShaking != item.isShaking;
  }
}

class _FlossStringPainter extends CustomPainter {
  final Offset touchPos;
  final bool isDragging;
  final bool isSuccess;
  final int currentGap;
  final double flossDepth;

  _FlossStringPainter({
    required this.touchPos,
    required this.isDragging,
    required this.isSuccess,
    this.currentGap = -1,
    this.flossDepth = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (isSuccess) return;

    final double w = size.width;
    final double h = size.height;

    Offset leftAnchor = Offset(w * 0.05, touchPos.dy.clamp(h * 0.2, h * 0.8));
    Offset rightAnchor = Offset(w * 0.95, touchPos.dy.clamp(h * 0.2, h * 0.8));
    Offset centerControl = touchPos;

    if (!isDragging) {
      leftAnchor = Offset(w * 0.05, h * 0.52);
      rightAnchor = Offset(w * 0.95, h * 0.52);
      centerControl = Offset(w * 0.5, h * 0.52);
    } else {
      leftAnchor = Offset(w * 0.05, (touchPos.dy - 20).clamp(h * 0.15, h * 0.85));
      rightAnchor = Offset(w * 0.95, (touchPos.dy - 20).clamp(h * 0.15, h * 0.85));
    }

    final Paint shadowPaint = Paint()
      ..color = const Color(0xFFFFA801).withValues(alpha: 0.35)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final Path stringPath = Path();
    stringPath.moveTo(leftAnchor.dx, leftAnchor.dy);
    stringPath.quadraticBezierTo(centerControl.dx, centerControl.dy, rightAnchor.dx, rightAnchor.dy);

    canvas.drawPath(stringPath, shadowPaint);

    // Floss string color changes based on depth
    final Color stringColor = flossDepth > 0.7
        ? const Color(0xFF2ECC71) // green = deep enough
        : Colors.white;

    final Paint stringPaint = Paint()
      ..color = stringColor
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(stringPath, stringPaint);

    _drawHandle(canvas, leftAnchor);
    _drawHandle(canvas, rightAnchor);

    if (isDragging) {
      final Paint ringPaint = Paint()
        ..color = const Color(0xFFFFA801).withValues(alpha: 0.7)
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
        Rect.fromCenter(center: pos, width: 22, height: 30),
        const Radius.circular(8),
      ),
      handlePaint,
    );

    final Paint detailPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, 4.5, detailPaint);
  }

  @override
  bool shouldRepaint(covariant _FlossStringPainter oldDelegate) {
    return oldDelegate.touchPos != touchPos ||
        oldDelegate.isDragging != isDragging ||
        oldDelegate.isSuccess != isSuccess ||
        oldDelegate.currentGap != currentGap ||
        oldDelegate.flossDepth != flossDepth;
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
