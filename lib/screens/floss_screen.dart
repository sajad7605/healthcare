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

  List<_StuckItem> _items = [];
  final List<_Sparkle> _sparkles = [];
  final List<_Confetti> _confetti = [];

  double _cleanlinessProgress = 0.0;
  int _totalItems = 8;
  String _tooltipText = '';
  Timer? _tooltipTimer;

  late AnimationController _floatingController;
  late AnimationController _wiggleController;
  late AnimationController _celebrationController;
  Timer? _updateTimer;

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
      duration: const Duration(milliseconds: 450),
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
      
      _StuckItem(
        id: 1,
        gapIndex: 1,
        normalizedY: 0.38,
        type: 'food',
        foodType: 'leaf',
        color: const Color(0xFF2ECC71),
        label: 'اسفناج',
      ),
      _StuckItem(
        id: 2,
        gapIndex: 1,
        normalizedY: 0.68,
        type: 'germ',
        color: const Color(0xFF9B59B6),
        label: 'میکروب بنفش',
      ),

      _StuckItem(
        id: 3,
        gapIndex: 2,
        normalizedY: 0.35,
        type: 'food',
        foodType: 'cheese',
        color: const Color(0xFFF1C40F),
        label: 'پنیر',
      ),
      _StuckItem(
        id: 4,
        gapIndex: 2,
        normalizedY: 0.70,
        type: 'germ',
        color: const Color(0xFFE74C3C),
        label: 'میکروب قرمز',
      ),

      _StuckItem(
        id: 5,
        gapIndex: 3,
        normalizedY: 0.40,
        type: 'food',
        foodType: 'meat',
        color: const Color(0xFFE67E22),
        label: 'گوشت',
      ),
      _StuckItem(
        id: 6,
        gapIndex: 3,
        normalizedY: 0.65,
        type: 'germ',
        color: const Color(0xFF1ABC9C),
        label: 'میکروب فیروزه‌ای',
      ),

      _StuckItem(
        id: 7,
        gapIndex: 4,
        normalizedY: 0.42,
        type: 'food',
        foodType: 'seed',
        color: const Color(0xFFD35400),
        label: 'تخمه',
      ),
      _StuckItem(
        id: 8,
        gapIndex: 4,
        normalizedY: 0.72,
        type: 'germ',
        color: const Color(0xFFFD79A8),
        label: 'میکروب صورتی',
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

    for (int i = 0; i < 75; i++) {
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
        if (i >= _sparkles.length) continue;
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

        if (math.Random().nextDouble() < 0.15 && _sparkles.length < 25) {
          _sparkles.add(
            _Sparkle(
              position: Offset(
                math.Random().nextDouble() * 380,
                150 + math.Random().nextDouble() * 350,
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

  void _onPanStart(DragStartDetails details, Size boardSize) {
    if (_isSuccess) return;
    setState(() {
      _isDragging = true;
      _touchPos = details.localPosition;
    });
    _checkFlossHit(boardSize);
  }

  void _onPanUpdate(DragUpdateDetails details, Size boardSize) {
    if (_isSuccess) return;
    setState(() {
      final double dx = details.delta.dx;
      final double dy = details.delta.dy;
      final double dist = math.sqrt(dx * dx + dy * dy);

      _touchPos = details.localPosition;
      _checkFlossHit(boardSize, dragDistance: dist);
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

  void _checkFlossHit(Size boardSize, {double dragDistance = 0.0}) {
    if (boardSize.width <= 0 || boardSize.height <= 0) return;

    final double w = boardSize.width;
    final double h = boardSize.height;

    final gapXPositions = [
      w * 0.22, 
      w * 0.40, 
      w * 0.60, 
      w * 0.78, 
    ];

    bool hitAny = false;
    final random = math.Random();

    for (var item in _items) {
      if (item.health <= 0.0) continue;

      final double itemX = gapXPositions[(item.gapIndex - 1).clamp(0, 3)];
      final double itemY = h * item.normalizedY;
      final Offset itemPos = Offset(itemX, itemY);

      final double distance = (_touchPos - itemPos).distance;

      if (distance < 48.0) {
        hitAny = true;
        setState(() {
          item.isShaking = true;
          double damage = 0.045 + (dragDistance * 0.015);
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
        _initCelebration();
      });
      HapticFeedback.vibrate();
      Future.delayed(const Duration(milliseconds: 1000), () {
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
        HealthcareApi.instance.currentChild = ChildProfile(
          id: activeChild.id,
          childName: activeChild.childName,
          childAge: activeChild.childAge,
          avatarUrl: activeChild.avatarUrl,
          stars: oldStars + res.starsEarned,
          createdAt: activeChild.createdAt,
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
                  const Text(
                    'تمام میکروب‌ها و باقی‌مانده‌های غذا رو از بین دندان‌ها پاک کردی! دندون‌هات مثل مروارید می‌درخشن! 😁✨',
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

                    if (_isSuccess)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _FlossConfettiPainter(confetti: List.of(_confetti)),
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
                ? 'دندان‌ها از تمیزی دارن برق می‌زنن! 😍✨'
                : 'نخ دندان را بین فاصله‌های دندان‌ها بالا و پایین بکش! 🦷',
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
    final double boardWidth = constraints.maxWidth - 24;
    final double boardHeight = 380.0;

    return Center(
      child: Container(
        width: boardWidth,
        height: boardHeight,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF5D1224), 
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B0B17).withValues(alpha: 0.4),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: const Color(0xFFFF8A8A), width: 3),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(33),
          child: LayoutBuilder(
            builder: (context, boardConstraints) {
              final Size boardSize = Size(boardConstraints.maxWidth, boardConstraints.maxHeight);
              final double w = boardSize.width;
              final double h = boardSize.height;

              final gapXPositions = [
                w * 0.22,
                w * 0.40,
                w * 0.60,
                w * 0.78,
              ];

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (d) => _onPanStart(d, boardSize),
                onPanUpdate: (d) => _onPanUpdate(d, boardSize),
                onPanEnd: _onPanEnd,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _RealisticMouthPainter(isSuccess: _isSuccess),
                      ),
                    ),

                    ..._items.map((item) {
                      if (item.health <= 0.0) return const SizedBox.shrink();

                      final double itemX = gapXPositions[(item.gapIndex - 1).clamp(0, 3)];
                      final double itemY = h * item.normalizedY;

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
                              scale: 0.65 + (0.35 * item.health),
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

                    if (!_isDragging && !_isSuccess && _cleanlinessProgress == 0.0)
                      Positioned(
                        left: gapXPositions[0] - 25,
                        top: h * 0.48,
                        child: AnimatedBuilder(
                          animation: _floatingController,
                          builder: (context, child) {
                            final offset = math.sin(_floatingController.value * math.pi * 2) * 16.0;
                            return Transform.translate(
                              offset: Offset(0, offset),
                              child: Container(
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
                                  size: 28,
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

class _RealisticMouthPainter extends CustomPainter {
  final bool isSuccess;

  _RealisticMouthPainter({required this.isSuccess});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Paint bgPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0, 0),
        radius: 0.85,
        colors: [
          Color(0xFF4A0E1C),
          Color(0xFF2E0811),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    final Path tonguePath = Path();
    tonguePath.moveTo(w * 0.1, h * 0.82);
    tonguePath.quadraticBezierTo(w * 0.5, h * 0.65, w * 0.9, h * 0.82);
    tonguePath.quadraticBezierTo(w * 0.5, h * 1.05, w * 0.1, h * 0.82);
    tonguePath.close();

    final Paint tonguePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFF7675),
          Color(0xFFD63031),
        ],
      ).createShader(Rect.fromLTWH(0, h * 0.65, w, h * 0.35));
    canvas.drawPath(tonguePath, tonguePaint);

    final Paint tongueLinePaint = Paint()
      ..color = const Color(0xFFB22222).withValues(alpha: 0.4)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w * 0.5, h * 0.72), Offset(w * 0.5, h * 0.88), tongueLinePaint);

    final Path upperGums = Path();
    upperGums.moveTo(0, 0);
    upperGums.lineTo(w, 0);
    upperGums.lineTo(w, h * 0.22);
    upperGums.quadraticBezierTo(w * 0.5, h * 0.36, 0, h * 0.22);
    upperGums.close();

    final Paint upperGumsPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFF7675),
          Color(0xFFFF8A8A),
          Color(0xFFFFB5C5),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.36));
    canvas.drawPath(upperGums, upperGumsPaint);

    final Paint gumsShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawPath(upperGums, gumsShadow);

    final double toothHeight = h * 0.52;

    final toothPositions = [
      w * 0.13, 
      w * 0.31, 
      w * 0.50, 
      w * 0.69, 
      w * 0.87, 
    ];

    final toothWidths = [
      w * 0.15,
      w * 0.17,
      w * 0.18,
      w * 0.17,
      w * 0.15,
    ];

    for (int i = 0; i < 5; i++) {
      _drawRealisticTooth(
        canvas,
        Offset(toothPositions[i], h * 0.16),
        Size(toothWidths[i], toothHeight),
        isMolar: i == 0 || i == 4,
        isCenter: i == 2,
      );
    }

    if (isSuccess) {
      final Paint starPaint = Paint()..color = Colors.white;
      for (int i = 0; i < 5; i++) {
        _drawShineStar(canvas, Offset(toothPositions[i], h * 0.32), 12, starPaint);
      }
    }
  }

  void _drawRealisticTooth(Canvas canvas, Offset center, Size size, {bool isMolar = false, bool isCenter = false}) {
    final double w = size.width;
    final double h = size.height;
    final Rect toothRect = Rect.fromCenter(center: center, width: w, height: h);

    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(toothRect.shift(const Offset(0, 4)), const Radius.circular(16)),
      shadowPaint,
    );

    final Path toothPath = Path();
    toothPath.moveTo(center.dx - w * 0.45, center.dy - h * 0.42);

    toothPath.quadraticBezierTo(
      center.dx, center.dy - h * 0.48,
      center.dx + w * 0.45, center.dy - h * 0.42,
    );

    toothPath.quadraticBezierTo(
      center.dx + w * 0.52, center.dy,
      center.dx + w * 0.42, center.dy + h * 0.45,
    );

    if (isMolar) {
      toothPath.cubicTo(
        center.dx + w * 0.2, center.dy + h * 0.52,
        center.dx - w * 0.2, center.dy + h * 0.52,
        center.dx - w * 0.42, center.dy + h * 0.45,
      );
    } else {
      toothPath.quadraticBezierTo(
        center.dx, center.dy + h * 0.49,
        center.dx - w * 0.42, center.dy + h * 0.45,
      );
    }

    toothPath.quadraticBezierTo(
      center.dx - w * 0.52, center.dy,
      center.dx - w * 0.45, center.dy - h * 0.42,
    );

    toothPath.close();

    final Paint enamelPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white,
          Color(0xFFFAFDFF),
          Color(0xFFE3F2FD),
          Color(0xFFBBDEFB),
        ],
        stops: [0.0, 0.4, 0.85, 1.0],
      ).createShader(toothRect);

    canvas.drawPath(toothPath, enamelPaint);

    final Paint glossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - w * 0.18, center.dy - h * 0.15),
        width: w * 0.28,
        height: h * 0.35,
      ),
      glossPaint,
    );

    final Paint borderPaint = Paint()
      ..color = const Color(0xFF90CAF9).withValues(alpha: 0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawPath(toothPath, borderPaint);

    final Paint eyePaint = Paint()..color = const Color(0xFF2C3E50);
    final double eyeY = center.dy - h * 0.05;
    canvas.drawCircle(Offset(center.dx - w * 0.2, eyeY), 3.0, eyePaint);
    canvas.drawCircle(Offset(center.dx + w * 0.2, eyeY), 3.0, eyePaint);

    final Path smilePath = Path();
    smilePath.moveTo(center.dx - w * 0.18, center.dy + h * 0.12);
    smilePath.quadraticBezierTo(center.dx, center.dy + h * 0.25, center.dx + w * 0.18, center.dy + h * 0.12);
    
    final Paint smilePaint = Paint()
      ..color = const Color(0xFF2C3E50)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(smilePath, smilePaint);

    final Paint blushPaint = Paint()
      ..color = const Color(0xFFFF8A8A).withValues(alpha: 0.5);
    canvas.drawCircle(Offset(center.dx - w * 0.32, center.dy + h * 0.08), 3.5, blushPaint);
    canvas.drawCircle(Offset(center.dx + w * 0.32, center.dy + h * 0.08), 3.5, blushPaint);
  }

  void _drawShineStar(Canvas canvas, Offset center, double size, Paint paint) {
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
  bool shouldRepaint(covariant _RealisticMouthPainter oldDelegate) {
    return oldDelegate.isSuccess != isSuccess;
  }
}

class _StuckItem {
  final int id;
  final int gapIndex;
  final double normalizedY;
  final String type; 
  final String foodType; 
  final Color color;
  final String label;
  double health = 1.0;
  bool isShaking = false;

  _StuckItem({
    required this.id,
    required this.gapIndex,
    required this.normalizedY,
    required this.type,
    this.foodType = '',
    required this.color,
    required this.label,
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

    final Paint stringPaint = Paint()
      ..color = Colors.white
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
