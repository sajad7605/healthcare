import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/squish_pop.dart';
import '../api/healthcare_api.dart';

enum BrushingStage {
  chooseBrush,
  chooseTime,
  place45Degrees,
  frontTeethUpper,
  frontTeethLower,
  backTeethUpperInner,
  backTeethUpperOuter,
  backTeethUpperChewing,
  backTeethLower,
  brushTongue,
  continue2Minutes,
  spitOut,
  cleanMouthDone,
}

class InteractiveBrushScreen extends StatefulWidget {
  const InteractiveBrushScreen({super.key});

  @override
  State<InteractiveBrushScreen> createState() => _InteractiveBrushScreenState();
}

class _InteractiveBrushScreenState extends State<InteractiveBrushScreen>
    with TickerProviderStateMixin {
  BrushingStage _currentStage = BrushingStage.chooseBrush;
  int _selectedBrushIndex = -1;
  int _selectedTimeIndex = -1;

  Offset _brushPosition = const Offset(200, 500);
  bool _isDragging = false;
  double _brushAngle = -math.pi / 6;

  Rect _cachedBounds = Rect.zero;

  final List<Offset> _dragHistory = [];
  String _tooltipText = '';
  Timer? _tooltipTimer;

  int _circleCount = 0;
  int _strokeCount = 0;
  int _tongueSwipeCount = 0;
  int _secondsRemaining = 15;
  bool _isFastMode = true;
  Timer? _countdownTimer;
  bool _isAngleAligned = false;
  bool _isCelebrationShown = false;

  Offset? _lastStrokePoint;
  String? _lastStrokeDirection;
  int _strokeDirectionSwitches = 0;

  Offset? _tongueDragStart;
  bool _isValidTongueDrag = false;

  double _linearDistanceInCircleStage = 0.0;
  Offset? _lastCircleCheckPoint;
  double _distanceInChewingStage = 0.0;
  Offset? _lastChewingCheckPoint;

  final List<_FoamBubble> _bubbles = [];
  final List<_Sparkle> _sparkles = [];
  final List<_Confetti> _confetti = [];

  List<_Germ> _germs = [];
  double _cleanlinessProgress = 0.0;
  int _totalGerms = 5;

  late AnimationController _floatingController;
  late AnimationController _wiggleController;
  late AnimationController _celebrationController;
  Timer? _updateTimer;

  final List<String> _brushes = [
    'assets/Gemini_Generated_Image_bmoqd1bmoqd1bmoq 1.png',
    'assets/Gemini_Generated_Image_bmoqd1bmoqd1bmoq 2.png',
    'assets/Gemini_Generated_Image_bmoqd1bmoqd1bmoq 3.png',
  ];

  @override
  void initState() {
    super.initState();
    _brushes.shuffle();

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

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
    _countdownTimer?.cancel();
    _tooltipTimer?.cancel();
    super.dispose();
  }

  void _initGerms(BrushingStage stage) {
    _germs.clear();
    if (stage == BrushingStage.frontTeethUpper) {
      _germs = [
        _Germ(
          id: 1,
          position: const Offset(0.35, 0.41),
          color: Colors.lightGreenAccent.shade700,
        ),
        _Germ(
          id: 2,
          position: const Offset(0.50, 0.38),
          color: Colors.redAccent.shade400,
        ),
        _Germ(
          id: 3,
          position: const Offset(0.65, 0.41),
          color: Colors.amber.shade700,
        ),
      ];
    } else if (stage == BrushingStage.frontTeethLower) {
      _germs = [
        _Germ(
          id: 1,
          position: const Offset(0.36, 0.52),
          color: Colors.teal.shade600,
        ),
        _Germ(
          id: 2,
          position: const Offset(0.50, 0.55),
          color: Colors.orangeAccent.shade700,
        ),
        _Germ(
          id: 3,
          position: const Offset(0.64, 0.52),
          color: Colors.pinkAccent.shade400,
        ),
      ];
    } else if (stage == BrushingStage.backTeethUpperInner) {
      _germs = [
        _Germ(
          id: 1,
          position: const Offset(0.28, 0.40),
          color: Colors.deepOrange.shade600,
        ),
        _Germ(
          id: 2,
          position: const Offset(0.72, 0.40),
          color: Colors.indigo.shade500,
        ),
        _Germ(
          id: 3,
          position: const Offset(0.50, 0.42),
          color: Colors.lightGreenAccent.shade700,
        ),
      ];
    } else if (stage == BrushingStage.backTeethUpperOuter) {
      _germs = [
        _Germ(
          id: 1,
          position: const Offset(0.26, 0.36),
          color: Colors.cyan.shade700,
        ),
        _Germ(
          id: 2,
          position: const Offset(0.74, 0.36),
          color: Colors.redAccent.shade400,
        ),
        _Germ(
          id: 3,
          position: const Offset(0.50, 0.34),
          color: Colors.amber.shade600,
        ),
      ];
    } else if (stage == BrushingStage.backTeethUpperChewing) {
      _germs = [
        _Germ(
          id: 1,
          position: const Offset(0.30, 0.44),
          color: Colors.green.shade600,
        ),
        _Germ(
          id: 2,
          position: const Offset(0.42, 0.48),
          color: Colors.orange.shade700,
        ),
        _Germ(
          id: 3,
          position: const Offset(0.58, 0.48),
          color: Colors.red.shade600,
        ),
        _Germ(
          id: 4,
          position: const Offset(0.70, 0.44),
          color: Colors.pink.shade700,
        ),
      ];
    } else if (stage == BrushingStage.backTeethLower) {
      _germs = [
        _Germ(
          id: 1,
          position: const Offset(0.30, 0.52),
          color: Colors.purple.shade500,
        ),
        _Germ(
          id: 2,
          position: const Offset(0.50, 0.56),
          color: Colors.blue.shade600,
        ),
        _Germ(
          id: 3,
          position: const Offset(0.70, 0.52),
          color: Colors.teal.shade600,
        ),
      ];
    } else if (stage == BrushingStage.brushTongue) {
      _germs = [
        _Germ(
          id: 1,
          position: const Offset(0.45, 0.54),
          color: Colors.deepPurple.shade400,
        ),
        _Germ(
          id: 2,
          position: const Offset(0.50, 0.58),
          color: Colors.purple.shade600,
        ),
        _Germ(
          id: 3,
          position: const Offset(0.55, 0.52),
          color: Colors.blue.shade600,
        ),
      ];
    }
    _totalGerms = _germs.length;
    setState(() {
      _cleanlinessProgress = 0.0;
    });
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

    for (int i = 0; i < 90; i++) {
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
      for (int i = _bubbles.length - 1; i >= 0; i--) {
        final bubble = _bubbles[i];
        bubble.position += Offset(bubble.vx, bubble.vy);
        bubble.life -= 0.02;
        if (bubble.life <= 0.0) {
          _bubbles.removeAt(i);
        }
      }

      for (int i = _sparkles.length - 1; i >= 0; i--) {
        final sparkle = _sparkles[i];
        sparkle.progress += 0.03;
        sparkle.position += Offset(sparkle.vx, sparkle.vy);
        if (sparkle.progress >= 1.0) {
          _sparkles.removeAt(i);
        }
      }

      if (_currentStage == BrushingStage.cleanMouthDone) {
        for (var conf in _confetti) {
          conf.position += Offset(conf.vx, conf.vy);
          conf.rotation += conf.rotationSpeed;

          if (conf.position.dy > 900) {
            conf.position = Offset(math.Random().nextDouble() * 400 - 50, -50);
            conf.vy = math.Random().nextDouble() * 4 + 2;
          }
        }

        if (math.Random().nextDouble() < 0.1 && _sparkles.length < 15) {
          final randomX = 0.2 + math.Random().nextDouble() * 0.6;
          final randomY = 0.38 + math.Random().nextDouble() * 0.18;
          _sparkles.add(
            _Sparkle(
              position: Offset(randomX * 360, randomY * 800),
              vx: 0,
              vy: 0,
              size: math.Random().nextDouble() * 20 + 10,
              color: Colors.white,
              isStar: true,
            ),
          );
        }
      }
    });
  }

  Rect _getImageBounds(BoxConstraints constraints) {
    const double imageWidth = 393.0;
    const double imageHeight = 852.0;
    const double imageAspectRatio = imageWidth / imageHeight;
    final double screenAspectRatio =
        constraints.maxWidth / constraints.maxHeight;

    double renderWidth, renderHeight, dx, dy;

    if (screenAspectRatio > imageAspectRatio) {
      renderHeight = constraints.maxHeight;
      renderWidth = renderHeight * imageAspectRatio;
      dx = (constraints.maxWidth - renderWidth) / 2.0;
      dy = 0.0;
    } else {
      renderWidth = constraints.maxWidth;
      renderHeight = renderWidth / imageAspectRatio;
      dx = 0.0;
      dy = (constraints.maxHeight - renderHeight) / 2.0;
    }

    final rect = Rect.fromLTWH(dx, dy, renderWidth, renderHeight);
    _cachedBounds = rect;
    return rect;
  }

  void _handleBrushing(Offset localPos, BoxConstraints constraints) {
    setState(() {
      final double dx = localPos.dx - _brushPosition.dx;

      if (_currentStage != BrushingStage.place45Degrees) {
        if (dx.abs() > 1.0) {
          _brushAngle = dx > 0 ? -math.pi / 4 : -math.pi / 12;
        }
      }
      _brushPosition = localPos;
      _isDragging = true;
    });

    final Offset brushTip = Offset(localPos.dx, localPos.dy - 70);

    final random = math.Random();
    final double foamChance = _currentStage == BrushingStage.continue2Minutes
        ? 0.7
        : 0.35;
    if (random.nextDouble() < foamChance) {
      _bubbles.add(
        _FoamBubble(
          position:
              brushTip +
              Offset(
                random.nextDouble() * 30 - 15,
                random.nextDouble() * 20 - 10,
              ),
          vx: random.nextDouble() * 1.5 - 0.75,
          vy: random.nextDouble() * -1.5 - 0.5,
          radius: random.nextDouble() * 8 + 4,
        ),
      );
    }

    _validateStageGestures(localPos, constraints);
  }

  void _validateStageGestures(Offset localPos, BoxConstraints constraints) {
    _cachedBounds = _getImageBounds(constraints);

    switch (_currentStage) {
      case BrushingStage.place45Degrees:
        _checkAngleAlignment();
        break;
      case BrushingStage.frontTeethUpper:
        _checkVerticalMotion(localPos, expectDownward: true);
        _detectVerticalBrushingWarning(localPos, message: 'دندان‌های جلو بالا را از بالا به پایین بکش! ⬇️');
        break;
      case BrushingStage.frontTeethLower:
        _checkVerticalMotion(localPos, expectDownward: false);
        _detectVerticalBrushingWarning(localPos, message: 'دندان‌های جلو پایین را از پایین به بالا بکش! ⬆️');
        break;
      case BrushingStage.backTeethUpperInner:
        _checkVerticalMotion(localPos, expectDownward: true);
        _detectVerticalBrushingWarning(localPos, message: 'سطح داخلی دندان‌های عقب بالا را از بالا به پایین بکش! ⬇️');
        break;
      case BrushingStage.backTeethUpperOuter:
        _checkVerticalMotion(localPos, expectDownward: true);
        _detectVerticalBrushingWarning(localPos, message: 'سطح خارجی دندان‌های عقب بالا را از بالا به پایین بکش! ⬇️');
        break;
      case BrushingStage.backTeethUpperChewing:
        _checkBackAndForthMotion(localPos);
        _detectChewingWarning(localPos);
        break;
      case BrushingStage.backTeethLower:
        _checkVerticalMotion(localPos, expectDownward: true);
        _detectVerticalBrushingWarning(localPos, message: 'دندان‌های عقب پایین را مسواک بزن! ↕️');
        break;
      case BrushingStage.brushTongue:
        _updateTongueDrag(localPos, constraints);
        _detectTongueWarning(localPos, constraints);
        break;
      case BrushingStage.continue2Minutes:
        if (math.Random().nextDouble() < 0.2) {
          _sparkles.add(
            _Sparkle(
              position: localPos - const Offset(0, 60),
              vx: math.Random().nextDouble() * 2 - 1,
              vy: math.Random().nextDouble() * -2 - 1,
              size: math.Random().nextDouble() * 10 + 5,
              color: Colors.white,
              isStar: true,
            ),
          );
        }
        break;
      default:
        break;
    }
  }

  void _checkAngleAlignment() {
    if (_cachedBounds == Rect.zero) return;

    final Offset brushTip = Offset(_brushPosition.dx, _brushPosition.dy - 70);
    final double rx = (brushTip.dx - _cachedBounds.left) / _cachedBounds.width;
    final double ry = (brushTip.dy - _cachedBounds.top) / _cachedBounds.height;

    final bool isPositionCorrect =
        rx >= 0.30 && rx <= 0.70 && ry >= 0.35 && ry <= 0.48;

    final double angleDeg = (_brushAngle * 180 / math.pi).abs();
    final bool isAngleCorrect = (angleDeg - 45.0).abs() <= 12.0;

    if (isPositionCorrect && isAngleCorrect) {
      if (!_isAngleAligned) {
        setState(() {
          _isAngleAligned = true;
        });
        HapticFeedback.heavyImpact();
        _emitTargetSparkles();

        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted &&
              _isAngleAligned &&
              _currentStage == BrushingStage.place45Degrees) {
            _transitionToNextStage();
          }
        });
      }
    } else {
      if (_isAngleAligned) {
        setState(() {
          _isAngleAligned = false;
        });
      }
    }
  }

  void _emitTargetSparkles() {
    final random = math.Random();
    for (int i = 0; i < 20; i++) {
      _sparkles.add(
        _Sparkle(
          position:
              _brushPosition +
              Offset(
                random.nextDouble() * 60 - 30,
                random.nextDouble() * 60 - 100,
              ),
          vx: random.nextDouble() * 4 - 2,
          vy: random.nextDouble() * -4 - 2,
          size: random.nextDouble() * 15 + 8,
          color: Colors.lightGreenAccent,
          isStar: true,
        ),
      );
    }
  }

  void _checkVerticalMotion(Offset currentPos, {bool expectDownward = true}) {
    if (_lastCircleCheckPoint == null) {
      _lastCircleCheckPoint = currentPos;
      return;
    }

    final double dx = currentPos.dx - _lastCircleCheckPoint!.dx;
    final double dy = currentPos.dy - _lastCircleCheckPoint!.dy;
    final double distance = math.sqrt(dx * dx + dy * dy);

    if (distance > 10.0) {
      // Detect primarily vertical movement
      if (dy.abs() > dx.abs() * 0.8) {
        String currentDir = dy > 0 ? 'D' : 'U';
        // For downward stages, reward D->U->D switches; for upward, reward U->D->U
        String primaryDir = expectDownward ? 'D' : 'U';
        String secondaryDir = expectDownward ? 'U' : 'D';

        if (_lastStrokeDirection != null && _lastStrokeDirection != currentDir) {
          bool isVerticalSwitch =
              (_lastStrokeDirection == secondaryDir && currentDir == primaryDir) ||
              (_lastStrokeDirection == primaryDir && currentDir == secondaryDir);

          if (isVerticalSwitch && distance < 150.0) {
            _strokeDirectionSwitches++;
            HapticFeedback.lightImpact();
            _damageGermsInRadius(50.0, damage: 0.22);

            if (_strokeDirectionSwitches >= 2) {
              _strokeDirectionSwitches = 0;
              _linearDistanceInCircleStage = 0.0;
              _onVerticalStrokeDetected();
            }
          }
        }

        _lastStrokeDirection = currentDir;
      }
      _lastCircleCheckPoint = currentPos;
    }
  }

  void _onVerticalStrokeDetected() {
    _linearDistanceInCircleStage = 0.0;
    setState(() {
      _circleCount++;
    });
    HapticFeedback.lightImpact();
    _damageGermsInRadius(50.0, damage: 0.22);
  }

  void _checkBackAndForthMotion(Offset currentPos) {
    if (_lastStrokePoint == null) {
      _lastStrokePoint = currentPos;
      return;
    }

    final double dx = currentPos.dx - _lastStrokePoint!.dx;
    final double dy = currentPos.dy - _lastStrokePoint!.dy;
    final double distance = math.sqrt(dx * dx + dy * dy);

    if (distance > 10.0) {
      String currentDir = dx.abs() > dy.abs()
          ? (dx > 0 ? 'R' : 'L')
          : (dy > 0 ? 'D' : 'U');

      if (_lastStrokeDirection != null && _lastStrokeDirection != currentDir) {
        bool isOpposite =
            (_lastStrokeDirection == 'L' && currentDir == 'R') ||
            (_lastStrokeDirection == 'R' && currentDir == 'L') ||
            (_lastStrokeDirection == 'U' && currentDir == 'D') ||
            (_lastStrokeDirection == 'D' && currentDir == 'U');

        if (isOpposite && distance < 150.0) {
          _strokeDirectionSwitches++;
          HapticFeedback.lightImpact();
          _damageGermsInRadius(50.0, damage: 0.18);

          if (_strokeDirectionSwitches >= 2) {
            _strokeDirectionSwitches = 0;
            _distanceInChewingStage = 0.0;
            setState(() {
              _strokeCount++;
            });
          }
        }
      }

      _lastStrokeDirection = currentDir;
      _lastStrokePoint = currentPos;
    }
  }

  void _startTongueDrag(Offset localPos, BoxConstraints constraints) {
    if (_cachedBounds == Rect.zero) return;
    final double rx = (localPos.dx - _cachedBounds.left) / _cachedBounds.width;
    final double ry = (localPos.dy - _cachedBounds.top) / _cachedBounds.height;

    if (rx > 0.35 && rx < 0.65 && ry > 0.38 && ry < 0.55) {
      _tongueDragStart = localPos;
      _isValidTongueDrag = true;
    } else {
      _isValidTongueDrag = false;
    }
  }

  void _updateTongueDrag(Offset localPos, BoxConstraints constraints) {
    if (!_isValidTongueDrag || _tongueDragStart == null) return;

    final double dy = localPos.dy - _tongueDragStart!.dy;
    final double dx = localPos.dx - _tongueDragStart!.dx;

    if (dy > 40.0) {
      if (dy > dx.abs() * 1.2) {
        _isValidTongueDrag = false;
        _tongueDragStart = null;

        setState(() {
          _tongueSwipeCount++;
          final random = math.Random();
          for (int i = 0; i < 8; i++) {
            _sparkles.add(
              _Sparkle(
                position:
                    localPos +
                    Offset(
                      random.nextDouble() * 30 - 15,
                      random.nextDouble() * 30 - 15,
                    ),
                vx: random.nextDouble() * 2 - 1,
                vy: random.nextDouble() * -2 - 1,
                size: random.nextDouble() * 10 + 5,
                color: Colors.pinkAccent.shade100,
              ),
            );
          }
        });
        HapticFeedback.mediumImpact();
        _damageGermsInRadius(70.0, damage: 0.45);
      }
    }
  }

  void _damageGermsInRadius(double radius, {double damage = 0.05}) {
    if (_cachedBounds == Rect.zero) return;
    final Offset brushTip = Offset(_brushPosition.dx, _brushPosition.dy - 70);
    final random = math.Random();

    for (var germ in _germs) {
      if (germ.health > 0) {
        final double absoluteX =
            _cachedBounds.left + germ.position.dx * _cachedBounds.width;
        final double absoluteY =
            _cachedBounds.top + germ.position.dy * _cachedBounds.height;
        final Offset germOffset = Offset(absoluteX, absoluteY);

        final double distance = (brushTip - germOffset).distance;
        if (distance < radius + 30.0) {
          setState(() {
            germ.health -= damage;
            germ.isShaking = true;
          });

          if (random.nextDouble() < 0.4) {
            _sparkles.add(
              _Sparkle(
                position: germOffset,
                vx: random.nextDouble() * 4 - 2,
                vy: random.nextDouble() * 4 - 2,
                size: random.nextDouble() * 12 + 6,
                color: Colors.amberAccent,
              ),
            );
          }

          HapticFeedback.lightImpact();

          if (germ.health <= 0) {
            HapticFeedback.mediumImpact();
            for (int k = 0; k < 12; k++) {
              final angle = k * (2 * math.pi / 12);
              final speed = random.nextDouble() * 3 + 2;
              _sparkles.add(
                _Sparkle(
                  position: germOffset,
                  vx: math.cos(angle) * speed,
                  vy: math.sin(angle) * speed,
                  size: random.nextDouble() * 14 + 8,
                  color: germ.color,
                  isStar: true,
                ),
              );
            }
            _checkStageProgress();
          }
        } else {
          setState(() {
            germ.isShaking = false;
          });
        }
      }
    }
  }

  void _detectVerticalBrushingWarning(Offset currentPos, {String? message}) {
    if (_lastCircleCheckPoint == null) {
      _lastCircleCheckPoint = currentPos;
      return;
    }
    final double dist = (currentPos - _lastCircleCheckPoint!).distance;
    _linearDistanceInCircleStage += dist;
    _lastCircleCheckPoint = currentPos;

    if (_linearDistanceInCircleStage > 250.0) {
      _showTooltip(message ?? "مسواک را از بالا به پایین حرکت بده! ⬇️");
      _linearDistanceInCircleStage = 0.0;
    }
  }

  void _detectChewingWarning(Offset currentPos) {
    if (_lastChewingCheckPoint == null) {
      _lastChewingCheckPoint = currentPos;
      return;
    }
    final double dist = (currentPos - _lastChewingCheckPoint!).distance;
    _distanceInChewingStage += dist;
    _lastChewingCheckPoint = currentPos;

    if (_distanceInChewingStage > 250.0) {
      _showTooltip("مسواک را به جلو و عقب بکش! ↔️");
      _distanceInChewingStage = 0.0;
    }
  }

  void _detectTongueWarning(Offset currentPos, BoxConstraints constraints) {
    if (_tongueDragStart == null) return;
    final double dx = currentPos.dx - _tongueDragStart!.dx;
    final double dy = currentPos.dy - _tongueDragStart!.dy;

    if (dx.abs() > 40.0 && dy.abs() < dx.abs()) {
      _showTooltip("مسواک را فقط از عقب به سمت جلو بکش! ⬇️");
      _tongueDragStart = null;
    } else if (dy < -40.0) {
      _showTooltip("مسواک را فقط از عقب به سمت جلو بکش! ⬇️");
      _tongueDragStart = null;
    }
  }

  void _showTooltip(String message) {
    if (_tooltipText == message) return;
    setState(() {
      _tooltipText = message;
    });
    _tooltipTimer?.cancel();
    _tooltipTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _tooltipText = '';
        });
      }
    });
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    setState(() {
      _secondsRemaining = _isFastMode ? 15 : 120;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
            final random = math.Random();
            for (int i = 0; i < 3; i++) {
              _bubbles.add(
                _FoamBubble(
                  position: Offset(
                    random.nextDouble() * 360,
                    480 + random.nextDouble() * 120,
                  ),
                  vx: random.nextDouble() * 2 - 1,
                  vy: random.nextDouble() * -2 - 1,
                  radius: random.nextDouble() * 10 + 5,
                ),
              );
            }
          } else {
            _countdownTimer?.cancel();
            _currentStage = BrushingStage.spitOut;
            HapticFeedback.vibrate();
          }
        });
      }
    });
  }

  void _handleSpit() {
    HapticFeedback.heavyImpact();
    final random = math.Random();
    final center = const Offset(180, 450);
    setState(() {
      _bubbles.clear();
      _sparkles.clear();

      for (int i = 0; i < 40; i++) {
        final double angle = random.nextDouble() * 2 * math.pi;
        final double speed = random.nextDouble() * 8 + 4;
        _bubbles.add(
          _FoamBubble(
            position: center,
            vx: math.cos(angle) * speed,
            vy: math.sin(angle) * speed - 2.0,
            radius: random.nextDouble() * 14 + 6,
          ),
        );
        _sparkles.add(
          _Sparkle(
            position: center,
            vx: math.cos(angle) * speed * 1.2,
            vy: math.sin(angle) * speed * 1.2 - 2.0,
            size: random.nextDouble() * 12 + 6,
            color: Colors.blueAccent.shade100,
          ),
        );
      }

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _currentStage = BrushingStage.cleanMouthDone;
            _initCelebration();
          });

          // API Connection: Log interactive brushing activity and update stars
          final activeChild = HealthcareApi.instance.currentChild;
          if (activeChild != null) {
            HealthcareApi.instance.children.logActivity(
              activeChild.id,
              ActivityLogRequest(
                activityType: 'brushing_interactive',
                durationSeconds: _isFastMode ? 15 : 120,
                completedSteps: const [
                  'chooseBrush',
                  'place45Degrees',
                  'circularBrushing',
                  'chewingSurfaces',
                  'brushTongue',
                  'spitOut',
                  'cleanMouthDone'
                ],
              ),
            ).then((res) {
              // Update local cached stars
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

          Future.delayed(const Duration(seconds: 4), () {
            if (mounted) {
              _showCelebrationDialog();
            }
          });
        }
      });
    });
  }

  void _checkStageProgress() {
    final activeGermsCount = _germs.where((g) => g.health > 0).length;
    setState(() {
      _cleanlinessProgress = _totalGerms > 0
          ? (1.0 - (activeGermsCount / _totalGerms))
          : 1.0;
    });

    if (activeGermsCount == 0) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        _transitionToNextStage();
      });
    }
  }

  void _transitionToNextStage() {
    _bubbles.clear();
    _sparkles.clear();
    _dragHistory.clear();
    _lastStrokePoint = null;
    _lastStrokeDirection = null;
    _tongueDragStart = null;
    _lastCircleCheckPoint = null;
    _strokeDirectionSwitches = 0;
    _circleCount = 0;
    _strokeCount = 0;

    if (_currentStage == BrushingStage.place45Degrees) {
      setState(() {
        _currentStage = BrushingStage.frontTeethUpper;
        _initGerms(BrushingStage.frontTeethUpper);
        _brushPosition = const Offset(200, 500);
      });
    } else if (_currentStage == BrushingStage.frontTeethUpper) {
      setState(() {
        _currentStage = BrushingStage.frontTeethLower;
        _initGerms(BrushingStage.frontTeethLower);
        _brushPosition = const Offset(200, 500);
      });
    } else if (_currentStage == BrushingStage.frontTeethLower) {
      setState(() {
        _currentStage = BrushingStage.backTeethUpperInner;
        _initGerms(BrushingStage.backTeethUpperInner);
        _brushPosition = const Offset(200, 500);
      });
    } else if (_currentStage == BrushingStage.backTeethUpperInner) {
      setState(() {
        _currentStage = BrushingStage.backTeethUpperOuter;
        _initGerms(BrushingStage.backTeethUpperOuter);
        _brushPosition = const Offset(200, 500);
      });
    } else if (_currentStage == BrushingStage.backTeethUpperOuter) {
      setState(() {
        _currentStage = BrushingStage.backTeethUpperChewing;
        _initGerms(BrushingStage.backTeethUpperChewing);
        _brushPosition = const Offset(200, 500);
      });
    } else if (_currentStage == BrushingStage.backTeethUpperChewing) {
      setState(() {
        _currentStage = BrushingStage.backTeethLower;
        _initGerms(BrushingStage.backTeethLower);
        _brushPosition = const Offset(200, 500);
      });
    } else if (_currentStage == BrushingStage.backTeethLower) {
      setState(() {
        _currentStage = BrushingStage.brushTongue;
        _initGerms(BrushingStage.brushTongue);
        _brushPosition = const Offset(200, 500);
      });
    } else if (_currentStage == BrushingStage.brushTongue) {
      setState(() {
        _currentStage = BrushingStage.continue2Minutes;
        _startTimer();
      });
    }
  }

  void _showWrongBrushDialog(String title, String message) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, a1, a2) => const SizedBox(),
      transitionBuilder: (context, anim, secAnim, child) {
        final scale = Tween<double>(
          begin: 0.8,
          end: 1.0,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack));
        return Transform.scale(
          scale: scale.value,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              content: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF2C3E50),
                  height: 1.5,
                ),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                SquishPopButton(
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _selectedBrushIndex = -1;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'دوباره انتخاب کن',
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

  void _showCelebrationDialog() {
    if (_isCelebrationShown) return;
    _isCelebrationShown = true;
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 600),
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

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 30 + (index == 1 ? 12.0 : 0.0),
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
                    _celebrationController.stop();
                    setState(() {
                      _isCelebrationShown = false;
                      _brushes.shuffle();
                      _currentStage = BrushingStage.chooseBrush;
                      _selectedBrushIndex = -1;
                      _selectedTimeIndex = -1;
                      _bubbles.clear();
                      _sparkles.clear();
                      _confetti.clear();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
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
                    _celebrationController.stop();
                    _isCelebrationShown = false;
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
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/Gemini_Generated_Image_5zdvov5zdvov5zdv 1.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),

                Positioned.fill(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 600),
                    child: (_currentStage == BrushingStage.chooseBrush ||
                            _currentStage == BrushingStage.chooseTime)
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
                                    opacity:
                                        0.5 +
                                        0.5 *
                                            math.sin(
                                              _celebrationController.value *
                                                  math.pi *
                                                  2,
                                            ),
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

                if (_currentStage != BrushingStage.chooseBrush &&
                    _currentStage != BrushingStage.chooseTime)
                  _buildGameHeader(constraints),

                if (_currentStage == BrushingStage.chooseBrush)
                  _buildChooseBrushStage(constraints),

                if (_currentStage == BrushingStage.chooseTime)
                  _buildChooseTimeStage(constraints),

                if (_currentStage != BrushingStage.chooseBrush &&
                    _currentStage != BrushingStage.chooseTime &&
                    _currentStage != BrushingStage.cleanMouthDone)
                  _buildBrushingStage(constraints),

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

                if (_currentStage == BrushingStage.cleanMouthDone)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _ConfettiPainter(confetti: _confetti),
                      ),
                    ),
                  ),

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
                ),

                if (_currentStage == BrushingStage.chooseBrush ||
                    _currentStage == BrushingStage.chooseTime)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 10,
                    left: 20,
                    child: SquishPopButton(
                      onTap: () => Navigator.pushNamed(context, '/timer'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
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
                            Icon(
                              Icons.timer_outlined,
                              color: Color(0xFF9B59B6),
                              size: 18,
                            ),
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

  String _getStageObject() {
    switch (_currentStage) {
      case BrushingStage.chooseBrush:
      case BrushingStage.chooseTime:
        return '';
      case BrushingStage.place45Degrees:
      case BrushingStage.frontTeethUpper:
      case BrushingStage.frontTeethLower:
        return 'assets/Group 2.png';
      case BrushingStage.backTeethUpperInner:
      case BrushingStage.backTeethUpperOuter:
      case BrushingStage.backTeethUpperChewing:
      case BrushingStage.backTeethLower:
      case BrushingStage.brushTongue:
      case BrushingStage.continue2Minutes:
      case BrushingStage.spitOut:
        return 'assets/Group 2(2).png';
      case BrushingStage.cleanMouthDone:
        return 'assets/Group 3.png';
    }
  }

  Widget _buildGameHeader(BoxConstraints constraints) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 70,
      left: 20,
      right: 20,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

          if (_tooltipText.isNotEmpty) ...[
            _buildTooltip(),
            const SizedBox(height: 12),
          ],

          if (_currentStage == BrushingStage.frontTeethUpper ||
              _currentStage == BrushingStage.frontTeethLower ||
              _currentStage == BrushingStage.backTeethUpperInner ||
              _currentStage == BrushingStage.backTeethUpperOuter ||
              _currentStage == BrushingStage.backTeethUpperChewing ||
              _currentStage == BrushingStage.backTeethLower ||
              _currentStage == BrushingStage.brushTongue)
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
                        width:
                            (constraints.maxWidth - 40) * _cleanlinessProgress,
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
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 4,
                        offset: Offset(1, 1),
                      ),
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
      case BrushingStage.chooseBrush:
        return 'یک مسواک قشنگ انتخاب کن! 🪥';
      case BrushingStage.chooseTime:
        return 'زمان مناسب مسواک زدن را انتخاب کن! ⏱️';
      case BrushingStage.place45Degrees:
        return '۱. مسواک را با زاویه ۴۵ درجه روی لثه قرار بده! 📐';
      case BrushingStage.frontTeethUpper:
        return '۲. دندان‌های جلو – فک بالا را از بالا به پایین بکش! ⬇️ (حرکت: $_circleCount)';
      case BrushingStage.frontTeethLower:
        return '۳. دندان‌های جلو – فک پایین را از پایین به بالا بکش! ⬆️ (حرکت: $_circleCount)';
      case BrushingStage.backTeethUpperInner:
        return '۴. دندان‌های عقب دارای ۳ سطح هستند\nسطح داخلی فک بالا را از بالا به پایین بکش! ⬇️ (حرکت: $_circleCount)';
      case BrushingStage.backTeethUpperOuter:
        return '۵. سطح خارجی دندان‌های عقب فک بالا را از بالا به پایین بکش! ⬇️ (حرکت: $_circleCount)';
      case BrushingStage.backTeethUpperChewing:
        return '۶. سطح جویدنی دندان‌های عقب فک بالا را با حرکت جلو-عقب تمیز کن! ↔️ (حرکت: $_strokeCount)';
      case BrushingStage.backTeethLower:
        return '۷. حالا به بخش عقبی فک پایین بروید و آن را مسواک بزنید! ↕️ (حرکت: $_circleCount)';
      case BrushingStage.brushTongue:
        return '۸. زبان را به آرامی از عقب به جلو مسواک بکش! ⬇️ ($_tongueSwipeCount/۳)';
      case BrushingStage.continue2Minutes:
        return '۹. مسواک زدن را ادامه بده تا زمان تمام شود! ⏳';
      case BrushingStage.spitOut:
        return '۱۰. حالا آب و خمیردندان را تف کن! 💦';
      case BrushingStage.cleanMouthDone:
        return 'دندون‌هات از تمیزی دارن برق می‌زنن! 😍⭐';
    }
  }

  Widget _buildTooltip() {
    return AnimatedOpacity(
      opacity: _tooltipText.isNotEmpty ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      child: Container(
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

  Widget _buildRotationDial() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'مسواک را با کشیدن غلتک به چپ و راست بچرخانید:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onHorizontalDragUpdate: (details) {
              setState(() {
                _brushAngle = (_brushAngle + details.delta.dx * 0.012).clamp(
                  -math.pi / 2,
                  math.pi / 2,
                );
                _checkAngleAlignment();
              });
            },
            child: Container(
              height: 54,
              width: 280,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.shade100,
                    Colors.blue.shade50,
                    Colors.blue.shade100,
                  ],
                ),
                borderRadius: BorderRadius.circular(27),
                border: Border.all(color: Colors.blue.shade300, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 14),
                    child: Icon(
                      Icons.arrow_back_ios,
                      size: 16,
                      color: Colors.blue,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.rotate_right,
                        color: Colors.blueAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'زاویه: ${(_brushAngle * 180 / math.pi).round()}°',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B4F72),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(right: 14),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'هدف: ۴۵ درجه یا ۴۵- درجه 🎯',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerProgress() {
    final double maxSec = _isFastMode ? 15.0 : 120.0;
    final double progress = (_secondsRemaining / maxSec).clamp(0.0, 1.0);

    final String minutes = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final String seconds = (_secondsRemaining % 60).toString().padLeft(2, '0');

    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$minutes:$seconds',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'مسواک بزن!',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpitButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'وقت تف کردن خمیردندانه! 💦',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
          ),
        ),
        const SizedBox(height: 12),
        SquishPopButton(
          onTap: _handleSpit,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.5),
                  blurRadius: 15,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wash, color: Colors.white, size: 28),
                SizedBox(width: 10),
                Text(
                  'تف کردن 💦',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChooseBrushStage(BoxConstraints constraints) {
    return Positioned.fill(
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 80),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
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

            SizedBox(
              height: 320,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_brushes.length, (index) {
                  return AnimatedBuilder(
                    animation: _floatingController,
                    builder: (context, child) {
                      final offset =
                          math.sin(
                            (_floatingController.value * math.pi * 2) + index,
                          ) *
                          15.0;
                      final isSelected = _selectedBrushIndex == index;

                      return Transform.translate(
                        offset: Offset(0, offset),
                        child: SquishPopButton(
                          onTap: () {
                            setState(() {
                              _selectedBrushIndex = index;
                            });
                            HapticFeedback.mediumImpact();

                            final selectedBrushAsset = _brushes[index];

                            if (selectedBrushAsset ==
                                'assets/Gemini_Generated_Image_bmoqd1bmoqd1bmoq 2.png') {
                              Future.delayed(
                                const Duration(milliseconds: 500),
                                () {
                                  if (mounted) {
                                    setState(() {
                                      _currentStage =
                                          BrushingStage.chooseTime;
                                      _selectedTimeIndex = -1;
                                    });
                                  }
                                },
                              );
                            } else {
                              Future.delayed(const Duration(milliseconds: 300), () {
                                if (mounted) {
                                  if (selectedBrushAsset ==
                                      'assets/Gemini_Generated_Image_bmoqd1bmoqd1bmoq 1.png') {
                                    _showWrongBrushDialog(
                                      'اوه! خمیردندونش خیلی زیاده! 😅',
                                      'این مسواک خمیردندون زیادی داره و ممکنه دهانت رو اذیت کنه. یه مسواک بهتر انتخاب کن.',
                                    );
                                  } else {
                                    _showWrongBrushDialog(
                                      'اوه! خمیردندونش کمه! 😕',
                                      'این مسواک خمیردندون کافی برای از بین بردن میکروب‌ها نداره. یکی دیگه انتخاب کن.',
                                    );
                                  }
                                }
                              });
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.95)
                                  : Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF9B59B6)
                                    : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF9B59B6,
                                        ).withValues(alpha: 0.3),
                                        blurRadius: 16,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 6),
                                      ),
                                    ]
                                  : [
                                      const BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF9B59B6)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'مسواک ${index + 1}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF2C3E50),
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

  Widget _buildChooseTimeStage(BoxConstraints constraints) {
    final List<Map<String, dynamic>> timeOptions = [
      {'label': '۲ دقیقه', 'icon': Icons.timer, 'minutes': 2, 'color': const Color(0xFF2ECC71)},
      {'label': '۵ دقیقه', 'icon': Icons.timer, 'minutes': 5, 'color': const Color(0xFFE67E22)},
      {'label': '۱۰ دقیقه', 'icon': Icons.timer, 'minutes': 10, 'color': const Color(0xFFE74C3C)},
    ];

    return Positioned.fill(
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 80),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                'زمان مناسب مسواک زدن را انتخاب کن! ⏱️',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF9B59B6),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              margin: const EdgeInsets.symmetric(horizontal: 30),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'چه مدت باید دندان‌هایمان را مسواک بزنیم؟ 🤔',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2C3E50),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const Spacer(),

            SizedBox(
              height: 220,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(timeOptions.length, (index) {
                  final option = timeOptions[index];
                  final isSelected = _selectedTimeIndex == index;

                  return AnimatedBuilder(
                    animation: _floatingController,
                    builder: (context, child) {
                      final offset =
                          math.sin(
                            (_floatingController.value * math.pi * 2) + index * 1.2,
                          ) *
                          12.0;

                      return Transform.translate(
                        offset: Offset(0, offset),
                        child: SquishPopButton(
                          onTap: () {
                            setState(() {
                              _selectedTimeIndex = index;
                            });
                            HapticFeedback.mediumImpact();

                            if (option['minutes'] == 2) {
                              Future.delayed(
                                const Duration(milliseconds: 500),
                                () {
                                  if (mounted) {
                                    setState(() {
                                      _currentStage =
                                          BrushingStage.place45Degrees;
                                      _initGerms(BrushingStage.place45Degrees);
                                    });
                                  }
                                },
                              );
                            } else {
                              Future.delayed(const Duration(milliseconds: 300), () {
                                if (mounted) {
                                  if (option['minutes'] == 5) {
                                    _showWrongTimeDialog(
                                      'اوه! این زمان زیاده! ⏰',
                                      '۵ دقیقه خیلی زیاده! زمان مناسب مسواک زدن ۲ دقیقه است. دوباره انتخاب کن.',
                                    );
                                  } else {
                                    _showWrongTimeDialog(
                                      'اوه! این خیلی زیاده! 😅',
                                      '۱۰ دقیقه واقعاً زیاده و ممکنه لثه‌هات رو اذیت کنه! زمان مناسب ۲ دقیقه است.',
                                    );
                                  }
                                }
                              });
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 105,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 20,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.95)
                                  : Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isSelected
                                    ? (option['color'] as Color)
                                    : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: (option['color'] as Color)
                                            .withValues(alpha: 0.3),
                                        blurRadius: 16,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 6),
                                      ),
                                    ]
                                  : [
                                      const BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 8,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: (option['color'] as Color)
                                        .withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    option['icon'] as IconData,
                                    color: option['color'] as Color,
                                    size: 36,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? (option['color'] as Color)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    option['label'] as String,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF2C3E50),
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

  void _showWrongTimeDialog(String title, String message) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, a1, a2) => const SizedBox(),
      transitionBuilder: (context, anim, secAnim, child) {
        final scale = Tween<double>(
          begin: 0.8,
          end: 1.0,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack));
        return Transform.scale(
          scale: scale.value,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              content: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF2C3E50),
                  height: 1.5,
                ),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                SquishPopButton(
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _selectedTimeIndex = -1;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'دوباره انتخاب کن',
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

  Widget _buildBrushingStage(BoxConstraints constraints) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (details) {
          if (_currentStage == BrushingStage.brushTongue) {
            _startTongueDrag(details.localPosition, constraints);
          }
          _handleBrushing(details.localPosition, constraints);
        },
        onPanUpdate: (details) =>
            _handleBrushing(details.localPosition, constraints),
        onPanEnd: (_) {
          setState(() {
            _isDragging = false;
            _tongueDragStart = null;
            _isValidTongueDrag = false;
          });
        },
        child: Stack(
          children: [
            if (_currentStage == BrushingStage.place45Degrees) ...[
              Positioned(
                left: _cachedBounds.left + 0.28 * _cachedBounds.width,
                top: _cachedBounds.top + 0.38 * _cachedBounds.height,
                width: 0.44 * _cachedBounds.width,
                height: 0.07 * _cachedBounds.height,
                child: Container(
                  decoration: BoxDecoration(
                    color: _isAngleAligned
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.redAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _isAngleAligned
                          ? Colors.green
                          : Colors.redAccent.withValues(alpha: 0.8),
                      width: 3,
                    ),
                    boxShadow: _isAngleAligned
                        ? [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.4),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      _isAngleAligned
                          ? 'آفرین! همینجا نگه دار 🌟'
                          : 'مسواک را روی لثه‌ها تراز کن 📐',
                      style: TextStyle(
                        color: _isAngleAligned
                            ? Colors.green.shade800
                            : Colors.redAccent.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                left: _cachedBounds.left + 0.42 * _cachedBounds.width,
                top: _cachedBounds.top + 0.27 * _cachedBounds.height,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.4,
                    child: Transform.rotate(
                      angle: math.pi / 4,
                      child: Image.asset(
                        _brushes[0],
                        height: 150,
                        color: Colors.white,
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            ],

            // Animated direction arrow hints for brushing stages
            if (_currentStage == BrushingStage.frontTeethUpper ||
                _currentStage == BrushingStage.backTeethUpperInner ||
                _currentStage == BrushingStage.backTeethUpperOuter ||
                _currentStage == BrushingStage.backTeethLower)
              Positioned(
                left: _cachedBounds.left + 0.42 * _cachedBounds.width,
                top: _cachedBounds.top + 0.32 * _cachedBounds.height,
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _floatingController,
                    builder: (context, child) {
                      return Opacity(
                        opacity:
                            0.3 +
                            0.3 *
                                math.sin(
                                  _floatingController.value * math.pi * 2,
                                ),
                        child: const Icon(
                          Icons.arrow_downward,
                          size: 60,
                          color: Colors.lightBlueAccent,
                        ),
                      );
                    },
                  ),
                ),
              ),

            if (_currentStage == BrushingStage.frontTeethLower)
              Positioned(
                left: _cachedBounds.left + 0.42 * _cachedBounds.width,
                top: _cachedBounds.top + 0.48 * _cachedBounds.height,
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _floatingController,
                    builder: (context, child) {
                      return Opacity(
                        opacity:
                            0.3 +
                            0.3 *
                                math.sin(
                                  _floatingController.value * math.pi * 2,
                                ),
                        child: const Icon(
                          Icons.arrow_upward,
                          size: 60,
                          color: Colors.greenAccent,
                        ),
                      );
                    },
                  ),
                ),
              ),

            if (_currentStage == BrushingStage.backTeethUpperChewing)
              Positioned(
                left: _cachedBounds.left + 0.35 * _cachedBounds.width,
                top: _cachedBounds.top + 0.42 * _cachedBounds.height,
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _floatingController,
                    builder: (context, child) {
                      final t = _floatingController.value;
                      final direction = (t * 2).floor() % 2 == 0
                          ? Icons.arrow_forward
                          : Icons.arrow_back;
                      return Opacity(
                        opacity: 0.4 + 0.3 * math.sin(t * math.pi * 2),
                        child: Icon(
                          direction,
                          size: 60,
                          color: Colors.orangeAccent,
                        ),
                      );
                    },
                  ),
                ),
              ),

            if (_currentStage == BrushingStage.brushTongue)
              Positioned(
                left: _cachedBounds.left + 0.42 * _cachedBounds.width,
                top: _cachedBounds.top + 0.46 * _cachedBounds.height,
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _floatingController,
                    builder: (context, child) {
                      return Opacity(
                        opacity:
                            0.3 +
                            0.2 *
                                math.sin(
                                  _floatingController.value * math.pi * 2,
                                ),
                        child: const Icon(
                          Icons.arrow_downward,
                          size: 60,
                          color: Colors.pinkAccent,
                        ),
                      );
                    },
                  ),
                ),
              ),

            ..._germs.map((germ) {
              if (germ.health <= 0) return const SizedBox.shrink();

              final double x =
                  _cachedBounds.left + germ.position.dx * _cachedBounds.width;
              final double y =
                  _cachedBounds.top + germ.position.dy * _cachedBounds.height;

              return AnimatedBuilder(
                animation: _wiggleController,
                builder: (context, child) {
                  double angle = 0.0;
                  double scaleOffset = 1.0;
                  if (germ.isShaking) {
                    angle = (math.Random().nextDouble() * 0.2 - 0.1);
                    scaleOffset = 0.95;
                  } else {
                    angle =
                        math.sin(_wiggleController.value * math.pi * 2) * 0.05;
                    scaleOffset =
                        1.0 +
                        (math.sin(_wiggleController.value * math.pi * 2) *
                            0.05);
                  }

                  return Positioned(
                    left: x - 30,
                    top: y - 30,
                    child: Transform.rotate(
                      angle: angle,
                      child: Transform.scale(
                        scale: scaleOffset * germ.health,
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

            if (_selectedBrushIndex != -1 &&
                _currentStage != BrushingStage.spitOut)
              Positioned(
                left: _brushPosition.dx - 25,
                top: _brushPosition.dy - 190,
                child: IgnorePointer(
                  child: AnimatedRotation(
                    turns: _isDragging
                        ? (_brushAngle / (2 * math.pi))
                        : (_brushAngle / (2 * math.pi)),
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      transform: Matrix4.translationValues(
                        _isDragging
                            ? (math.Random().nextDouble() * 4 - 2)
                            : 0.0,
                        _isDragging
                            ? (math.Random().nextDouble() * 4 - 2)
                            : 0.0,
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

            if (_currentStage == BrushingStage.place45Degrees)
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: Center(child: _buildRotationDial()),
              ),

            if (_currentStage == BrushingStage.continue2Minutes) ...[
              Positioned(
                top: _cachedBounds.top + 0.36 * _cachedBounds.height,
                left: 0,
                right: 0,
                child: Center(child: _buildTimerProgress()),
              ),
              Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: Center(
                  child: SquishPopButton(
                    onTap: () {
                      setState(() {
                        _isFastMode = !_isFastMode;
                        _startTimer();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _isFastMode
                            ? const Color(0xFFE67E22)
                            : const Color(0xFF2980B9),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isFastMode ? Icons.bolt : Icons.timer,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isFastMode
                                ? 'تغییر به حالت واقعی (۲ دقیقه)'
                                : 'تغییر به حالت سریع (۱۵ ثانیه)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],

            if (_currentStage == BrushingStage.spitOut)
              Positioned(
                top: _cachedBounds.top + 0.40 * _cachedBounds.height,
                left: 0,
                right: 0,
                child: Center(child: _buildSpitButton()),
              ),
          ],
        ),
      ),
    );
  }
}

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

class _Germ {
  final int id;
  final Offset position;
  final Color color;
  double health = 1.0;
  bool isShaking = false;

  _Germ({required this.id, required this.position, required this.color});
}

class _ParticlesPainter extends CustomPainter {
  final List<_FoamBubble> bubbles;
  final List<_Sparkle> sparkles;

  _ParticlesPainter({required this.bubbles, required this.sparkles});

  @override
  void paint(Canvas canvas, Size size) {
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
      bubbleStroke.color = const Color(
        0xFF35B8FF,
      ).withValues(alpha: opacity * 0.4);

      canvas.drawCircle(bubble.position, bubble.radius, bubblePaint);
      canvas.drawCircle(bubble.position, bubble.radius, bubbleStroke);

      final reflectPaint = Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.9);
      canvas.drawCircle(
        bubble.position + Offset(-bubble.radius * 0.3, -bubble.radius * 0.3),
        bubble.radius * 0.2,
        reflectPaint,
      );
    }

    for (var sparkle in sparkles) {
      final opacity = (1.0 - sparkle.progress).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = sparkle.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      if (sparkle.isStar) {
        _drawStar(
          canvas,
          sparkle.position,
          sparkle.size * (1.0 - sparkle.progress),
          paint,
        );
      } else {
        canvas.drawCircle(
          sparkle.position,
          sparkle.size * (1.0 - sparkle.progress),
          paint,
        );
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
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) {
    return true;
  }
}

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

      if (conf.size.toInt() % 2 == 0) {
        canvas.drawRect(
          Rect.fromLTWH(
            -conf.size / 2,
            -conf.size / 4,
            conf.size,
            conf.size / 2,
          ),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, conf.size / 2, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return true;
  }
}

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

    final double wobble = math.sin(animationValue * math.pi * 2) * 2.5;

    final Path bodyPath = Path();
    bodyPath.moveTo(w * 0.2, h * 0.5 + wobble);
    bodyPath.cubicTo(
      w * 0.15,
      h * 0.15,
      w * 0.85,
      h * 0.15,
      w * 0.8,
      h * 0.5 + wobble,
    );
    bodyPath.cubicTo(
      w * 0.95,
      h * 0.85,
      w * 0.05,
      h * 0.85,
      w * 0.2,
      h * 0.5 + wobble,
    );
    bodyPath.close();
    canvas.drawPath(bodyPath, bodyPaint);

    final Paint darkDetailPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.72), w * 0.08, darkDetailPaint);

    final Paint eyeWhite = Paint()..color = Colors.white;
    final Paint eyePupil = Paint()..color = Colors.black;

    canvas.drawCircle(Offset(w * 0.38, h * 0.42), w * 0.11, eyeWhite);
    canvas.drawCircle(Offset(w * 0.39, h * 0.42), w * 0.05, eyePupil);

    canvas.drawCircle(Offset(w * 0.62, h * 0.42), w * 0.11, eyeWhite);
    canvas.drawCircle(Offset(w * 0.61, h * 0.42), w * 0.05, eyePupil);

    final Paint browPaint = Paint()
      ..color = const Color(0xFF2C3E50)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(w * 0.26, h * 0.30),
      Offset(w * 0.44, h * 0.36),
      browPaint,
    );
    canvas.drawLine(
      Offset(w * 0.74, h * 0.30),
      Offset(w * 0.56, h * 0.36),
      browPaint,
    );

    final Paint mouthPaint = Paint()
      ..color = const Color(0xFF2C3E50)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final Path mouthPath = Path();
    mouthPath.moveTo(w * 0.4, h * 0.64);
    mouthPath.quadraticBezierTo(w * 0.5, h * 0.56, w * 0.6, h * 0.64);
    canvas.drawPath(mouthPath, mouthPaint);

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
