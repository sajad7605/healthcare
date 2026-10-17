import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/squish_pop.dart';
import '../widgets/mouth_3d_widget.dart';
import '../api/healthcare_api.dart';

enum BrushingStage {
  chooseBrush,
  chooseTime,
  mouthOverview, // 1. Overall dirty mouth full of grime, food particles, and germs!
  // Upper Front Teeth
  upperFrontOuter, // 2. Upper front outward (top to bottom)
  upperFrontInner, // 3. Behind upper front teeth (top to bottom)
  upperFrontChewing, // 4. Chewing / incisal edge of upper front (parallel)
  // Upper Left Teeth (3D rotate to left + zoom)
  upperLeftOuter, // 5. Upper left outward (top to bottom)
  upperLeftInner, // 6. Upper left inner/palatal (top to bottom)
  upperLeftChewing, // 7. Upper left molars chewing (vertical & parallel)
  // Upper Right Teeth (3D rotate to right + zoom)
  upperRightOuter, // 8. Upper right outward (top to bottom)
  upperRightInner, // 9. Upper right inner/palatal (top to bottom)
  upperRightChewing, // 10. Upper right molars chewing (vertical & parallel)
  // Lower Front Teeth
  lowerFrontOuter, // 11. Lower front outward (bottom to top)
  lowerFrontInner, // 12. Behind lower front teeth (bottom to top)
  lowerFrontChewing, // 13. Chewing / incisal edge of lower front (parallel)
  // Lower Left Teeth (3D rotate to left + zoom)
  lowerLeftOuter, // 14. Lower left outward (bottom to top)
  lowerLeftInner, // 15. Lower left inner/lingual (bottom to top)
  lowerLeftChewing, // 16. Lower left molars chewing (vertical & parallel)
  // Lower Right Teeth (3D rotate to right + zoom)
  lowerRightOuter, // 17. Lower right outward (bottom to top)
  lowerRightInner, // 18. Lower right inner/lingual (bottom to top)
  lowerRightChewing, // 19. Lower right molars chewing (vertical & parallel)
  // Post-brushing
  brushTongue, // 20. Tongue cleaning
  continue2Minutes, // Optional extra timer stage
  gargleMouth, // 21. Water gargling
  spitOut, // 22. Natural spit
  cleanMouthDone, // 23. Sparkling clean mouth celebration!
}

enum BrushingDirectionRequirement {
  downward,        // Upper teeth: strictly from gums down towards tooth edge
  upward,          // Lower teeth: strictly from gums up towards tooth edge
  horizontal,      // Front incisal edges: horizontal back and forth
  verticalChewing, // Side molars biting surfaces: back and forth along tooth line
  free,            // Any motion allowed (overview, 2-minute timer)
  none,            // Non-brushing stages
}

class _CameraTarget {
  final double zoom;
  final Offset target; // Normalized (0..1) relative to mouth bounds
  final double rotY; // 3D yaw in radians
  final double rotX; // 3D pitch in radians

  const _CameraTarget({
    required this.zoom,
    required this.target,
    required this.rotY,
    required this.rotX,
  });
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
  final bool _is3DModelMode = true;

  Offset _brushPosition = const Offset(200, 500);
  bool _isDragging = false;
  bool _isSpitHandled = false;

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
  bool _isCelebrationShown = false;

  bool _isStageTransitioning = false;
  double _currentStrokeDistance = 0.0;
  Offset? _previousBrushPositionLocal;
  Offset? _lastScreenBrushPos;
  final List<Offset> _recentBrushPositions = [];
  double _wrongMotionAccumulator = 0.0;

  final List<_FoamBubble> _bubbles = [];
  final List<_FoamBubble> _surfaceFoam = [];
  final List<_Sparkle> _sparkles = [];
  final List<_Confetti> _confetti = [];
  int _lastFoamHapticTime = 0;

  // 3D Camera State & Animation
  late AnimationController _cameraController;
  Animation<double>? _zoomAnim;
  Animation<Offset>? _targetAnim;
  Animation<double>? _rotYAnim;
  Animation<double>? _rotXAnim;

  double _camZoom = 1.0;
  Offset _camTarget = const Offset(0.5, 0.5);
  double _camRotY = 0.0;
  double _camRotX = 0.0;

  // Interactive 3D micro-tilt responsiveness under finger drag
  double _dragTiltY = 0.0;
  double _dragTiltX = 0.0;

  // Kid Gargle & Spit state (natural animated scene with boy, puffing cheeks, sink & foam fluid stream)
  double _gargleProgress = 0.0;
  bool _isGarglingHolding = false;
  Timer? _gargleTimer;
  late AnimationController _cheekPuffController;
  late AnimationController _gargleBubbleController;
  late AnimationController _waveController;
  late AnimationController _spitController;
  final List<_SplashDroplet> _spitDroplets = [];
  bool _isSpittingAnimationRunning = false;
  bool _isActivityLogged = false;

  // Items to clean in the current stage
  List<_Germ> _germs = [];
  List<_FoodItem> _foods = [];
  List<_DirtSpot> _dirtSpots = [];

  double _cleanlinessProgress = 0.0;
  int _totalStageItems = 1;

  late AnimationController _floatingController;
  late AnimationController _wiggleController;
  late AnimationController _celebrationController;
  Timer? _updateTimer;

  final List<String> _brushes = [
    'assets/Gemini_Generated_Image_bmoqd1bmoqd1bmoq 1.png',
    'assets/Gemini_Generated_Image_bmoqd1bmoqd1bmoq 2.png',
    'assets/Gemini_Generated_Image_x50vatx50vatx50v 1.png',
  ];

  @override
  void initState() {
    super.initState();
    _brushes.shuffle();

    _cameraController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _cameraController.addListener(() {
      if (mounted) {
        setState(() {
          _camZoom = _zoomAnim?.value ?? _camZoom;
          _camTarget = _targetAnim?.value ?? _camTarget;
          _camRotY = _rotYAnim?.value ?? _camRotY;
          _camRotX = _rotXAnim?.value ?? _camRotX;
        });
      }
    });

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

    _cheekPuffController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _gargleBubbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _spitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _spitController.addListener(() {
      if (_spitController.value > 0.25) {
        _updateSpitDroplets();
      }
    });

    _spitController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isSpittingAnimationRunning = false;
        });
        _logActivityAndShowCelebration();
      }
    });

    _updateTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (mounted) {
        _updateGameLoop();
      }
    });
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _floatingController.dispose();
    _wiggleController.dispose();
    _celebrationController.dispose();
    _cheekPuffController.dispose();
    _gargleBubbleController.dispose();
    _waveController.dispose();
    _spitController.dispose();
    _updateTimer?.cancel();
    _countdownTimer?.cancel();
    _tooltipTimer?.cancel();
    _gargleTimer?.cancel();
    super.dispose();
  }

  Offset _pixelPos(double px, double py) => Offset(px / 1572.0, py / 3408.0);

  bool get _isInnerStage {
    return _currentStage == BrushingStage.upperFrontInner ||
        _currentStage == BrushingStage.upperLeftInner ||
        _currentStage == BrushingStage.upperRightInner ||
        _currentStage == BrushingStage.lowerFrontInner ||
        _currentStage == BrushingStage.lowerLeftInner ||
        _currentStage == BrushingStage.lowerRightInner ||
        _currentStage == BrushingStage.brushTongue ||
        _currentStage == BrushingStage.continue2Minutes ||
        _currentStage == BrushingStage.gargleMouth ||
        _currentStage == BrushingStage.spitOut;
  }

  bool get _shouldShow3DModel =>
      _is3DModelMode &&
      !_isInnerStage &&
      _currentStage != BrushingStage.cleanMouthDone;

  Offset _getItemRenderPosition(Offset baseNormPos) {
    return Offset(
      _cachedBounds.left + baseNormPos.dx * _cachedBounds.width,
      _cachedBounds.top + baseNormPos.dy * _cachedBounds.height,
    );
  }

  _CameraTarget _getCameraTargetForStage(BrushingStage stage) {
    switch (stage) {
      case BrushingStage.chooseBrush:
      case BrushingStage.chooseTime:
      case BrushingStage.mouthOverview:
        return const _CameraTarget(
          zoom: 1.0,
          target: Offset(0.50, 0.50),
          rotY: 0.0,
          rotX: 0.0,
        );

      // Upper Front (Outer & Chewing with subtle 3D angle; Inner is completely stationary back-of-teeth)
      case BrushingStage.upperFrontOuter:
        return const _CameraTarget(
          zoom: 1.35,
          target: Offset(0.50, 0.355),
          rotY: 0.0,
          rotX: 0.08,
        );
      case BrushingStage.upperFrontInner:
        return const _CameraTarget(
          zoom: 1.0,
          target: Offset(0.50, 0.50),
          rotY: 0.0,
          rotX: 0.0, // Back of teeth image stays still
        );
      case BrushingStage.upperFrontChewing:
        return const _CameraTarget(
          zoom: 1.38,
          target: Offset(0.50, 0.300),
          rotY: 0.0,
          rotX: 0.20,
        );

      // Upper Left
      case BrushingStage.upperLeftOuter:
        return const _CameraTarget(
          zoom: 1.35,
          target: Offset(0.22, 0.340),
          rotY: -0.45, // Negative yaw turns left side outer surface forward toward user
          rotX: 0.08,
        );
      case BrushingStage.upperLeftInner:
        return const _CameraTarget(
          zoom: 1.0,
          target: Offset(0.50, 0.50),
          rotY: 0.0,
          rotX: 0.0, // Back of teeth image stays still
        );
      case BrushingStage.upperLeftChewing:
        return const _CameraTarget(
          zoom: 1.40,
          target: Offset(0.20, 0.370),
          rotY: -0.35, // Negative yaw turns left chewing surface toward user
          rotX: 0.40,
        );

      // Upper Right
      case BrushingStage.upperRightOuter:
        return const _CameraTarget(
          zoom: 1.35,
          target: Offset(0.78, 0.340),
          rotY: 0.45, // Positive yaw turns right side outer surface forward toward user
          rotX: 0.08,
        );
      case BrushingStage.upperRightInner:
        return const _CameraTarget(
          zoom: 1.0,
          target: Offset(0.50, 0.50),
          rotY: 0.0,
          rotX: 0.0, // Back of teeth image stays still
        );
      case BrushingStage.upperRightChewing:
        return const _CameraTarget(
          zoom: 1.40,
          target: Offset(0.80, 0.370),
          rotY: 0.35, // Positive yaw turns right chewing surface toward user
          rotX: 0.40,
        );

      // Lower Front
      case BrushingStage.lowerFrontOuter:
        return const _CameraTarget(
          zoom: 1.35,
          target: Offset(0.50, 0.675),
          rotY: 0.0,
          rotX: -0.08,
        );
      case BrushingStage.lowerFrontInner:
        return const _CameraTarget(
          zoom: 1.0,
          target: Offset(0.50, 0.50),
          rotY: 0.0,
          rotX: 0.0, // Back of teeth image stays still
        );
      case BrushingStage.lowerFrontChewing:
        return const _CameraTarget(
          zoom: 1.38,
          target: Offset(0.50, 0.665),
          rotY: 0.0,
          rotX: -0.20,
        );

      // Lower Left
      case BrushingStage.lowerLeftOuter:
        return const _CameraTarget(
          zoom: 1.35,
          target: Offset(0.20, 0.635),
          rotY: -0.45, // Negative yaw turns left side outer surface forward toward user
          rotX: -0.08,
        );
      case BrushingStage.lowerLeftInner:
        return const _CameraTarget(
          zoom: 1.0,
          target: Offset(0.50, 0.50),
          rotY: 0.0,
          rotX: 0.0, // Back of teeth image stays still
        );
      case BrushingStage.lowerLeftChewing:
        return const _CameraTarget(
          zoom: 1.40,
          target: Offset(0.12, 0.610),
          rotY: -0.35, // Negative yaw turns left chewing surface toward user
          rotX: -0.40,
        );

      // Lower Right
      case BrushingStage.lowerRightOuter:
        return const _CameraTarget(
          zoom: 1.35,
          target: Offset(0.80, 0.635),
          rotY: 0.45, // Positive yaw turns right side outer surface forward toward user
          rotX: -0.08,
        );
      case BrushingStage.lowerRightInner:
        return const _CameraTarget(
          zoom: 1.0,
          target: Offset(0.50, 0.50),
          rotY: 0.0,
          rotX: 0.0, // Back of teeth image stays still
        );
      case BrushingStage.lowerRightChewing:
        return const _CameraTarget(
          zoom: 1.40,
          target: Offset(0.88, 0.610),
          rotY: 0.35, // Positive yaw turns right chewing surface toward user
          rotX: -0.40,
        );

      // Tongue
      case BrushingStage.brushTongue:
        return const _CameraTarget(
          zoom: 1.0,
          target: Offset(0.50, 0.50),
          rotY: 0.0,
          rotX: 0.0, // Back of teeth image stays still
        );

      case BrushingStage.continue2Minutes:
      case BrushingStage.gargleMouth:
      case BrushingStage.spitOut:
      case BrushingStage.cleanMouthDone:
        return const _CameraTarget(
          zoom: 1.0,
          target: Offset(0.5, 0.5),
          rotY: 0.0,
          rotX: 0.0,
        );
    }
  }

  void _animateCameraTo(BrushingStage stage) {
    final target = _getCameraTargetForStage(stage);
    final bool isTargetInner = stage == BrushingStage.upperFrontInner ||
        stage == BrushingStage.upperLeftInner ||
        stage == BrushingStage.upperRightInner ||
        stage == BrushingStage.lowerFrontInner ||
        stage == BrushingStage.lowerLeftInner ||
        stage == BrushingStage.lowerRightInner ||
        stage == BrushingStage.brushTongue ||
        stage == BrushingStage.continue2Minutes ||
        stage == BrushingStage.gargleMouth ||
        stage == BrushingStage.spitOut;

    if (isTargetInner || stage == BrushingStage.cleanMouthDone || stage == BrushingStage.mouthOverview) {
      _camRotY = 0.0;
      _camRotX = 0.0;
      _dragTiltY = 0.0;
      _dragTiltX = 0.0;
    }

    _zoomAnim = Tween<double>(begin: _camZoom, end: target.zoom).animate(
      CurvedAnimation(parent: _cameraController, curve: Curves.easeInOutCubic),
    );
    _targetAnim = Tween<Offset>(begin: _camTarget, end: target.target).animate(
      CurvedAnimation(parent: _cameraController, curve: Curves.easeInOutCubic),
    );
    _rotYAnim = Tween<double>(begin: isTargetInner ? 0.0 : _camRotY, end: target.rotY).animate(
      CurvedAnimation(parent: _cameraController, curve: Curves.easeInOutCubic),
    );
    _rotXAnim = Tween<double>(begin: isTargetInner ? 0.0 : _camRotX, end: target.rotX).animate(
      CurvedAnimation(parent: _cameraController, curve: Curves.easeInOutCubic),
    );
    _cameraController.forward(from: 0.0);
  }

  double _getBrushRotationForStage(BrushingStage stage) {
    switch (stage) {
      // Chewing surfaces on sides (Left and Right molars):
      // Toothbrush MUST BE VERTICAL & PARALLEL to the chewing surfaces of teeth!
      case BrushingStage.upperLeftChewing:
      case BrushingStage.lowerLeftChewing:
        return -math.pi / 2; // -90 deg: Vertical, bristles parallel along left molars
      case BrushingStage.upperRightChewing:
      case BrushingStage.lowerRightChewing:
        return math.pi / 2; // 90 deg: Vertical, bristles parallel along right molars

      // Incisal chewing edges of front teeth:
      // Parallel to the horizontal biting edge!
      case BrushingStage.upperFrontChewing:
      case BrushingStage.lowerFrontChewing:
        return 0.0; // Horizontal along the front edge

      // Tongue:
      case BrushingStage.brushTongue:
        return -math.pi / 4;

      // Outer and inner surfaces:
      // Natural ergonomic tilt
      default:
        return -0.28;
    }
  }

  void _initStageItems(BrushingStage stage) {
    _germs.clear();
    _foods.clear();
    _dirtSpots.clear();

    if (stage == BrushingStage.mouthOverview) {
      // 0. Overview – front view (yaw=0°, pitch=0°). Germs placed on upper and lower dental arches.
      _germs = [
        _Germ(id: 1, position: const Offset(0.46, 0.355), color: Colors.redAccent.shade400),
        _Germ(id: 2, position: const Offset(0.54, 0.355), color: Colors.amber.shade700),
        _Germ(id: 3, position: const Offset(0.24, 0.400), color: Colors.purple.shade500),
        _Germ(id: 4, position: const Offset(0.76, 0.400), color: Colors.teal.shade600),
        _Germ(id: 5, position: const Offset(0.47, 0.640), color: Colors.indigo.shade500),
        _Germ(id: 6, position: const Offset(0.53, 0.640), color: Colors.lightGreenAccent.shade700),
        _Germ(id: 7, position: const Offset(0.24, 0.620), color: Colors.pink.shade700),
        _Germ(id: 8, position: const Offset(0.76, 0.620), color: Colors.cyan.shade700),
        _Germ(id: 9, position: const Offset(0.50, 0.350), color: Colors.deepPurple.shade400),
      ];
      _foods = [
        _FoodItem(id: 1, position: const Offset(0.50, 0.365), foodType: 'leaf', color: const Color(0xFF2ECC71), size: 36),
        _FoodItem(id: 2, position: const Offset(0.24, 0.400), foodType: 'cheese', color: const Color(0xFFF39C12), size: 34),
        _FoodItem(id: 3, position: const Offset(0.76, 0.400), foodType: 'meat', color: const Color(0xFFC0392B), size: 34),
        _FoodItem(id: 4, position: const Offset(0.50, 0.640), foodType: 'leaf', color: const Color(0xFF27AE60), size: 34),
        _FoodItem(id: 5, position: const Offset(0.24, 0.620), foodType: 'crumb', color: const Color(0xFFD35400), size: 32),
        _FoodItem(id: 6, position: const Offset(0.76, 0.620), foodType: 'candy', color: const Color(0xFF8E44AD), size: 32),
      ];
      _dirtSpots = [
        _DirtSpot(id: 1, position: const Offset(0.43, 0.355), radius: 24, color: const Color(0xFFD4AC0D)),
        _DirtSpot(id: 2, position: const Offset(0.57, 0.355), radius: 24, color: const Color(0xFFB7950B)),
        _DirtSpot(id: 3, position: const Offset(0.28, 0.395), radius: 26, color: const Color(0xFFCA6F1E)),
        _DirtSpot(id: 4, position: const Offset(0.72, 0.395), radius: 26, color: const Color(0xFFBA4A00)),
        _DirtSpot(id: 5, position: const Offset(0.43, 0.645), radius: 24, color: const Color(0xFFD4AC0D)),
        _DirtSpot(id: 6, position: const Offset(0.57, 0.645), radius: 24, color: const Color(0xFFB7950B)),
      ];
    } else if (stage == BrushingStage.upperFrontOuter) {
      // 1. Upper front outward (yaw=0°, pitch≈+4.6°)
      // Upper central incisors visible at enamel: x=0.45–0.55, y=0.34–0.37
      _germs = [
        _Germ(id: 1, position: const Offset(0.46, 0.355), color: Colors.lightGreenAccent.shade700),
        _Germ(id: 2, position: const Offset(0.50, 0.350), color: Colors.redAccent.shade400),
        _Germ(id: 3, position: const Offset(0.54, 0.355), color: Colors.amber.shade700),
      ];
      _foods = [
        _FoodItem(id: 1, position: const Offset(0.50, 0.365), foodType: 'leaf', color: const Color(0xFF2ECC71), size: 36),
      ];
      _dirtSpots = [
        _DirtSpot(id: 1, position: const Offset(0.43, 0.355), radius: 22, color: const Color(0xFFD4AC0D)),
        _DirtSpot(id: 2, position: const Offset(0.57, 0.355), radius: 22, color: const Color(0xFFB7950B)),
      ];
    } else if (stage == BrushingStage.upperFrontInner) {
      // 2. Behind upper front teeth (top to bottom) - clean_mouth_inner lingual enamel (Y = 1410-1435)
      _germs = [
        _Germ(id: 1, position: _pixelPos(740, 1420), color: Colors.orange.shade700),
        _Germ(id: 2, position: _pixelPos(830, 1420), color: Colors.purple.shade600),
      ];
      _foods = [
        _FoodItem(id: 1, position: _pixelPos(786, 1435), foodType: 'crumb', color: const Color(0xFFD35400), size: 32),
      ];
      _dirtSpots = [
        _DirtSpot(id: 1, position: _pixelPos(660, 1410), radius: 20, color: const Color(0xFFD4AC0D)),
        _DirtSpot(id: 2, position: _pixelPos(910, 1410), radius: 20, color: const Color(0xFFB7950B)),
      ];
    } else if (stage == BrushingStage.upperFrontChewing) {
      // 3. Chewing / incisal biting edge of upper front (yaw=0°, pitch≈+11.5°)
      _germs = [
        _Germ(id: 1, position: const Offset(0.46, 0.300), color: Colors.teal.shade600),
        _Germ(id: 2, position: const Offset(0.54, 0.300), color: Colors.deepOrange.shade600),
      ];
      _foods = [
        _FoodItem(id: 1, position: const Offset(0.50, 0.305), foodType: 'meat', color: const Color(0xFFC0392B), size: 32),
      ];
    } else if (stage == BrushingStage.upperLeftOuter) {
      // 4. Upper left outward (yaw≈-25.8°, pitch≈+4.6°)
      // Upper left side teeth crowns face forward into view (x=0.16–0.32, y=0.31–0.36)
      _germs = [
        _Germ(id: 1, position: const Offset(0.26, 0.330), color: Colors.pinkAccent.shade400),
        _Germ(id: 2, position: const Offset(0.18, 0.350), color: Colors.purple.shade500),
      ];
      _foods = [
        _FoodItem(id: 1, position: const Offset(0.22, 0.340), foodType: 'candy', color: const Color(0xFF8E44AD), size: 34),
      ];
      _dirtSpots = [
        _DirtSpot(id: 1, position: const Offset(0.25, 0.330), radius: 24, color: const Color(0xFFD4AC0D)),
        _DirtSpot(id: 2, position: const Offset(0.16, 0.355), radius: 24, color: const Color(0xFFCA6F1E)),
      ];
    } else if (stage == BrushingStage.upperLeftInner) {
      // 5. Upper left inner (top to bottom) - Screen Left premolars/molars lingual enamel
      _germs = [
        _Germ(id: 1, position: _pixelPos(400, 1410), color: Colors.deepPurple.shade400),
        _Germ(id: 2, position: _pixelPos(500, 1415), color: Colors.red.shade600),
      ];
      _foods = [
        _FoodItem(id: 1, position: _pixelPos(450, 1425), foodType: 'leaf', color: const Color(0xFF2ECC71), size: 32),
      ];
      _dirtSpots = [
        _DirtSpot(id: 1, position: _pixelPos(350, 1400), radius: 22, color: const Color(0xFFD4AC0D)),
      ];
    } else if (stage == BrushingStage.upperLeftChewing) {
      // 6. Upper left molars chewing (yaw≈-20°, pitch≈+23°)
      _germs = [
        _Germ(id: 1, position: const Offset(0.23, 0.360), color: Colors.amber.shade700),
        _Germ(id: 2, position: const Offset(0.17, 0.385), color: Colors.teal.shade600),
      ];
      _foods = [
        _FoodItem(id: 1, position: const Offset(0.20, 0.375), foodType: 'cheese', color: const Color(0xFFF39C12), size: 34),
      ];
      _dirtSpots = [
        _DirtSpot(id: 1, position: const Offset(0.25, 0.355), radius: 22, color: const Color(0xFFCA6F1E)),
      ];
    } else if (stage == BrushingStage.upperRightOuter) {
      // 7. Upper right outward (yaw≈+25.8°, pitch≈+4.6°)
      // Upper right side teeth crowns face forward into view (x=0.68–0.84, y=0.31–0.36)
      _germs = [
        _Germ(id: 1, position: const Offset(0.74, 0.330), color: Colors.orangeAccent.shade700),
        _Germ(id: 2, position: const Offset(0.82, 0.350), color: Colors.teal.shade600),
      ];
      _foods = [
        _FoodItem(id: 1, position: const Offset(0.78, 0.340), foodType: 'meat', color: const Color(0xFFC0392B), size: 34),
      ];
      _dirtSpots = [
        _DirtSpot(id: 1, position: const Offset(0.75, 0.330), radius: 24, color: const Color(0xFFD4AC0D)),
        _DirtSpot(id: 2, position: const Offset(0.84, 0.355), radius: 24, color: const Color(0xFFBA4A00)),
      ];
    } else if (stage == BrushingStage.upperRightInner) {
      // 8. Upper right inner (top to bottom) - Screen Right premolars/molars lingual enamel
      _germs = [
        _Germ(id: 1, position: _pixelPos(1170, 1410), color: Colors.green.shade600),
        _Germ(id: 2, position: _pixelPos(1070, 1415), color: Colors.blue.shade600),
      ];
      _foods = [
        _FoodItem(id: 1, position: _pixelPos(1120, 1425), foodType: 'crumb', color: const Color(0xFFD35400), size: 32),
      ];
      _dirtSpots = [
        _DirtSpot(id: 1, position: _pixelPos(1220, 1400), radius: 22, color: const Color(0xFFD4AC0D)),
      ];
    } else if (stage == BrushingStage.upperRightChewing) {
      // 9. Upper right molars chewing (yaw≈+20°, pitch≈+23°)
      _germs = [
        _Germ(id: 1, position: const Offset(0.77, 0.360), color: Colors.deepOrange.shade600),
        _Germ(id: 2, position: const Offset(0.83, 0.385), color: Colors.pink.shade700),
      ];
      _foods = [
        _FoodItem(id: 1, position: const Offset(0.80, 0.375), foodType: 'candy', color: const Color(0xFF8E44AD), size: 34),
      ];
      _dirtSpots = [
        _DirtSpot(id: 1, position: const Offset(0.75, 0.355), radius: 22, color: const Color(0xFFBA4A00)),
      ];
    } else if (stage == BrushingStage.lowerFrontOuter) {
      // 10. Lower front outward (yaw=0°, pitch≈-4.6°)
      // Lower central incisors visible at enamel: x=0.45–0.55, y=0.66–0.69
      _germs = [
        _Germ(id: 1, position: const Offset(0.46, 0.675), color: Colors.deepOrange.shade600),
        _Germ(id: 2, position: const Offset(0.50, 0.670), color: Colors.indigo.shade500),
        _Germ(id: 3, position: const Offset(0.54, 0.675), color: Colors.cyan.shade700),
      ];
      _foods = [
        _FoodItem(id: 1, position: const Offset(0.50, 0.680), foodType: 'leaf', color: const Color(0xFF27AE60), size: 34),
      ];
      _dirtSpots = [
        _DirtSpot(id: 1, position: const Offset(0.43, 0.675), radius: 22, color: const Color(0xFFD4AC0D)),
        _DirtSpot(id: 2, position: const Offset(0.57, 0.675), radius: 22, color: const Color(0xFFB7950B)),
      ];
    } else if (stage == BrushingStage.lowerFrontInner) {
      // 11. Behind lower front teeth (bottom to top) - clean_mouth_inner lingual enamel (Y = 1810-1825)
      _germs = [
        _Germ(id: 1, position: _pixelPos(740, 1810), color: Colors.blue.shade600),
        _Germ(id: 2, position: _pixelPos(830, 1810), color: Colors.teal.shade600),
      ];
      _foods = [
        _FoodItem(id: 1, position: _pixelPos(786, 1825), foodType: 'crumb', color: const Color(0xFFD35400), size: 32),
      ];
      _dirtSpots = [
        _DirtSpot(id: 1, position: _pixelPos(660, 1815), radius: 20, color: const Color(0xFFD4AC0D)),
        _DirtSpot(id: 2, position: _pixelPos(910, 1815), radius: 20, color: const Color(0xFFB7950B)),
      ];
    } else if (stage == BrushingStage.lowerFrontChewing) {
      // 12. Chewing / incisal biting edge of lower front (yaw=0°, pitch≈-11.5°)
      _germs = [
        _Germ(id: 1, position: const Offset(0.46, 0.665), color: Colors.purple.shade500),
        _Germ(id: 2, position: const Offset(0.54, 0.665), color: Colors.amber.shade700),
      ];
      _foods = [
        _FoodItem(id: 1, position: const Offset(0.50, 0.660), foodType: 'meat', color: const Color(0xFFC0392B), size: 32),
      ];
    } else if (stage == BrushingStage.lowerLeftOuter) {
      // 13. Lower left outward (yaw≈-25.8°, pitch≈-4.6°)
      // Lower left side teeth crowns (x=0.15–0.30, y=0.61–0.64)
      _germs = [
        _Germ(id: 1, position: const Offset(0.24, 0.635), color: Colors.amber.shade600),
        _Germ(id: 2, position: const Offset(0.15, 0.640), color: Colors.pink.shade700),
      ];
      _foods = [
        _FoodItem(id: 1, position: const Offset(0.20, 0.635), foodType: 'meat', color: const Color(0xFFC0392B), size: 34),
      ];
      _dirtSpots = [
        _DirtSpot(id: 1, position: const Offset(0.23, 0.635), radius: 24, color: const Color(0xFFD4AC0D)),
        _DirtSpot(id: 2, position: const Offset(0.13, 0.645), radius: 24, color: const Color(0xFFCA6F1E)),
      ];
    } else if (stage == BrushingStage.lowerLeftInner) {
      // 14. Lower left inner (bottom to top) - Screen Left premolars/molars lingual enamel
      _germs = [
        _Germ(id: 1, position: _pixelPos(400, 1870), color: Colors.deepOrange.shade600),
        _Germ(id: 2, position: _pixelPos(500, 1830), color: Colors.purple.shade600),
      ];
      _foods = [
        _FoodItem(id: 1, position: _pixelPos(450, 1855), foodType: 'leaf', color: const Color(0xFF2ECC71), size: 32),
      ];
      _dirtSpots = [
        _DirtSpot(id: 1, position: _pixelPos(350, 1885), radius: 22, color: const Color(0xFFD4AC0D)),
      ];
    } else if (stage == BrushingStage.lowerLeftChewing) {
      // 15. Lower left molars chewing (yaw≈-20°, pitch≈-23°)
      _germs = [
        _Germ(id: 1, position: const Offset(0.13, 0.590), color: Colors.teal.shade600),
        _Germ(id: 2, position: const Offset(0.10, 0.625), color: Colors.indigo.shade500),
      ];
      _foods = [
        _FoodItem(id: 1, position: const Offset(0.12, 0.610), foodType: 'cheese', color: const Color(0xFFF39C12), size: 34),
      ];
      _dirtSpots = [
        _DirtSpot(id: 1, position: const Offset(0.14, 0.585), radius: 22, color: const Color(0xFFCA6F1E)),
      ];
    } else if (stage == BrushingStage.lowerRightOuter) {
      // 16. Lower right outward (yaw≈+25.8°, pitch≈-4.6°)
      // Lower right side teeth crowns (x=0.70–0.85, y=0.61–0.64)
      _germs = [
        _Germ(id: 1, position: const Offset(0.76, 0.635), color: Colors.cyan.shade700),
        _Germ(id: 2, position: const Offset(0.85, 0.640), color: Colors.redAccent.shade400),
      ];
      _foods = [
        _FoodItem(id: 1, position: const Offset(0.80, 0.635), foodType: 'crumb', color: const Color(0xFFD35400), size: 34),
      ];
      _dirtSpots = [
        _DirtSpot(id: 1, position: const Offset(0.77, 0.635), radius: 24, color: const Color(0xFFD4AC0D)),
        _DirtSpot(id: 2, position: const Offset(0.87, 0.645), radius: 24, color: const Color(0xFFBA4A00)),
      ];
    } else if (stage == BrushingStage.lowerRightInner) {
      // 17. Lower right inner (bottom to top) - Screen Right premolars/molars lingual enamel
      _germs = [
        _Germ(id: 1, position: _pixelPos(1170, 1870), color: Colors.purple.shade500),
        _Germ(id: 2, position: _pixelPos(1070, 1830), color: Colors.teal.shade600),
      ];
      _foods = [
        _FoodItem(id: 1, position: _pixelPos(1120, 1855), foodType: 'candy', color: const Color(0xFF8E44AD), size: 32),
      ];
      _dirtSpots = [
        _DirtSpot(id: 1, position: _pixelPos(1220, 1885), radius: 22, color: const Color(0xFFD4AC0D)),
      ];
    } else if (stage == BrushingStage.lowerRightChewing) {
      // 18. Lower right molars chewing (yaw≈+20°, pitch≈-23°)
      _germs = [
        _Germ(id: 1, position: const Offset(0.87, 0.590), color: Colors.orange.shade700),
        _Germ(id: 2, position: const Offset(0.90, 0.625), color: Colors.pinkAccent.shade400),
      ];
      _foods = [
        _FoodItem(id: 1, position: const Offset(0.88, 0.610), foodType: 'meat', color: const Color(0xFFC0392B), size: 34),
      ];
      _dirtSpots = [
        _DirtSpot(id: 1, position: const Offset(0.86, 0.585), radius: 22, color: const Color(0xFFBA4A00)),
      ];
    } else if (stage == BrushingStage.brushTongue) {
      // 19. Tongue cleaning - dorsal surface
      _germs = [
        _Germ(id: 1, position: _pixelPos(740, 2000), color: Colors.deepPurple.shade400),
        _Germ(id: 2, position: _pixelPos(830, 2000), color: Colors.purple.shade600),
        _Germ(id: 3, position: _pixelPos(786, 2060), color: Colors.blue.shade600),
        _Germ(id: 4, position: _pixelPos(786, 1960), color: Colors.pinkAccent.shade700),
      ];
      _foods = [
        _FoodItem(id: 1, position: _pixelPos(786, 2015), foodType: 'crumb', color: const Color(0xFFD35400), size: 32),
      ];
      _dirtSpots = [
        _DirtSpot(id: 1, position: _pixelPos(710, 2035), radius: 22, color: const Color(0xFFD4AC0D)),
        _DirtSpot(id: 2, position: _pixelPos(860, 2035), radius: 22, color: const Color(0xFFB7950B)),
      ];
    }

    _totalStageItems = math.max(1, _germs.length + _foods.length + _dirtSpots.length);
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
      final now = DateTime.now();
      for (int i = _surfaceFoam.length - 1; i >= 0; i--) {
        final bubble = _surfaceFoam[i];
        final elapsedMs = now.difference(bubble.createdAt).inMilliseconds;
        bubble.life = 1.0 - (elapsedMs / 1000.0);
        if (bubble.life <= 0.0) {
          _surfaceFoam.removeAt(i);
        }
      }

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

          if (conf.position.dy > 950) {
            conf.position = Offset(math.Random().nextDouble() * 450 - 50, -50);
            conf.vy = math.Random().nextDouble() * 4 + 2;
          }
        }

        if (math.Random().nextDouble() < 0.18 && _sparkles.length < 20) {
          final bounds = _cachedBounds == Rect.zero
              ? const Rect.fromLTWH(60, 250, 240, 300)
              : _cachedBounds;
          final randomX = bounds.left + (0.24 + math.Random().nextDouble() * 0.52) * bounds.width;
          final randomY = bounds.top + (0.40 + math.Random().nextDouble() * 0.22) * bounds.height;
          _sparkles.add(
            _Sparkle(
              position: Offset(randomX, randomY),
              vx: 0,
              vy: 0,
              size: math.Random().nextDouble() * 24 + 14,
              color: math.Random().nextBool() ? const Color(0xFFFFD700) : Colors.white,
              isStar: true,
            ),
          );
        }
      }

      if (!_isDragging) {
        _dragTiltY *= 0.88;
        _dragTiltX *= 0.88;
        if (_dragTiltY.abs() < 0.0005) _dragTiltY = 0.0;
        if (_dragTiltX.abs() < 0.0005) _dragTiltX = 0.0;
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

  Matrix4 _buildCameraMatrix(BoxConstraints constraints) {
    _cachedBounds = _getImageBounds(constraints);

    final double cx = constraints.maxWidth / 2.0;
    final double cy = constraints.maxHeight / 2.0;

    final double tx = _cachedBounds.left + _camTarget.dx * _cachedBounds.width;
    final double ty = _cachedBounds.top + _camTarget.dy * _cachedBounds.height;

    final double effRotY = _camRotY + _dragTiltY;
    final double effRotX = _camRotX + _dragTiltX;

    final Matrix4 m = Matrix4.identity();
    m.translateByDouble(cx, cy, 0.0, 1.0);
    m.scaleByDouble(_camZoom, _camZoom, 1.0, 1.0);

    // Natural 3D model perspective depth (only for outer 2D illustration mode; back of teeth never rotates)
    if (!_shouldShow3DModel && !_isInnerStage) {
      final Matrix4 persp = Matrix4.identity()..setEntry(3, 2, 0.0006);
      m.multiply(persp);
      m.rotateY(effRotY);
      m.rotateX(effRotX);
    }

    m.translateByDouble(-tx, -ty, 0.0, 1.0);

    return m;
  }

  void _handleBrushing(Offset screenPos, BoxConstraints constraints) {
    _cachedBounds = _getImageBounds(constraints);

    final double touchX = screenPos.dx.clamp(20.0, constraints.maxWidth - 20.0);
    final double touchY = (screenPos.dy - 30.0).clamp(40.0, constraints.maxHeight - 40.0);
    final Offset newBrushPos = Offset(touchX, touchY);

    // Natural 3D tilt tracking user finger drag across dental canvas (only on outer stages)
    final double cx = constraints.maxWidth / 2.0;
    final double cy = constraints.maxHeight / 2.0;
    final double dragNormX = ((touchX - cx) / cx).clamp(-1.0, 1.0);
    final double dragNormY = ((touchY - cy) / cy).clamp(-1.0, 1.0);
    if (!_isInnerStage && !_shouldShow3DModel) {
      _dragTiltY = dragNormX * 0.28;
      _dragTiltX = -dragNormY * 0.22;
    } else {
      _dragTiltY = 0.0;
      _dragTiltX = 0.0;
    }

    setState(() {
      _brushPosition = newBrushPos;
      _isDragging = true;
    });

    // Map screen touch to mouth world coordinate using inverse 3D camera matrix
    final Matrix4 camMatrix = _buildCameraMatrix(constraints);
    final Matrix4? invMatrix = Matrix4.tryInvert(camMatrix);
    final Offset mouthLocalPos = invMatrix != null
        ? MatrixUtils.transformPoint(invMatrix, newBrushPos)
        : newBrushPos;

    // Instantaneous movement vector on screen
    final Offset stepDelta = _lastScreenBrushPos != null
        ? (newBrushPos - _lastScreenBrushPos!)
        : Offset.zero;
    _lastScreenBrushPos = newBrushPos;

    final bool isCorrectDirection = _processBrushingMotion(newBrushPos, stepDelta, mouthLocalPos);

    if (isCorrectDirection) {
      _produceFoamAlongPath(_previousBrushPositionLocal, mouthLocalPos);
    }
    _previousBrushPositionLocal = mouthLocalPos;

    _checkMouthItemsContact(mouthLocalPos, isCorrectDirection: isCorrectDirection);
  }

  bool _isPointOnMouthAndTeeth(Offset point) {
    if (_cachedBounds == Rect.zero ||
        _cachedBounds.width <= 0 ||
        _cachedBounds.height <= 0) {
      return false;
    }
    final double normX = (point.dx - _cachedBounds.left) / _cachedBounds.width;
    final double normY = (point.dy - _cachedBounds.top) / _cachedBounds.height;

    return normX >= 0.10 && normX <= 0.90 && normY >= 0.22 && normY <= 0.76;
  }

  void _produceFoamAlongPath(Offset? from, Offset to) {
    if (from != null && (to - from).distance > 10.0) {
      final double distance = (to - from).distance;
      final int steps = (distance / 12.0).clamp(1, 8).toInt();
      for (int i = 1; i <= steps; i++) {
        final double t = i / steps;
        final intermediate = Offset.lerp(from, to, t)!;
        _produceFoamAt(intermediate);
      }
    } else {
      _produceFoamAt(to);
    }
  }

  void _produceFoamAt(Offset point) {
    if (!_isPointOnMouthAndTeeth(point)) return;

    final random = math.Random();
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastFoamHapticTime > 120) {
      _lastFoamHapticTime = now;
      HapticFeedback.selectionClick();
    }

    // 1. Generate surface foam bubbles
    final int bubbleCount = random.nextInt(3) + 2;
    for (int i = 0; i < bubbleCount; i++) {
      final double angle = random.nextDouble() * 2 * math.pi;
      final double dist = random.nextDouble() * 20.0;
      final Offset bubblePos = point + Offset(math.cos(angle) * dist, math.sin(angle) * dist);

      if (!_isPointOnMouthAndTeeth(bubblePos)) continue;

      int nearby = 0;
      for (var existing in _surfaceFoam) {
        if ((existing.position - bubblePos).distance < 14.0) {
          nearby++;
          if (nearby >= 4) break;
        }
      }

      if (nearby < 4) {
        final double normX = (bubblePos.dx - _cachedBounds.left) / _cachedBounds.width;
        final double normY = (bubblePos.dy - _cachedBounds.top) / _cachedBounds.height;

        _surfaceFoam.add(
          _FoamBubble(
            position: bubblePos,
            normalizedPosition: Offset(normX, normY),
            radius: random.nextDouble() * 9.0 + 7.0,
            wobbleOffset: random.nextDouble() * math.pi * 2,
            isSurface: true,
          ),
        );

        if (_surfaceFoam.length > 350) {
          _surfaceFoam.removeAt(0);
        }
      }
    }

    // 2. Playful active airborne froth bubbles
    if (random.nextDouble() < 0.35) {
      _bubbles.add(
        _FoamBubble(
          position: point +
              Offset(
                random.nextDouble() * 24 - 12,
                random.nextDouble() * 16 - 8,
              ),
          vx: random.nextDouble() * 1.6 - 0.8,
          vy: random.nextDouble() * -1.5 - 0.5,
          radius: random.nextDouble() * 7.0 + 4.0,
          isSurface: false,
        ),
      );
    }
  }

  void _checkMouthItemsContact(Offset mouthLocalPos, {required bool isCorrectDirection}) {
    if (!isCorrectDirection) return;
    if (_cachedBounds == Rect.zero || _isStageTransitioning) return;

    // 1. Check Germs
    for (var germ in _germs) {
      if (germ.health > 0) {
        final Offset germAbs = _getItemRenderPosition(germ.position);
        if ((mouthLocalPos - germAbs).distance < 65.0) {
          germ.health -= 0.040;
          germ.isShaking = true;
          if (germ.health <= 0) {
            germ.health = 0;
            _onGermDefeated(germAbs, germ.color);
          }
        }
      }
    }

    // 2. Check Food residue items
    for (var food in _foods) {
      if (food.health > 0) {
        final Offset foodAbs = _getItemRenderPosition(food.position);
        if ((mouthLocalPos - foodAbs).distance < 65.0) {
          food.health -= 0.045;
          food.isShaking = true;
          if (food.health <= 0) {
            food.health = 0;
            _onFoodCleaned(foodAbs, food.color);
          }
        }
      }
    }

    // 3. Check Plaque / Dirt spots
    for (var dirt in _dirtSpots) {
      if (dirt.health > 0) {
        final Offset dirtAbs = _getItemRenderPosition(dirt.position);
        if ((mouthLocalPos - dirtAbs).distance < 60.0) {
          dirt.health -= 0.050;
          dirt.isShaking = true;
          if (dirt.health <= 0) {
            dirt.health = 0;
            _onDirtCleaned(dirtAbs);
          }
        }
      }
    }

    _checkStageProgress();
  }

  void _damageItemsNearBrush(Offset mouthLocalPos, {required double radius, required double damage}) {
    if (_cachedBounds == Rect.zero || _isStageTransitioning) return;

    for (var germ in _germs) {
      if (germ.health > 0) {
        final Offset germAbs = _getItemRenderPosition(germ.position);
        if ((mouthLocalPos - germAbs).distance <= radius) {
          germ.health -= damage;
          germ.isShaking = true;
          if (germ.health <= 0) {
            germ.health = 0;
            _onGermDefeated(germAbs, germ.color);
          }
        }
      }
    }
    for (var food in _foods) {
      if (food.health > 0) {
        final Offset foodAbs = _getItemRenderPosition(food.position);
        if ((mouthLocalPos - foodAbs).distance <= radius) {
          food.health -= damage;
          food.isShaking = true;
          if (food.health <= 0) {
            food.health = 0;
            _onFoodCleaned(foodAbs, food.color);
          }
        }
      }
    }
    for (var dirt in _dirtSpots) {
      if (dirt.health > 0) {
        final Offset dirtAbs = _getItemRenderPosition(dirt.position);
        if ((mouthLocalPos - dirtAbs).distance <= radius) {
          dirt.health -= damage;
          dirt.isShaking = true;
          if (dirt.health <= 0) {
            dirt.health = 0;
            _onDirtCleaned(dirtAbs);
          }
        }
      }
    }
    _checkStageProgress();
  }

  void _onGermDefeated(Offset offset, Color color) {
    HapticFeedback.mediumImpact();
    final random = math.Random();
    for (int k = 0; k < 12; k++) {
      final angle = k * (2 * math.pi / 12);
      final speed = random.nextDouble() * 3 + 2;
      _sparkles.add(
        _Sparkle(
          position: offset,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed,
          size: random.nextDouble() * 14 + 8,
          color: color,
          isStar: true,
        ),
      );
    }
    _checkStageProgress();
  }

  void _onFoodCleaned(Offset offset, Color color) {
    HapticFeedback.mediumImpact();
    final random = math.Random();
    for (int k = 0; k < 10; k++) {
      final angle = k * (2 * math.pi / 10);
      final speed = random.nextDouble() * 2.5 + 1.5;
      _sparkles.add(
        _Sparkle(
          position: offset,
          vx: math.cos(angle) * speed,
          vy: math.sin(angle) * speed,
          size: random.nextDouble() * 10 + 6,
          color: Colors.white,
          isStar: true,
        ),
      );
    }
    _checkStageProgress();
  }

  void _onDirtCleaned(Offset offset) {
    HapticFeedback.lightImpact();
    final random = math.Random();
    for (int k = 0; k < 6; k++) {
      _sparkles.add(
        _Sparkle(
          position: offset + Offset(random.nextDouble() * 20 - 10, random.nextDouble() * 20 - 10),
          vx: random.nextDouble() * 1.5 - 0.75,
          vy: random.nextDouble() * -1.5,
          size: random.nextDouble() * 8 + 4,
          color: Colors.amberAccent,
          isStar: true,
        ),
      );
    }
    _checkStageProgress();
  }

  BrushingDirectionRequirement _getDirectionRequirement(BrushingStage stage) {
    switch (stage) {
      case BrushingStage.upperFrontOuter:
      case BrushingStage.upperFrontInner:
      case BrushingStage.upperLeftOuter:
      case BrushingStage.upperLeftInner:
      case BrushingStage.upperRightOuter:
      case BrushingStage.upperRightInner:
        return BrushingDirectionRequirement.downward;

      case BrushingStage.lowerFrontOuter:
      case BrushingStage.lowerFrontInner:
      case BrushingStage.lowerLeftOuter:
      case BrushingStage.lowerLeftInner:
      case BrushingStage.lowerRightOuter:
      case BrushingStage.lowerRightInner:
        return BrushingDirectionRequirement.upward;

      case BrushingStage.upperFrontChewing:
      case BrushingStage.lowerFrontChewing:
        return BrushingDirectionRequirement.horizontal;

      case BrushingStage.upperLeftChewing:
      case BrushingStage.upperRightChewing:
      case BrushingStage.lowerLeftChewing:
      case BrushingStage.lowerRightChewing:
        return BrushingDirectionRequirement.verticalChewing;

      case BrushingStage.brushTongue:
        return BrushingDirectionRequirement.downward;

      case BrushingStage.mouthOverview:
      case BrushingStage.continue2Minutes:
        return BrushingDirectionRequirement.free;

      case BrushingStage.chooseBrush:
      case BrushingStage.chooseTime:
      case BrushingStage.gargleMouth:
      case BrushingStage.spitOut:
      case BrushingStage.cleanMouthDone:
        return BrushingDirectionRequirement.none;
    }
  }

  String _getDirectionWarningMessage(BrushingDirectionRequirement req) {
    switch (req) {
      case BrushingDirectionRequirement.downward:
        return 'فقط از بالا به پایین مسواک بزن! ⬇️';
      case BrushingDirectionRequirement.upward:
        return 'فقط از پایین به بالا مسواک بزن! ⬆️';
      case BrushingDirectionRequirement.horizontal:
        return 'فقط به چپ و راست مسواک بزن! ↔️';
      case BrushingDirectionRequirement.verticalChewing:
        return 'فقط به جلو و عقب مسواک بزن! ↕️';
      case BrushingDirectionRequirement.free:
      case BrushingDirectionRequirement.none:
        return '';
    }
  }

  bool _processBrushingMotion(Offset currentPos, Offset stepDelta, Offset mouthLocalPos) {
    final req = _getDirectionRequirement(_currentStage);
    if (req == BrushingDirectionRequirement.none) {
      return false;
    }
    if (req == BrushingDirectionRequirement.free) {
      return stepDelta.distance > 0.8;
    }

    _recentBrushPositions.add(currentPos);
    if (_recentBrushPositions.length > 5) {
      _recentBrushPositions.removeAt(0);
    }

    final double stepDist = stepDelta.distance;
    // Stationary finger or tap
    if (stepDist < 1.0) {
      return false;
    }

    // Displacement over recent frames
    final Offset windowDelta = _recentBrushPositions.length >= 2
        ? (_recentBrushPositions.last - _recentBrushPositions.first)
        : stepDelta;
    final double windowDist = windowDelta.distance;

    bool isCorrect = false;

    switch (req) {
      case BrushingDirectionRequirement.downward:
        // Must move downwards (positive dy). Angle tolerance: vertical must clearly dominate (|dx| <= dy * 0.9)
        final bool stepDown = stepDelta.dy > 1.0 && stepDelta.dy > stepDelta.dx.abs() * 0.9;
        final bool windowDown = windowDist < 3.0 || (windowDelta.dy > 0 && windowDelta.dy > windowDelta.dx.abs() * 0.7);
        if (stepDelta.dy <= 0.2) {
          isCorrect = false;
        } else {
          isCorrect = stepDown && windowDown;
        }
        break;

      case BrushingDirectionRequirement.upward:
        // Must move upwards (negative dy). Angle tolerance: vertical must clearly dominate (|dx| <= -dy * 0.9)
        final bool stepUp = stepDelta.dy < -1.0 && (-stepDelta.dy) > stepDelta.dx.abs() * 0.9;
        final bool windowUp = windowDist < 3.0 || (windowDelta.dy < 0 && (-windowDelta.dy) > windowDelta.dx.abs() * 0.7);
        if (stepDelta.dy >= -0.2) {
          isCorrect = false;
        } else {
          isCorrect = stepUp && windowUp;
        }
        break;

      case BrushingDirectionRequirement.horizontal:
        // Must move horizontally (|dx| > |dy| * 0.9)
        final bool stepH = stepDelta.dx.abs() > 1.0 && stepDelta.dx.abs() > stepDelta.dy.abs() * 0.9;
        final bool windowH = windowDist < 3.0 || (windowDelta.dx.abs() > windowDelta.dy.abs() * 0.7);
        isCorrect = stepH && windowH;
        break;

      case BrushingDirectionRequirement.verticalChewing:
        // Must move vertically (|dy| > |dx| * 0.9)
        final bool stepV = stepDelta.dy.abs() > 1.0 && stepDelta.dy.abs() > stepDelta.dx.abs() * 0.9;
        final bool windowV = windowDist < 3.0 || (windowDelta.dy.abs() > windowDelta.dy.abs() * 0.7);
        isCorrect = stepV && windowV;
        break;

      case BrushingDirectionRequirement.free:
      case BrushingDirectionRequirement.none:
        break;
    }

    if (isCorrect) {
      _wrongMotionAccumulator = 0.0;
      _currentStrokeDistance += stepDist;
      if (_currentStrokeDistance >= 24.0) {
        _currentStrokeDistance = 0.0;
        _onValidStrokeCompleted(mouthLocalPos);
      }
    } else {
      // Finger is moving, but in the wrong direction
      _currentStrokeDistance = 0.0;
      _wrongMotionAccumulator += stepDist;
      if (_wrongMotionAccumulator >= 28.0) {
        _wrongMotionAccumulator = 0.0;
        final String warning = _getDirectionWarningMessage(req);
        if (warning.isNotEmpty) {
          _showTooltip(warning);
        }
      }
    }

    return isCorrect;
  }

  void _onValidStrokeCompleted(Offset mouthLocalPos) {
    HapticFeedback.lightImpact();
    setState(() {
      _strokeCount++;
      _circleCount++;
      if (_currentStage == BrushingStage.brushTongue) {
        _tongueSwipeCount++;
      }
    });

    // Provide localized reward cleaning to items near the brush
    _damageItemsNearBrush(mouthLocalPos, radius: 80.0, damage: 0.15);

    // Emit sparkles at the brush head
    final random = math.Random();
    for (int k = 0; k < 4; k++) {
      _sparkles.add(
        _Sparkle(
          position: mouthLocalPos + Offset(random.nextDouble() * 24 - 12, random.nextDouble() * 24 - 12),
          vx: random.nextDouble() * 2.0 - 1.0,
          vy: random.nextDouble() * -2.0 - 0.5,
          size: random.nextDouble() * 8 + 5,
          color: Colors.white,
          isStar: true,
        ),
      );
    }
  }

  void _showTooltip(String message) {
    if (_tooltipText == message) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _tooltipText = message;
    });
    _tooltipTimer?.cancel();
    _tooltipTimer = Timer(const Duration(seconds: 3), () {
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
            _currentStage = BrushingStage.gargleMouth;
            _initGarglePhase();
            HapticFeedback.vibrate();
          }
        });
      }
    });
  }

  void _initGarglePhase() {
    _gargleProgress = 0.0;
    _isGarglingHolding = false;
    _isSpitHandled = false;
    _isSpittingAnimationRunning = false;
    _gargleTimer?.cancel();
    HapticFeedback.mediumImpact();
  }

  void _startGargling() {
    if (_currentStage != BrushingStage.gargleMouth) return;
    setState(() {
      _isGarglingHolding = true;
    });

    _gargleTimer?.cancel();
    _gargleTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_gargleProgress < 1.0) {
        setState(() {
          _gargleProgress += 0.018;
          if (_gargleProgress > 1.0) _gargleProgress = 1.0;
          if ((_gargleProgress * 100).toInt() % 15 == 0) {
            HapticFeedback.lightImpact();
          }
        });
      } else {
        timer.cancel();
        _stopGargling();
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _currentStage == BrushingStage.gargleMouth) {
            setState(() {
              _currentStage = BrushingStage.spitOut;
              _initSpitPhase();
            });
          }
        });
      }
    });
  }

  void _stopGargling() {
    _gargleTimer?.cancel();
    if (mounted) {
      setState(() {
        _isGarglingHolding = false;
      });
    }
  }

  void _initSpitPhase() {
    _gargleTimer?.cancel();
    _isGarglingHolding = false;
    _isSpitHandled = false;
    _isSpittingAnimationRunning = false;
    _spitDroplets.clear();
    _spitController.reset();
  }

  void _handleSpit() {
    if (_isSpitHandled || _isSpittingAnimationRunning || _currentStage != BrushingStage.spitOut) return;
    setState(() {
      _isSpitHandled = true;
      _isSpittingAnimationRunning = true;
    });

    HapticFeedback.heavyImpact();
    _spawnSpitDroplets();
    _spitController.forward(from: 0.0);
  }

  void _spawnSpitDroplets() {
    final random = math.Random();
    _spitDroplets.clear();
    for (int i = 0; i < 28; i++) {
      final bool isFoam = random.nextBool();
      _spitDroplets.add(
        _SplashDroplet(
          x: 0.0,
          y: 0.0,
          vx: (random.nextDouble() - 0.5) * 14.0,
          vy: -2.0 - random.nextDouble() * 10.0,
          radius: isFoam ? 3.0 + random.nextDouble() * 4.0 : 2.5 + random.nextDouble() * 5.0,
          color: isFoam
              ? Colors.white.withValues(alpha: 0.90)
              : const Color(0xFF29B6F6).withValues(alpha: 0.85),
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

  void _logActivityAndShowCelebration() {
    if (_isActivityLogged) return;
    _isActivityLogged = true;

    setState(() {
      _currentStage = BrushingStage.cleanMouthDone;
      _initCelebration();
    });
    _animateCameraTo(BrushingStage.cleanMouthDone);

    final activeChild = HealthcareApi.instance.currentChild;
    if (activeChild != null) {
      HealthcareApi.instance.children.logActivity(
        activeChild.id,
        ActivityLogRequest(
          activityType: 'brushing_interactive',
          durationSeconds: _isFastMode ? 15 : 120,
          completedSteps: const [
            'chooseBrush',
            'chooseTime',
            'mouthOverview',
            'upperFrontOuter',
            'upperFrontInner',
            'upperFrontChewing',
            'upperLeftOuter',
            'upperLeftInner',
            'upperLeftChewing',
            'upperRightOuter',
            'upperRightInner',
            'upperRightChewing',
            'lowerFrontOuter',
            'lowerFrontInner',
            'lowerFrontChewing',
            'lowerLeftOuter',
            'lowerLeftInner',
            'lowerLeftChewing',
            'lowerRightOuter',
            'lowerRightInner',
            'lowerRightChewing',
            'brushTongue',
            'gargleMouth',
            'spitOut',
            'cleanMouthDone'
          ],
        ),
      ).then((res) {
        final oldStars = HealthcareApi.instance.currentChild?.stars ?? 0;
        HealthcareApi.instance.currentChild = activeChild.copyWith(
          stars: oldStars + res.starsEarned,
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

  void _checkStageProgress() {
    if (_isStageTransitioning) return;
    final activeGermsCount = _germs.where((g) => g.health > 0).length;
    final activeFoodsCount = _foods.where((f) => f.health > 0).length;
    final activeDirtCount = _dirtSpots.where((d) => d.health > 0).length;
    final activeTotal = activeGermsCount + activeFoodsCount + activeDirtCount;

    setState(() {
      _cleanlinessProgress = _totalStageItems > 0
          ? (1.0 - (activeTotal / _totalStageItems)).clamp(0.0, 1.0)
          : 1.0;
    });

    if (activeTotal == 0 && _currentStage != BrushingStage.mouthOverview) {
      _isStageTransitioning = true;
      Future.delayed(const Duration(milliseconds: 650), () {
        if (!mounted) return;
        _transitionToNextStage();
      });
    }
  }

  void _transitionToNextStage() {
    _isStageTransitioning = false;
    _bubbles.clear();
    _sparkles.clear();
    _dragHistory.clear();
    _currentStrokeDistance = 0.0;
    _circleCount = 0;
    _strokeCount = 0;
    _tongueSwipeCount = 0;
    _previousBrushPositionLocal = null;
    _lastScreenBrushPos = null;
    _recentBrushPositions.clear();
    _wrongMotionAccumulator = 0.0;

    setState(() {
      switch (_currentStage) {
        case BrushingStage.chooseBrush:
          _currentStage = BrushingStage.chooseTime;
          break;
        case BrushingStage.chooseTime:
          _currentStage = BrushingStage.mouthOverview;
          _initStageItems(BrushingStage.mouthOverview);
          break;
        case BrushingStage.mouthOverview:
          _currentStage = BrushingStage.upperFrontOuter;
          _initStageItems(BrushingStage.upperFrontOuter);
          break;

        // Upper Front
        case BrushingStage.upperFrontOuter:
          _currentStage = BrushingStage.upperFrontInner;
          _initStageItems(BrushingStage.upperFrontInner);
          break;
        case BrushingStage.upperFrontInner:
          _currentStage = BrushingStage.upperFrontChewing;
          _initStageItems(BrushingStage.upperFrontChewing);
          break;
        case BrushingStage.upperFrontChewing:
          _currentStage = BrushingStage.upperLeftOuter;
          _initStageItems(BrushingStage.upperLeftOuter);
          break;

        // Upper Left (3D turned to left)
        case BrushingStage.upperLeftOuter:
          _currentStage = BrushingStage.upperLeftInner;
          _initStageItems(BrushingStage.upperLeftInner);
          break;
        case BrushingStage.upperLeftInner:
          _currentStage = BrushingStage.upperLeftChewing;
          _initStageItems(BrushingStage.upperLeftChewing);
          break;
        case BrushingStage.upperLeftChewing:
          _currentStage = BrushingStage.upperRightOuter;
          _initStageItems(BrushingStage.upperRightOuter);
          break;

        // Upper Right (3D turned to right)
        case BrushingStage.upperRightOuter:
          _currentStage = BrushingStage.upperRightInner;
          _initStageItems(BrushingStage.upperRightInner);
          break;
        case BrushingStage.upperRightInner:
          _currentStage = BrushingStage.upperRightChewing;
          _initStageItems(BrushingStage.upperRightChewing);
          break;
        case BrushingStage.upperRightChewing:
          _currentStage = BrushingStage.lowerFrontOuter;
          _initStageItems(BrushingStage.lowerFrontOuter);
          break;

        // Lower Front
        case BrushingStage.lowerFrontOuter:
          _currentStage = BrushingStage.lowerFrontInner;
          _initStageItems(BrushingStage.lowerFrontInner);
          break;
        case BrushingStage.lowerFrontInner:
          _currentStage = BrushingStage.lowerFrontChewing;
          _initStageItems(BrushingStage.lowerFrontChewing);
          break;
        case BrushingStage.lowerFrontChewing:
          _currentStage = BrushingStage.lowerLeftOuter;
          _initStageItems(BrushingStage.lowerLeftOuter);
          break;

        // Lower Left (3D turned to left)
        case BrushingStage.lowerLeftOuter:
          _currentStage = BrushingStage.lowerLeftInner;
          _initStageItems(BrushingStage.lowerLeftInner);
          break;
        case BrushingStage.lowerLeftInner:
          _currentStage = BrushingStage.lowerLeftChewing;
          _initStageItems(BrushingStage.lowerLeftChewing);
          break;
        case BrushingStage.lowerLeftChewing:
          _currentStage = BrushingStage.lowerRightOuter;
          _initStageItems(BrushingStage.lowerRightOuter);
          break;

        // Lower Right (3D turned to right)
        case BrushingStage.lowerRightOuter:
          _currentStage = BrushingStage.lowerRightInner;
          _initStageItems(BrushingStage.lowerRightInner);
          break;
        case BrushingStage.lowerRightInner:
          _currentStage = BrushingStage.lowerRightChewing;
          _initStageItems(BrushingStage.lowerRightChewing);
          break;
        case BrushingStage.lowerRightChewing:
          _currentStage = BrushingStage.brushTongue;
          _initStageItems(BrushingStage.brushTongue);
          break;

        // Tongue -> Gargle
        case BrushingStage.brushTongue:
          _currentStage = BrushingStage.gargleMouth;
          _initGarglePhase();
          break;
        case BrushingStage.continue2Minutes:
          _currentStage = BrushingStage.gargleMouth;
          _initGarglePhase();
          break;
        case BrushingStage.gargleMouth:
          _currentStage = BrushingStage.spitOut;
          _initSpitPhase();
          break;
        case BrushingStage.spitOut:
          _spitController.stop();
          _logActivityAndShowCelebration();
          break;
        default:
          break;
      }
      _brushPosition = const Offset(200, 500);
    });

    _animateCameraTo(_currentStage);
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
        final scale = Tween<double>(begin: 0.8, end: 1.0)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack));
        return Transform.scale(
          scale: scale.value,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                SquishPopButton(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9B59B6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'باشه، متوجه شدم! 👍',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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

  void _showWrongTimeDialog(String title, String message) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, a1, a2) => const SizedBox(),
      transitionBuilder: (context, anim, secAnim, child) {
        final scale = Tween<double>(begin: 0.8, end: 1.0)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack));
        return Transform.scale(
          scale: scale.value,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                SquishPopButton(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF9B59B6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'متوجه شدم! دوباره انتخاب می‌کنم! ⏱️',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
      barrierLabel: 'Celebration',
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (context, a1, a2) => const SizedBox(),
      transitionBuilder: (context, anim, secAnim, child) {
        final curvedAnim = CurvedAnimation(parent: anim, curve: Curves.elasticOut);
        return Transform.scale(
          scale: curvedAnim.value,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
              backgroundColor: Colors.white,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🎉🦷✨', style: TextStyle(fontSize: 54)),
                  const SizedBox(height: 16),
                  const Text(
                    'آفرین قهرمان تمیزی!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'تمام میکروب‌ها و باقیمانده غذاها را پاک کردی و دندان‌هایت مثل الماس می‌درخشند!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  SquishPopButton(
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
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
          ),
        );
      },
    );
  }

  String _getStageObject() {
    switch (_currentStage) {
      case BrushingStage.chooseBrush:
      case BrushingStage.chooseTime:
        return '';

      // Outer and Chewing surfaces use front mouth image
      case BrushingStage.mouthOverview:
      case BrushingStage.upperFrontOuter:
      case BrushingStage.upperFrontChewing:
      case BrushingStage.upperLeftOuter:
      case BrushingStage.upperLeftChewing:
      case BrushingStage.upperRightOuter:
      case BrushingStage.upperRightChewing:
      case BrushingStage.lowerFrontOuter:
      case BrushingStage.lowerFrontChewing:
      case BrushingStage.lowerLeftOuter:
      case BrushingStage.lowerLeftChewing:
      case BrushingStage.lowerRightOuter:
      case BrushingStage.lowerRightChewing:
        return 'assets/brush/clean_mouth_front_1572x3408.png';

      case BrushingStage.cleanMouthDone:
        return 'assets/Group 3.png';

      // Inner surfaces (back of teeth) and tongue/gargle/spit use inner mouth image
      case BrushingStage.upperFrontInner:
      case BrushingStage.upperLeftInner:
      case BrushingStage.upperRightInner:
      case BrushingStage.lowerFrontInner:
      case BrushingStage.lowerLeftInner:
      case BrushingStage.lowerRightInner:
      case BrushingStage.brushTongue:
      case BrushingStage.continue2Minutes:
      case BrushingStage.gargleMouth:
      case BrushingStage.spitOut:
        return 'assets/brush/clean_mouth_inner_1572x3408.png';
    }
  }

  String _getInstructionText() {
    switch (_currentStage) {
      case BrushingStage.chooseBrush:
        return 'مقدار مناسب خمیر دندان روی مسواک را انتخاب کن! 🪥';
      case BrushingStage.chooseTime:
        return 'زمان مناسب مسواک زدن را انتخاب کن! ⏱️';
      case BrushingStage.mouthOverview:
        return 'ای وای! دهان پر از میکروب، غذا و کثیفی است! 😱';

      // Upper Front
      case BrushingStage.upperFrontOuter:
        return '۱. سطح بیرونی دندان‌های جلوی فک بالا: با مسواک از بالا به پایین بکش! ⬇️ (حرکت: $_circleCount)';
      case BrushingStage.upperFrontInner:
        return '۲. پشت دندان‌های جلوی فک بالا: مسواک را از بالا به پایین بکش! ⬇️ (حرکت: $_circleCount)';
      case BrushingStage.upperFrontChewing:
        return '۳. سطح جونده دندان‌های جلوی بالا: مسواک را موازی لبه دندان عقب و جلو بکش! ↔️ (حرکت: $_strokeCount)';

      // Upper Left
      case BrushingStage.upperLeftOuter:
        return '۴. سطح بیرونی دندان‌های چپ فک بالا: از بالا به پایین بکش! ⬇️ (حرکت: $_circleCount)';
      case BrushingStage.upperLeftInner:
        return '۵. سطح داخلی (پشت) دندان‌های چپ فک بالا: از بالا به پایین بکش! ⬇️ (حرکت: $_circleCount)';
      case BrushingStage.upperLeftChewing:
        return '۶. سطح جونده دندان‌های چپ بالا: مسواک را عمودی و موازی سطح عقب و جلو بکش! ↕️ (حرکت: $_strokeCount)';

      // Upper Right
      case BrushingStage.upperRightOuter:
        return '۷. سطح بیرونی دندان‌های راست فک بالا: از بالا به پایین بکش! ⬇️ (حرکت: $_circleCount)';
      case BrushingStage.upperRightInner:
        return '۸. سطح داخلی (پشت) دندان‌های راست فک بالا: از بالا به پایین بکش! ⬇️ (حرکت: $_circleCount)';
      case BrushingStage.upperRightChewing:
        return '۹. سطح جونده دندان‌های راست بالا: مسواک را عمودی و موازی سطح عقب و جلو بکش! ↕️ (حرکت: $_strokeCount)';

      // Lower Front
      case BrushingStage.lowerFrontOuter:
        return '۱۰. سطح بیرونی دندان‌های جلوی فک پایین: مسواک را از پایین به بالا بکش! ⬆️ (حرکت: $_circleCount)';
      case BrushingStage.lowerFrontInner:
        return '۱۱. پشت دندان‌های جلوی فک پایین: مسواک را از پایین به بالا بکش! ⬆️ (حرکت: $_circleCount)';
      case BrushingStage.lowerFrontChewing:
        return '۱۲. سطح جونده دندان‌های جلوی پایین: مسواک را موازی لبه دندان عقب و جلو بکش! ↔️ (حرکت: $_strokeCount)';

      // Lower Left
      case BrushingStage.lowerLeftOuter:
        return '۱۳. سطح بیرونی دندان‌های چپ فک پایین: از پایین به بالا بکش! ⬆️ (حرکت: $_circleCount)';
      case BrushingStage.lowerLeftInner:
        return '۱۴. سطح داخلی (پشت) دندان‌های چپ فک پایین: از پایین به بالا بکش! ⬆️ (حرکت: $_circleCount)';
      case BrushingStage.lowerLeftChewing:
        return '۱۵. سطح جونده دندان‌های چپ پایین: مسواک را عمودی و موازی سطح عقب و جلو بکش! ↕️ (حرکت: $_strokeCount)';

      // Lower Right
      case BrushingStage.lowerRightOuter:
        return '۱۶. سطح بیرونی دندان‌های راست فک پایین: از پایین به بالا بکش! ⬆️ (حرکت: $_circleCount)';
      case BrushingStage.lowerRightInner:
        return '۱۷. سطح داخلی (پشت) دندان‌های راست فک پایین: از پایین به بالا بکش! ⬆️ (حرکت: $_circleCount)';
      case BrushingStage.lowerRightChewing:
        return '۱۸. سطح جونده دندان‌های راست پایین: مسواک را عمودی و موازی سطح عقب و جلو بکش! ↕️ (حرکت: $_strokeCount)';

      // Tongue
      case BrushingStage.brushTongue:
        return '۱۹. تمیز کردن زبان با حرکت رفت و برگشتی! ↕️ (حرکت: $_tongueSwipeCount)';

      case BrushingStage.continue2Minutes:
        return 'مسواک زدن را ادامه بده تا ۲ دقیقه تمام شود! ⏳';
      case BrushingStage.gargleMouth:
        return '۲۰. یک قلپ آب بردار و دهانت رو خوب آب‌کشی و غرغره کن! 💧🫧';
      case BrushingStage.spitOut:
        return '۲۱. حالا آب و کف خمیردندان را داخل سینک تف کن! 💦';
      case BrushingStage.cleanMouthDone:
        return 'دندون‌هات از تمیزی مثل مروارید دارن برق می‌زنن! 😍⭐';
    }
  }

  String _getQuadrantLabel() {
    switch (_currentStage) {
      case BrushingStage.mouthOverview:
        return 'نمای کلی دهان';
      case BrushingStage.upperFrontOuter:
        return 'فک بالا • جلو (سطح بیرونی)';
      case BrushingStage.upperFrontInner:
        return 'فک بالا • جلو (پشت دندان‌ها)';
      case BrushingStage.upperFrontChewing:
        return 'فک بالا • جلو (لبه جونده)';
      case BrushingStage.upperLeftOuter:
        return 'فک بالا • چپ (سطح بیرونی)';
      case BrushingStage.upperLeftInner:
        return 'فک بالا • چپ (سطح داخلی)';
      case BrushingStage.upperLeftChewing:
        return 'فک بالا • چپ (سطح جونده)';
      case BrushingStage.upperRightOuter:
        return 'فک بالا • راست (سطح بیرونی)';
      case BrushingStage.upperRightInner:
        return 'فک بالا • راست (سطح داخلی)';
      case BrushingStage.upperRightChewing:
        return 'فک بالا • راست (سطح جونده)';
      case BrushingStage.lowerFrontOuter:
        return 'فک پایین • جلو (سطح بیرونی)';
      case BrushingStage.lowerFrontInner:
        return 'فک پایین • جلو (پشت دندان‌ها)';
      case BrushingStage.lowerFrontChewing:
        return 'فک پایین • جلو (لبه جونده)';
      case BrushingStage.lowerLeftOuter:
        return 'فک پایین • چپ (سطح بیرونی)';
      case BrushingStage.lowerLeftInner:
        return 'فک پایین • چپ (سطح داخلی)';
      case BrushingStage.lowerLeftChewing:
        return 'فک پایین • چپ (سطح جونده)';
      case BrushingStage.lowerRightOuter:
        return 'فک پایین • راست (سطح بیرونی)';
      case BrushingStage.lowerRightInner:
        return 'فک پایین • راست (سطح داخلی)';
      case BrushingStage.lowerRightChewing:
        return 'فک پایین • راست (سطح جونده)';
      case BrushingStage.brushTongue:
        return 'تمیز کردن زبان';
      case BrushingStage.gargleMouth:
        return 'مرحله نهایی • آب‌کشی و غرغره دهان';
      case BrushingStage.spitOut:
        return 'مرحله نهایی • تف کردن در سینک';
      case BrushingStage.cleanMouthDone:
        return 'پایان تمیزکاری';
      default:
        return '';
    }
  }

  Widget _buildGameHeader(BoxConstraints constraints) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 16,
      right: 16,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_getQuadrantLabel().isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9B59B6).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _getQuadrantLabel(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8E44AD),
                            ),
                          ),
                        ),
                      Text(
                        _getInstructionText(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_currentStage != BrushingStage.chooseBrush &&
                    _currentStage != BrushingStage.chooseTime &&
                    _currentStage != BrushingStage.cleanMouthDone)
                  SquishPopButton(
                    onTap: () {
                      _transitionToNextStage();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9B59B6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'بعدی',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8E44AD),
                            ),
                          ),
                          Icon(Icons.skip_next_rounded, size: 16, color: Color(0xFF8E44AD)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          if (_tooltipText.isNotEmpty) ...[
            _buildTooltip(),
            const SizedBox(height: 8),
          ],

          if (_currentStage != BrushingStage.chooseBrush &&
              _currentStage != BrushingStage.chooseTime &&
              _currentStage != BrushingStage.cleanMouthDone) ...[
            Builder(
              builder: (context) {
                final double currentProgress = _currentStage == BrushingStage.gargleMouth
                    ? _gargleProgress
                    : (_currentStage == BrushingStage.spitOut
                        ? (_isSpitHandled ? _spitController.value : 0.0)
                        : _cleanlinessProgress);

                return Row(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: (constraints.maxWidth - 32) * currentProgress,
                            height: 14,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
                              ),
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(currentProgress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                      ),
                    ),
                  ],
                );
              },
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
            const Icon(Icons.info_outline, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                _tooltipText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerProgress() {
    final progress = _isFastMode
        ? (15 - _secondsRemaining) / 15.0
        : (120 - _secondsRemaining) / 120.0;

    return Container(
      width: 140,
      height: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
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
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              _isFastMode ? const Color(0xFFE67E22) : const Color(0xFF3498DB),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_secondsRemaining ~/ 60}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              Text(
                _isFastMode ? 'حالت سریع ⚡' : 'حالت واقعی ⏱️',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChooseBrushStage(BoxConstraints constraints) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: const Text(
              'اندازه مناسب خمیر دندان را انتخاب کن! 🪥',
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
              'روی کدام مسواک به اندازه یک نخود خمیر دندان قرار دارد؟ 🤔',
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
            height: 250,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_brushes.length, (index) {
                final isSelected = _selectedBrushIndex == index;
                final isCorrect =
                    _brushes[index] ==
                    'assets/Gemini_Generated_Image_bmoqd1bmoqd1bmoq 2.png';

                return AnimatedBuilder(
                  animation: _floatingController,
                  builder: (context, child) {
                    final offset =
                        math.sin(
                          (_floatingController.value * math.pi * 2) +
                              index * 1.5,
                        ) *
                        10.0;

                    return Transform.translate(
                      offset: Offset(0, offset),
                      child: SquishPopButton(
                        onTap: () {
                          setState(() {
                            _selectedBrushIndex = index;
                          });
                          HapticFeedback.mediumImpact();

                          if (isCorrect) {
                            Future.delayed(
                              const Duration(milliseconds: 500),
                              () {
                                if (mounted) {
                                  setState(() {
                                    _currentStage = BrushingStage.chooseTime;
                                  });
                                }
                              },
                            );
                          } else {
                            Future.delayed(
                              const Duration(milliseconds: 300),
                              () {
                                if (mounted) {
                                  if (_brushes[index].contains('bmoqd1bmoqd1bmoq 1')) {
                                    _showWrongBrushDialog(
                                      'اوه! خمیر دندان خیلی زیاده! 😲',
                                      'این مسواک خمیر دندان زیادی داره و ممکنه دهانت رو اذیت کنه. مسواکی رو انتخاب کن که به اندازه یک نخود خمیر دندان داشته باشه!',
                                    );
                                  } else {
                                    _showWrongBrushDialog(
                                      'اوه! این مسواک خمیر دندان نداره! 🪥',
                                      'این مسواک هیچ خمیر دندانی نداره! بدون خمیر دندان دندان‌ها تمیز نمی‌شن. مسواکی رو انتخاب کن که به اندازه یک نخود خمیر دندان داشته باشه!',
                                    );
                                  }
                                }
                              },
                            );
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF2ECC71)
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? const Color(0xFF2ECC71).withValues(alpha: 0.3)
                                    : Colors.black12,
                                blurRadius: isSelected ? 12 : 6,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            _brushes[index],
                            height: 180,
                            fit: BoxFit.contain,
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
    );
  }

  Widget _buildChooseTimeStage(BoxConstraints constraints) {
    final timeOptions = [
      {'minutes': 2, 'label': '۲ دقیقه\n(استاندارد دندانپزشکی)', 'isCorrect': true},
      {'minutes': 5, 'label': '۵ دقیقه\n(خیلی زیاد)', 'isCorrect': false},
      {'minutes': 10, 'label': '۱۰ دقیقه\n(بسیار طولانی)', 'isCorrect': false},
    ];

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 3),
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
                                    _currentStage = BrushingStage.mouthOverview;
                                    _initStageItems(BrushingStage.mouthOverview);
                                  });
                                  _animateCameraTo(BrushingStage.mouthOverview);
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF2ECC71)
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? const Color(0xFF2ECC71).withValues(alpha: 0.3)
                                    : Colors.black12,
                                blurRadius: isSelected ? 12 : 6,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 48,
                                color: isSelected
                                    ? const Color(0xFF2ECC71)
                                    : const Color(0xFF9B59B6),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${option['minutes']} دقیقه',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                (option['label'] as String).split('\n').last,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildOverviewOverlay(BoxConstraints constraints) {
    return Positioned(
      bottom: 40,
      left: 20,
      right: 20,
      child: AnimatedBuilder(
        animation: _floatingController,
        builder: (context, child) {
          final scale = 1.0 + 0.03 * math.sin(_floatingController.value * math.pi * 2);
          return Transform.scale(
            scale: scale,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9B59B6).withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('😱 🦠 🥦', style: TextStyle(fontSize: 34)),
                  const SizedBox(height: 6),
                  const Text(
                    'دهان پر از کثیفی، غذا و میکروبه!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'ببین چقدر غذا و میکروب روی دندان‌ها نشسته!\nبیا با مسواک بخش به بخش تمیزشون کنیم! ✨',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SquishPopButton(
                    onTap: () {
                      _transitionToNextStage();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2ECC71).withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'شروع مسواک زدن 🪥',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Offset _getStageActiveCenter(BrushingStage stage) {
    switch (stage) {
      case BrushingStage.upperFrontOuter:
        return const Offset(0.50, 0.355);
      case BrushingStage.upperFrontInner:
        return const Offset(0.50, 0.41);
      case BrushingStage.upperFrontChewing:
        return const Offset(0.50, 0.300);
      case BrushingStage.upperLeftOuter:
        return const Offset(0.22, 0.340);
      case BrushingStage.upperLeftInner:
        return const Offset(0.28, 0.41);
      case BrushingStage.upperLeftChewing:
        return const Offset(0.20, 0.370);
      case BrushingStage.upperRightOuter:
        return const Offset(0.78, 0.340);
      case BrushingStage.upperRightInner:
        return const Offset(0.72, 0.41);
      case BrushingStage.upperRightChewing:
        return const Offset(0.80, 0.370);
      case BrushingStage.lowerFrontOuter:
        return const Offset(0.50, 0.675);
      case BrushingStage.lowerFrontInner:
        return const Offset(0.50, 0.53);
      case BrushingStage.lowerFrontChewing:
        return const Offset(0.50, 0.665);
      case BrushingStage.lowerLeftOuter:
        return const Offset(0.20, 0.635);
      case BrushingStage.lowerLeftInner:
        return const Offset(0.28, 0.54);
      case BrushingStage.lowerLeftChewing:
        return const Offset(0.12, 0.610);
      case BrushingStage.lowerRightOuter:
        return const Offset(0.80, 0.635);
      case BrushingStage.lowerRightInner:
        return const Offset(0.72, 0.54);
      case BrushingStage.lowerRightChewing:
        return const Offset(0.88, 0.610);
      case BrushingStage.brushTongue:
        return const Offset(0.50, 0.59);
      default:
        return const Offset(0.50, 0.50);
    }
  }

  Widget _buildBrushingWorld(BoxConstraints constraints) {
    final Matrix4 cameraMatrix = _buildCameraMatrix(constraints);
    final double effRotY = _camRotY + _dragTiltY;
    final double effRotX = _camRotX + _dragTiltX;
    final Offset activeCenter = _getStageActiveCenter(_currentStage);

    // Directional Guide Arrow indicators anchored in the mouth
    Widget? guideArrow;
    final bool isUpperDown = _currentStage == BrushingStage.upperFrontOuter ||
        _currentStage == BrushingStage.upperFrontInner ||
        _currentStage == BrushingStage.upperLeftOuter ||
        _currentStage == BrushingStage.upperLeftInner ||
        _currentStage == BrushingStage.upperRightOuter ||
        _currentStage == BrushingStage.upperRightInner;

    final bool isLowerUp = _currentStage == BrushingStage.lowerFrontOuter ||
        _currentStage == BrushingStage.lowerFrontInner ||
        _currentStage == BrushingStage.lowerLeftOuter ||
        _currentStage == BrushingStage.lowerLeftInner ||
        _currentStage == BrushingStage.lowerRightOuter ||
        _currentStage == BrushingStage.lowerRightInner;

    final bool isSideChewing = _currentStage == BrushingStage.upperLeftChewing ||
        _currentStage == BrushingStage.upperRightChewing ||
        _currentStage == BrushingStage.lowerLeftChewing ||
        _currentStage == BrushingStage.lowerRightChewing;

    final bool isFrontChewing = _currentStage == BrushingStage.upperFrontChewing ||
        _currentStage == BrushingStage.lowerFrontChewing;

    final bool isTongue = _currentStage == BrushingStage.brushTongue;

    if (isUpperDown) {
      guideArrow = Positioned(
        left: _cachedBounds.left + activeCenter.dx * _cachedBounds.width - 24,
        top: _cachedBounds.top +
            (activeCenter.dy - 0.06 + _floatingController.value * 0.04) * _cachedBounds.height,
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              return Opacity(
                opacity: 0.4 + 0.35 * math.sin(_floatingController.value * math.pi * 2),
                child: const Icon(
                  Icons.arrow_downward,
                  size: 48,
                  color: Colors.lightBlueAccent,
                ),
              );
            },
          ),
        ),
      );
    } else if (isLowerUp) {
      guideArrow = Positioned(
        left: _cachedBounds.left + activeCenter.dx * _cachedBounds.width - 24,
        top: _cachedBounds.top +
            (activeCenter.dy + 0.06 - _floatingController.value * 0.04) * _cachedBounds.height,
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              return Opacity(
                opacity: 0.4 + 0.35 * math.sin(_floatingController.value * math.pi * 2),
                child: const Icon(
                  Icons.arrow_upward,
                  size: 48,
                  color: Colors.greenAccent,
                ),
              );
            },
          ),
        ),
      );
    } else if (isSideChewing) {
      // Chewing vertical arrow guide
      guideArrow = Positioned(
        left: _cachedBounds.left + activeCenter.dx * _cachedBounds.width - 24,
        top: _cachedBounds.top + activeCenter.dy * _cachedBounds.height - 24,
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              final t = _floatingController.value;
              final icon = (t * 2).floor() % 2 == 0
                  ? Icons.arrow_downward
                  : Icons.arrow_upward;
              return Opacity(
                opacity: 0.45 + 0.35 * math.sin(t * math.pi * 2),
                child: Icon(
                  icon,
                  size: 48,
                  color: Colors.orangeAccent,
                ),
              );
            },
          ),
        ),
      );
    } else if (isFrontChewing) {
      // Front chewing horizontal arrow guide
      guideArrow = Positioned(
        left: _cachedBounds.left + activeCenter.dx * _cachedBounds.width - 24,
        top: _cachedBounds.top + activeCenter.dy * _cachedBounds.height - 24,
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              final t = _floatingController.value;
              final icon = (t * 2).floor() % 2 == 0
                  ? Icons.arrow_forward
                  : Icons.arrow_back;
              return Opacity(
                opacity: 0.45 + 0.35 * math.sin(t * math.pi * 2),
                child: Icon(
                  icon,
                  size: 48,
                  color: Colors.orangeAccent,
                ),
              );
            },
          ),
        ),
      );
    } else if (isTongue) {
      guideArrow = Positioned(
        left: _cachedBounds.left + activeCenter.dx * _cachedBounds.width - 24,
        top: _cachedBounds.top + activeCenter.dy * _cachedBounds.height - 24,
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _floatingController,
            builder: (context, child) {
              final t = _floatingController.value;
              final icon = (t * 2).floor() % 2 == 0
                  ? Icons.arrow_downward
                  : Icons.arrow_upward;
              return Opacity(
                opacity: 0.4 + 0.3 * math.sin(t * math.pi * 2),
                child: Icon(
                  icon,
                  size: 48,
                  color: Colors.pinkAccent,
                ),
              );
            },
          ),
        ),
      );
    }

    return Transform(
      transform: cameraMatrix,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 0. Ambient 3D model contact shadow
          Positioned(
            left: _cachedBounds.left + _cachedBounds.width * 0.16,
            top: _cachedBounds.top + _cachedBounds.height * 0.72,
            width: _cachedBounds.width * 0.68,
            height: 38,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(
                    Radius.elliptical(_cachedBounds.width * 0.34, 19),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 30,
                      spreadRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 1. Mouth image (Clean front or Clean inner) OR Real 3D Model
          Positioned(
            left: _cachedBounds.left,
            top: _cachedBounds.top,
            width: _cachedBounds.width,
            height: _cachedBounds.height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 2D Image for Inner stages (نمای داخل) or 2D illustration mode
                AnimatedOpacity(
                  opacity: _shouldShow3DModel ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 250),
                  child: IgnorePointer(
                    ignoring: _shouldShow3DModel,
                    child: Image.asset(
                      _getStageObject(),
                      key: ValueKey<String>(_getStageObject()),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                // Persistent 3D Model Viewer (never reloads from disk between stages)
                if (_is3DModelMode)
                  AnimatedOpacity(
                    opacity: _shouldShow3DModel ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: IgnorePointer(
                      ignoring: !_shouldShow3DModel,
                      child: Mouth3DViewer(
                        key: const ValueKey<String>('persistent_mouth_3d_viewer'),
                        yaw: ((_camRotY + _dragTiltY) * (180.0 / math.pi)),
                        pitch: ((_camRotX + _dragTiltX) * (180.0 / math.pi)),
                        zoom: 6.8,
                        targetY: 0.0,
                        interactive: false,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 1.1 Volumetric 3D Depth Lighting & Shading (for 2.5D illustration mode)
          if (!_shouldShow3DModel && (effRotY != 0.0 || effRotX != 0.0)) ...[
            // Lateral Receding Jaw Depth Shadow
            if (effRotY != 0.0)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: effRotY < 0 ? Alignment.centerLeft : Alignment.centerRight,
                        end: effRotY < 0 ? Alignment.centerRight : Alignment.centerLeft,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: (effRotY.abs() * 0.50).clamp(0.0, 0.22)),
                        ],
                        stops: const [0.35, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

            // Vertical Palate / Sublingual Floor Depth Shadow
            if (effRotX != 0.0)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: effRotX > 0 ? Alignment.topCenter : Alignment.bottomCenter,
                        end: effRotX > 0 ? Alignment.bottomCenter : Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: (effRotX.abs() * 0.45).clamp(0.0, 0.18)),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.65],
                      ),
                    ),
                  ),
                ),
              ),

            // 3D Specular Highlight / Enamel Curvature Rim Light
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(
                        (-effRotY * 1.8).clamp(-0.85, 0.85),
                        (-effRotX * 1.8).clamp(-0.85, 0.85),
                      ),
                      radius: 0.85,
                      colors: [
                        Colors.white.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ],

          // 2. Dirt plaque spots
          ..._dirtSpots.map((dirt) {
            if (dirt.health <= 0) return const SizedBox.shrink();
            final Offset renderPos = _getItemRenderPosition(dirt.position);
            final double x = renderPos.dx;
            final double y = renderPos.dy;
            return Positioned(
              left: x - dirt.radius,
              top: y - dirt.radius,
              child: SizedBox(
                width: dirt.radius * 2,
                height: dirt.radius * 2,
                child: CustomPaint(
                  painter: CutePlaquePainter(
                    color: dirt.color,
                    health: dirt.health,
                    radius: dirt.radius,
                  ),
                ),
              ),
            );
          }),

          // 3. Food residue items with soft 3D contact shadows
          ..._foods.expand((food) {
            if (food.health <= 0) return <Widget>[];
            final Offset renderPos = _getItemRenderPosition(food.position);
            final double x = renderPos.dx;
            final double y = renderPos.dy;
            return [
              Positioned(
                left: x - food.size * 0.35 + 2.0,
                top: y - food.size * 0.20 + 3.0,
                child: IgnorePointer(
                  child: Container(
                    width: food.size * 0.7 * food.health,
                    height: food.size * 0.35 * food.health,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25 * food.health),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: x - food.size / 2,
                top: y - food.size / 2,
                child: AnimatedBuilder(
                  animation: _wiggleController,
                  builder: (context, child) {
                    return SizedBox(
                      width: food.size,
                      height: food.size,
                      child: CustomPaint(
                        painter: CuteFoodPainter(
                          foodType: food.foodType,
                          color: food.color,
                          health: food.health,
                          animationValue: _wiggleController.value,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ];
          }),

          // 4. Germs with soft 3D contact shadows
          ..._germs.expand((germ) {
            if (germ.health <= 0) return <Widget>[];
            final Offset renderPos = _getItemRenderPosition(germ.position);
            final double x = renderPos.dx;
            final double y = renderPos.dy;
            return [
              Positioned(
                left: x - 18 + 2.0,
                top: y - 8 + 3.0,
                child: IgnorePointer(
                  child: Container(
                    width: 36 * germ.health,
                    height: 16 * germ.health,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.28 * germ.health),
                          blurRadius: 7,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: x - 26,
                top: y - 26,
                child: AnimatedBuilder(
                  animation: _wiggleController,
                  builder: (context, child) {
                    double angle = 0.0;
                    double scaleOffset = 1.0;
                    if (germ.isShaking) {
                      angle = (math.Random().nextDouble() * 0.2 - 0.1);
                      scaleOffset = 0.95;
                    } else {
                      angle = math.sin(_wiggleController.value * math.pi * 2) * 0.05;
                      scaleOffset = 1.0 + (math.sin(_wiggleController.value * math.pi * 2) * 0.05);
                    }

                    return Transform.rotate(
                      angle: angle,
                      child: Transform.scale(
                        scale: scaleOffset * germ.health,
                        child: SizedBox(
                          width: 52,
                          height: 52,
                          child: CustomPaint(
                            painter: CuteGermPainter(
                              color: germ.color,
                              health: germ.health,
                              animationValue: _wiggleController.value,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ];
          }),

          // 5. Surface foam (attached to tooth coordinates)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _SurfaceFoamPainter(
                  foamList: _surfaceFoam,
                  animationValue: _floatingController.value,
                  cachedBounds: _cachedBounds,
                ),
              ),
            ),
          ),

          // 6. Directional guide arrow
          if (guideArrow != null) guideArrow,
        ],
      ),
    );
  }

  Widget _buildTeethBrighteningEffect(BoxConstraints constraints) {
    if (_currentStage != BrushingStage.cleanMouthDone) {
      return const SizedBox.shrink();
    }
    final teethRect = _cachedBounds == Rect.zero
        ? Rect.fromLTWH(0, constraints.maxHeight * 0.3, constraints.maxWidth, constraints.maxHeight * 0.4)
        : _cachedBounds;
    final teethCenter = Offset(teethRect.center.dx, teethRect.top + teethRect.height * 0.525);

    return AnimatedBuilder(
      animation: _celebrationController,
      builder: (context, child) {
        final val = _celebrationController.value;
        final pulse = 0.5 + 0.5 * math.sin(val * math.pi * 2);
        final gleamOffset = -1.5 + 3.0 * val;

        return Stack(
          children: [
            // 1. Radiant luminous glow directly on clean teeth
            Positioned(
              left: teethCenter.dx - 140,
              top: teethCenter.dy - 65,
              width: 280,
              height: 130,
              child: Opacity(
                opacity: (0.35 + 0.45 * pulse).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.90),
                        const Color(0xFFE0F7FA).withValues(alpha: 0.55),
                        const Color(0xFF80DEEA).withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.4, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // 2. Sweeping diagonal gleam light beam across teeth
            Positioned(
              left: teethCenter.dx - 130,
              top: teethCenter.dy - 35,
              width: 260,
              height: 70,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Opacity(
                  opacity: (0.25 + 0.65 * pulse).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(gleamOffset - 0.5, -1.0),
                        end: Alignment(gleamOffset + 0.5, 1.0),
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.15),
                          Colors.white.withValues(alpha: 0.95),
                          Colors.white.withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.42, 0.50, 0.58, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
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
            _cachedBounds = _getImageBounds(constraints);

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Background
                Positioned.fill(
                  child: Image.asset(
                    'assets/Gemini_Generated_Image_5zdvov5zdvov5zdv 1.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),

                // 3D Transformed Mouth World
                if (_currentStage != BrushingStage.chooseBrush &&
                    _currentStage != BrushingStage.chooseTime &&
                    _currentStage != BrushingStage.gargleMouth &&
                    _currentStage != BrushingStage.spitOut &&
                    _currentStage != BrushingStage.cleanMouthDone)
                  Positioned.fill(
                    child: _buildBrushingWorld(constraints),
                  ),

                // Last step: Picture of that boy with teeth brightening!
                if (_currentStage == BrushingStage.cleanMouthDone) ...[
                  Positioned.fill(
                    child: Center(
                      child: Image.asset(
                        'assets/Group 3.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _celebrationController,
                          builder: (context, child) {
                            return Opacity(
                              opacity: (0.45 +
                                      0.55 *
                                          math.sin(
                                            _celebrationController.value *
                                                math.pi *
                                                2,
                                          ))
                                  .clamp(0.0, 1.0),
                              child: Image.asset(
                                'assets/Gemini_Generated_Image_gv7eufgv7eufgv7e 1.png',
                                fit: BoxFit.contain,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: _buildTeethBrighteningEffect(constraints),
                    ),
                  ),
                ],

                // Gesture detector covering active brushing stages
                if (_currentStage != BrushingStage.chooseBrush &&
                    _currentStage != BrushingStage.chooseTime &&
                    _currentStage != BrushingStage.gargleMouth &&
                    _currentStage != BrushingStage.spitOut &&
                    _currentStage != BrushingStage.cleanMouthDone)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (details) {
                        _lastScreenBrushPos = null;
                        _recentBrushPositions.clear();
                        _currentStrokeDistance = 0.0;
                        _wrongMotionAccumulator = 0.0;
                        _handleBrushing(details.localPosition, constraints);
                      },
                      onPanUpdate: (details) =>
                          _handleBrushing(details.localPosition, constraints),
                      onPanEnd: (_) {
                        setState(() {
                          _isDragging = false;
                          _previousBrushPositionLocal = null;
                          _lastScreenBrushPos = null;
                          _recentBrushPositions.clear();
                          _currentStrokeDistance = 0.0;
                          _wrongMotionAccumulator = 0.0;
                        });
                      },
                      onPanCancel: () {
                        setState(() {
                          _isDragging = false;
                          _previousBrushPositionLocal = null;
                          _lastScreenBrushPos = null;
                          _recentBrushPositions.clear();
                          _currentStrokeDistance = 0.0;
                          _wrongMotionAccumulator = 0.0;
                        });
                      },
                    ),
                  ),

                // Animated wave at bottom during gargle & spit phases
                if (_currentStage == BrushingStage.gargleMouth ||
                    _currentStage == BrushingStage.spitOut)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _waveController,
                        builder: (context, child) {
                          return CustomPaint(
                            painter: _WavePainter(
                              waveAnimation: _waveController.value,
                              fillLevel: 0.22,
                              color: const Color(0xFF29B6F6).withValues(alpha: 0.25),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                // Kid Gargling Scene
                if (_currentStage == BrushingStage.gargleMouth)
                  Positioned.fill(
                    child: Column(
                      children: [
                        SizedBox(height: MediaQuery.of(context).padding.top + 130),
                        Expanded(
                          child: Center(
                            child: AnimatedBuilder(
                              animation: Listenable.merge([_cheekPuffController, _gargleBubbleController]),
                              builder: (context, child) {
                                final double puff = _isGarglingHolding
                                    ? math.sin(_cheekPuffController.value * math.pi) * 16.0
                                    : 0.0;
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    if (_isGarglingHolding)
                                      Container(
                                        width: 240 + (math.sin(_gargleBubbleController.value * math.pi * 2) * 15),
                                        height: 240 + (math.sin(_gargleBubbleController.value * math.pi * 2) * 15),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFF29B6F6).withValues(alpha: 0.25),
                                        ),
                                      ),
                                    CustomPaint(
                                      size: const Size(220, 260),
                                      painter: _GarglingKidPainter(
                                        isGargling: _isGarglingHolding,
                                        puffAmount: puff,
                                        bubbleAnim: _gargleBubbleController.value,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'میزان آب‌کشی و غرغره: ${(_gargleProgress * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0288D1),
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
                                  color: const Color(0xFF0288D1),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 45),
                          child: GestureDetector(
                            onTapDown: (_) => _startGargling(),
                            onTapUp: (_) => _stopGargling(),
                            onTapCancel: () => _stopGargling(),
                            child: SquishPopButton(
                              squishScale: 0.88,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _isGarglingHolding
                                        ? [const Color(0xFF0288D1), const Color(0xFF01579B)]
                                        : [const Color(0xFF29B6F6), const Color(0xFF0288D1)],
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0288D1).withValues(alpha: 0.4),
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
                                      _isGarglingHolding
                                          ? 'کودک در حال آب‌کشی و غرغره... 🫧'
                                          : 'نگه‌دار تا کودک غرغره کند! 💧',
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
                          ),
                        ),
                      ],
                    ),
                  ),

                // Kid Spitting Scene
                if (_currentStage == BrushingStage.spitOut)
                  Positioned.fill(
                    child: Column(
                      children: [
                        SizedBox(height: MediaQuery.of(context).padding.top + 130),
                        Expanded(
                          child: Center(
                            child: AnimatedBuilder(
                              animation: _spitController,
                              builder: (context, child) {
                                return CustomPaint(
                                  size: Size(constraints.maxWidth, 340),
                                  painter: _SpittingKidScenePainter(
                                    spitProgress: _spitController.value,
                                    droplets: _spitDroplets,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 45),
                          child: SquishPopButton(
                            onTap: _handleSpit,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 18),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF29B6F6), Color(0xFF0288D1)],
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0288D1).withValues(alpha: 0.4),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  )
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _isSpittingAnimationRunning ? Icons.water_drop : Icons.cleaning_services,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isSpittingAnimationRunning
                                        ? 'در حال تخلیه آب و کف... 🫧'
                                        : 'حالا کودک تف کند! 💦',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Airborne particles & bubbles
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

                // Celebration Confetti
                if (_currentStage == BrushingStage.cleanMouthDone)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _ConfettiPainter(confetti: _confetti),
                      ),
                    ),
                  ),

                // Interactive Toothbrush tracking finger position
                if (_selectedBrushIndex != -1 &&
                    _currentStage != BrushingStage.chooseBrush &&
                    _currentStage != BrushingStage.chooseTime &&
                    _currentStage != BrushingStage.mouthOverview &&
                    _currentStage != BrushingStage.spitOut &&
                    _currentStage != BrushingStage.gargleMouth &&
                    _currentStage != BrushingStage.cleanMouthDone) ...[
                  // 3D Soft Contact Shadow beneath toothbrush bristles
                  Positioned(
                    left: _brushPosition.dx - 18,
                    top: _brushPosition.dy + 8,
                    child: IgnorePointer(
                      child: AnimatedRotation(
                        turns: _getBrushRotationForStage(_currentStage) / (2 * math.pi),
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutBack,
                        alignment: const Alignment(-0.7, 0.0),
                        child: Container(
                          width: 130,
                          height: 28,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.32),
                                blurRadius: 14,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 3D Toothbrush with perspective tilt & dynamic dragging response
                  Positioned(
                    left: _brushPosition.dx - 28,
                    top: _brushPosition.dy - 46,
                    child: IgnorePointer(
                      child: AnimatedRotation(
                        turns: _getBrushRotationForStage(_currentStage) / (2 * math.pi),
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutBack,
                        alignment: const Alignment(-0.7, 0.0), // Rotate around bristle head!
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          transform: Matrix4.translationValues(
                            _isDragging ? (math.Random().nextDouble() * 4 - 2) : 0.0,
                            _isDragging ? (math.Random().nextDouble() * 4 - 2) : 0.0,
                            0.0,
                          ),
                          child: Transform(
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.0006)
                              ..rotateY(_isInnerStage ? 0.0 : (_camRotY + _dragTiltY) * 0.50)
                              ..rotateX(_isInnerStage ? 0.0 : (_camRotX + _dragTiltX) * 0.50),
                            alignment: const Alignment(-0.7, 0.0),
                            child: Image.asset(
                              'assets/Gemini_Generated_Image_nt5olnt5olnt5oln 1.png',
                              width: 185,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                // Overview Dialog / Card
                if (_currentStage == BrushingStage.mouthOverview)
                  _buildOverviewOverlay(constraints),

                // Header & status
                if (_currentStage != BrushingStage.chooseBrush &&
                    _currentStage != BrushingStage.chooseTime)
                  _buildGameHeader(constraints),

                // Setup stages
                if (_currentStage == BrushingStage.chooseBrush)
                  _buildChooseBrushStage(constraints),

                if (_currentStage == BrushingStage.chooseTime)
                  _buildChooseTimeStage(constraints),

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
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                // Back Button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  right: 16,
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
                        size: 22,
                      ),
                    ),
                  ),
                ),

                // Simple Timer Shortcut (on choose stage)
                if (_currentStage == BrushingStage.chooseBrush ||
                    _currentStage == BrushingStage.chooseTime)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 10,
                    left: 16,
                    child: SquishPopButton(
                      onTap: () => Navigator.pushNamed(context, '/timer'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                            Icon(Icons.timer_outlined, color: Color(0xFF9B59B6), size: 16),
                            SizedBox(width: 4),
                            Text(
                              'تایمر ساده',
                              style: TextStyle(
                                fontSize: 11,
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
}

// -------------------------------------------------------------
// Models
// -------------------------------------------------------------

class _Germ {
  final int id;
  final Offset position;
  final Color color;
  double health;
  bool isShaking;

  _Germ({
    required this.id,
    required this.position,
    required this.color,
  })  : health = 1.0,
        isShaking = false;
}

class _FoodItem {
  final int id;
  final Offset position;
  final String foodType; // 'leaf', 'cheese', 'meat', 'crumb', 'candy'
  final Color color;
  final double size;
  double health;
  bool isShaking;

  _FoodItem({
    required this.id,
    required this.position,
    required this.foodType,
    required this.color,
    required this.size,
  })  : health = 1.0,
        isShaking = false;
}

class _DirtSpot {
  final int id;
  final Offset position;
  final double radius;
  final Color color;
  double health;
  bool isShaking;

  _DirtSpot({
    required this.id,
    required this.position,
    required this.radius,
    required this.color,
  })  : health = 1.0,
        isShaking = false;
}

class _FoamBubble {
  Offset position;
  final Offset normalizedPosition;
  final double vx;
  final double vy;
  final double radius;
  double life = 1.0;
  final double wobbleOffset;
  final bool isSurface;
  final DateTime createdAt;

  _FoamBubble({
    required this.position,
    this.normalizedPosition = Offset.zero,
    this.vx = 0.0,
    this.vy = 0.0,
    required this.radius,
    this.wobbleOffset = 0.0,
    this.isSurface = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class _Sparkle {
  Offset position;
  final double vx;
  final double vy;
  final double size;
  final Color color;
  double progress = 0.0;
  final bool isStar;

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
  final double vx;
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

// -------------------------------------------------------------
// Custom Painters
// -------------------------------------------------------------

class CuteFoodPainter extends CustomPainter {
  final String foodType;
  final Color color;
  final double health;
  final double animationValue;

  CuteFoodPainter({
    required this.foodType,
    required this.color,
    required this.health,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (health <= 0) return;

    final double w = size.width;
    final double h = size.height;
    final Offset center = Offset(w / 2, h / 2);
    final double wobble = math.sin(animationValue * math.pi * 2) * 1.5;

    final Paint bodyPaint = Paint()
      ..color = color.withValues(alpha: (0.95 * health).clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    if (foodType == 'leaf') {
      final Path leafPath = Path();
      leafPath.moveTo(w * 0.1, h * 0.5 + wobble);
      leafPath.cubicTo(w * 0.2, h * 0.1, w * 0.8, h * 0.1, w * 0.9, h * 0.5);
      leafPath.cubicTo(w * 0.8, h * 0.9, w * 0.2, h * 0.9, w * 0.1, h * 0.5 + wobble);
      leafPath.close();
      canvas.drawPath(leafPath, bodyPaint);

      final Paint veinPaint = Paint()
        ..color = Colors.white.withValues(alpha: (0.55 * health).clamp(0.0, 1.0))
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(w * 0.2, h * 0.5), Offset(w * 0.8, h * 0.5), veinPaint);
      canvas.drawLine(Offset(w * 0.45, h * 0.5), Offset(w * 0.65, h * 0.3), veinPaint);
      canvas.drawLine(Offset(w * 0.45, h * 0.5), Offset(w * 0.65, h * 0.7), veinPaint);
    } else if (foodType == 'cheese') {
      final Path cheesePath = Path();
      cheesePath.moveTo(w * 0.5, h * 0.15 + wobble);
      cheesePath.lineTo(w * 0.9, h * 0.85);
      cheesePath.lineTo(w * 0.1, h * 0.85);
      cheesePath.close();
      canvas.drawPath(cheesePath, bodyPaint);

      final Paint holePaint = Paint()
        ..color = Colors.orange.shade800.withValues(alpha: (0.35 * health).clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(w * 0.5, h * 0.55), w * 0.11, holePaint);
      canvas.drawCircle(Offset(w * 0.35, h * 0.72), w * 0.08, holePaint);
      canvas.drawCircle(Offset(w * 0.68, h * 0.68), w * 0.07, holePaint);
    } else if (foodType == 'meat') {
      final RRect rrect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: w * 0.85, height: h * 0.7),
        Radius.circular(w * 0.2),
      );
      canvas.drawRRect(rrect, bodyPaint);

      final Paint streakPaint = Paint()
        ..color = Colors.white.withValues(alpha: (0.4 * health).clamp(0.0, 1.0))
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(w * 0.25, h * 0.4), Offset(w * 0.75, h * 0.4), streakPaint);
      canvas.drawLine(Offset(w * 0.25, h * 0.6), Offset(w * 0.75, h * 0.6), streakPaint);
    } else if (foodType == 'candy') {
      final Path candyPath = Path();
      candyPath.addOval(Rect.fromCenter(center: center, width: w * 0.8, height: h * 0.8));
      canvas.drawPath(candyPath, bodyPaint);

      final Paint swirlPaint = Paint()
        ..color = Colors.white.withValues(alpha: (0.5 * health).clamp(0.0, 1.0))
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;
      canvas.drawArc(
        Rect.fromCenter(center: center, width: w * 0.45, height: h * 0.45),
        0.5,
        4.0,
        false,
        swirlPaint,
      );
    } else {
      // Bread/cake crumbs
      canvas.drawCircle(Offset(w * 0.35, h * 0.4), w * 0.18, bodyPaint);
      canvas.drawCircle(Offset(w * 0.65, h * 0.55), w * 0.20, bodyPaint);
      canvas.drawCircle(Offset(w * 0.45, h * 0.7), w * 0.15, bodyPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CuteFoodPainter oldDelegate) {
    return oldDelegate.health != health || oldDelegate.animationValue != animationValue;
  }
}

class CutePlaquePainter extends CustomPainter {
  final Color color;
  final double health;
  final double radius;

  CutePlaquePainter({
    required this.color,
    required this.health,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (health <= 0) return;

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double r = radius * (0.8 + 0.2 * health);

    final Paint plaquePaint = Paint()
      ..color = color.withValues(alpha: (0.75 * health).clamp(0.0, 1.0))
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

    canvas.drawOval(
      Rect.fromCenter(center: center, width: r * 2.1, height: r * 1.3),
      plaquePaint,
    );

    final Paint speckPaint = Paint()
      ..color = Colors.brown.shade800.withValues(alpha: (0.45 * health).clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center + Offset(-r * 0.25, -r * 0.1), 1.6, speckPaint);
    canvas.drawCircle(center + Offset(r * 0.22, r * 0.12), 1.4, speckPaint);
  }

  @override
  bool shouldRepaint(covariant CutePlaquePainter oldDelegate) {
    return oldDelegate.health != health;
  }
}

class _SurfaceFoamPainter extends CustomPainter {
  final List<_FoamBubble> foamList;
  final double animationValue;
  final Rect cachedBounds;

  _SurfaceFoamPainter({
    required this.foamList,
    required this.animationValue,
    required this.cachedBounds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (foamList.isEmpty || cachedBounds == Rect.zero) return;

    final basePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.90)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFF64B5F6).withValues(alpha: 0.40)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.fill;

    final subHighlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.60)
      ..style = PaintingStyle.fill;

    for (var bubble in foamList) {
      final double x = cachedBounds.left + bubble.normalizedPosition.dx * cachedBounds.width;
      final double y = cachedBounds.top + bubble.normalizedPosition.dy * cachedBounds.height;
      final center = Offset(x, y);
      bubble.position = center;

      final double opacity =
          (bubble.life > 0.3 ? 1.0 : (bubble.life / 0.3)).clamp(0.0, 1.0);
      basePaint.color = Colors.white.withValues(alpha: opacity * 0.90);
      strokePaint.color = const Color(0xFF64B5F6).withValues(alpha: opacity * 0.40);
      highlightPaint.color = Colors.white.withValues(alpha: opacity * 0.95);
      subHighlightPaint.color = Colors.white.withValues(alpha: opacity * 0.60);

      final double wobble = math.sin((animationValue * math.pi * 2) + bubble.wobbleOffset) * 0.6;
      final double r = (bubble.radius + wobble).clamp(3.0, 30.0);

      canvas.drawCircle(center, r, basePaint);
      canvas.drawCircle(center, r, strokePaint);

      final highlightPos = center + Offset(-r * 0.32, -r * 0.32);
      canvas.drawCircle(highlightPos, r * 0.22, highlightPaint);

      final subHighlightPos = center + Offset(r * 0.25, r * 0.25);
      canvas.drawCircle(subHighlightPos, r * 0.12, subHighlightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SurfaceFoamPainter oldDelegate) {
    return true;
  }
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

    // Ears
    paint.color = const Color(0xFFFFD2A6);
    final double earPuff = isGargling ? puffAmount * 0.4 : 0.0;
    canvas.drawCircle(Offset(headCenter.dx - headRadius - earPuff, headCenter.dy), 14, paint);
    canvas.drawCircle(Offset(headCenter.dx + headRadius + earPuff, headCenter.dy), 14, paint);

    paint.color = const Color(0xFFFFB5C5).withValues(alpha: 0.5);
    canvas.drawCircle(Offset(headCenter.dx - headRadius - earPuff, headCenter.dy), 7, paint);
    canvas.drawCircle(Offset(headCenter.dx + headRadius + earPuff, headCenter.dy), 7, paint);

    // Shirt
    paint.color = const Color(0xFF2980B9);
    final shirtPath = Path();
    shirtPath.moveTo(headCenter.dx - w * 0.36, h * 0.84);
    shirtPath.lineTo(headCenter.dx + w * 0.36, h * 0.84);
    shirtPath.lineTo(headCenter.dx + w * 0.45, h);
    shirtPath.lineTo(headCenter.dx - w * 0.45, h);
    shirtPath.close();
    canvas.drawPath(shirtPath, paint);

    // Collar
    paint.color = Colors.white;
    final collarPath = Path();
    collarPath.moveTo(headCenter.dx - 22, h * 0.84);
    collarPath.lineTo(headCenter.dx, h * 0.92);
    collarPath.lineTo(headCenter.dx + 22, h * 0.84);
    collarPath.close();
    canvas.drawPath(collarPath, paint);

    // Star badge
    final starPaint = Paint()..color = Colors.amber;
    canvas.drawCircle(Offset(headCenter.dx + 26, h * 0.92), 7, starPaint);

    // Head with puffed cheeks
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

    // Hair
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

    // Eyes
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

    // Eyebrows
    final browPaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(leftEye.dx - 10, leftEye.dy - 16), Offset(leftEye.dx + 8, leftEye.dy - 18), browPaint);
    canvas.drawLine(Offset(rightEye.dx - 8, rightEye.dy - 18), Offset(rightEye.dx + 10, rightEye.dy - 16), browPaint);

    // Cute Nose
    final nosePaint = Paint()
      ..color = const Color(0xFFE59866)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCenter(center: Offset(headCenter.dx, headCenter.dy + headRadius * 0.15), width: 8, height: 6), 0, math.pi, false, nosePaint);

    // Cheerful Blushing
    final blushPaint = Paint()
      ..color = const Color(0xFFFF8A80).withValues(alpha: 0.65)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(headCenter.dx - headRadius * 0.65 - (puffAmount * 0.5), headCenter.dy + 16), 18, blushPaint);
    canvas.drawCircle(Offset(headCenter.dx + headRadius * 0.65 + (puffAmount * 0.5), headCenter.dy + 16), 18, blushPaint);

    // Mouth (Gargling with water & bubbles or smiling)
    if (isGargling) {
      final liquidPaint = Paint()
        ..color = const Color(0xFF29B6F6)
        ..style = PaintingStyle.fill;

      final Rect mouthRect = Rect.fromCenter(
        center: Offset(headCenter.dx, headCenter.dy + headRadius * 0.42),
        width: 48 + (puffAmount * 1.1),
        height: 32,
      );
      canvas.drawOval(mouthRect, liquidPaint);

      // Bubbles swirling in mouth
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

    // Ears
    paint.color = const Color(0xFFFFD2A6);
    canvas.drawCircle(Offset(kidHeadCenter.dx - headRadius, kidHeadCenter.dy), 12, paint);
    canvas.drawCircle(Offset(kidHeadCenter.dx + headRadius, kidHeadCenter.dy), 12, paint);

    // Shirt
    paint.color = const Color(0xFF2980B9);
    final shirtPath = Path();
    shirtPath.moveTo(kidHeadCenter.dx - 55, kidHeadCenter.dy + 42);
    shirtPath.lineTo(kidHeadCenter.dx + 55, kidHeadCenter.dy + 42);
    shirtPath.lineTo(kidHeadCenter.dx + 70, kidHeadCenter.dy + 95);
    shirtPath.lineTo(kidHeadCenter.dx - 70, kidHeadCenter.dy + 95);
    shirtPath.close();
    canvas.drawPath(shirtPath, paint);

    // White collar
    paint.color = Colors.white;
    final collar = Path();
    collar.moveTo(kidHeadCenter.dx - 20, kidHeadCenter.dy + 42);
    collar.lineTo(kidHeadCenter.dx, kidHeadCenter.dy + 56);
    collar.lineTo(kidHeadCenter.dx + 20, kidHeadCenter.dy + 42);
    collar.close();
    canvas.drawPath(collar, paint);

    // Head
    paint.color = const Color(0xFFFFD2A6);
    canvas.drawCircle(kidHeadCenter, headRadius, paint);

    // Hair
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

    // Eyes
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

    // Blush
    final blushPaint = Paint()
      ..color = const Color(0xFFFF8A80).withValues(alpha: 0.65)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(kidHeadCenter.dx - 32, kidHeadCenter.dy + 14), 14, blushPaint);
    canvas.drawCircle(Offset(kidHeadCenter.dx + 32, kidHeadCenter.dy + 14), 14, blushPaint);

    // Mouth: open spitting or happy proud smile with clean teeth
    final Offset mouthPos = Offset(kidHeadCenter.dx, kidHeadCenter.dy + 24);
    if (spitProgress < 0.9) {
      final mouthPaint = Paint()..color = const Color(0xFFE74C3C);
      canvas.drawCircle(mouthPos, 12, mouthPaint);
    } else {
      // Clean teeth happy smile!
      final smilePaint = Paint()
        ..color = const Color(0xFF2ECC71)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round;
      final smilePath = Path();
      smilePath.moveTo(kidHeadCenter.dx - 18, kidHeadCenter.dy + 20);
      smilePath.quadraticBezierTo(kidHeadCenter.dx, kidHeadCenter.dy + 36, kidHeadCenter.dx + 18, kidHeadCenter.dy + 20);
      canvas.drawPath(smilePath, smilePaint);

      // Sparkling clean white teeth
      final teethPaint = Paint()..color = Colors.white;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(kidHeadCenter.dx, kidHeadCenter.dy + 24), width: 18, height: 8),
          const Radius.circular(3),
        ),
        teethPaint,
      );
    }

    // Bathroom Sink
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

    // Sink Drain
    final Paint drainPaint = Paint()..color = const Color(0xFF7F8C8D);
    canvas.drawCircle(sinkCenter, 14, drainPaint);

    // Parabolic fluid spray (water + toothpaste foam droplets & mist)
    if (spitProgress > 0.05 && spitProgress < 0.95) {
      final Offset targetSink = Offset(w * 0.5, h * 0.8);
      final double streamLen = spitProgress.clamp(0.0, 1.0);
      final Offset controlPoint = Offset(w * 0.62, (mouthPos.dy + targetSink.dy) / 2);

      final dropPaint = Paint()..color = const Color(0xFF29B6F6).withValues(alpha: 0.90);
      final highlightPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
      final mistPaint = Paint()..color = const Color(0xFF81D4FA).withValues(alpha: 0.70);
      final foamPaint = Paint()..color = Colors.white.withValues(alpha: 0.90);

      // Natural parabolic spray composed of individual elongated droplets & mist
      final int numDrops = (streamLen * 28).toInt();
      for (int i = 0; i < numDrops; i++) {
        final double t = i / 28.0;
        if (t > streamLen) break;

        final double omt = 1.0 - t;
        final double bx = omt * omt * mouthPos.dx + 2 * omt * t * controlPoint.dx + t * t * targetSink.dx;
        final double by = omt * omt * mouthPos.dy + 2 * omt * t * controlPoint.dy + t * t * targetSink.dy + (math.sin(t * math.pi) * 8.0);

        final double dropR = (1.0 - t * 0.45) * 6.5 + math.sin(i * 1.5) * 1.8;
        if (dropR <= 0.5) continue;

        final double dx = 2 * omt * (controlPoint.dx - mouthPos.dx) + 2 * t * (targetSink.dx - controlPoint.dx);
        final double dy = 2 * omt * (controlPoint.dy - mouthPos.dy) + 2 * t * (targetSink.dy - controlPoint.dy);
        final double angle = math.atan2(dy, dx);

        final bool isFoamDrop = i % 3 == 0;

        canvas.save();
        canvas.translate(bx, by);
        canvas.rotate(angle);
        final Rect dropRect = Rect.fromCenter(
          center: Offset.zero,
          width: dropR * 2.2,
          height: dropR * 1.2,
        );
        canvas.drawOval(dropRect, isFoamDrop ? foamPaint : dropPaint);
        canvas.drawCircle(Offset(-dropR * 0.35, -dropR * 0.2), dropR * 0.35, highlightPaint);
        canvas.restore();

        if (i % 2 == 0) {
          final double sprayOffX = math.sin(i * 2.3) * (dropR * 1.4);
          final double sprayOffY = math.cos(i * 1.9) * (dropR * 1.4);
          canvas.drawCircle(Offset(bx + sprayOffX, by + sprayOffY), 1.5 + (i % 3), isFoamDrop ? foamPaint : mistPaint);
        }
      }
    }

    // Splash droplets and foam in the sink
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
  final Color color;

  _WavePainter({
    required this.waveAnimation,
    required this.fillLevel,
    this.color = const Color(0xFF29B6F6),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (fillLevel <= 0.0) return;

    final double w = size.width;
    final double h = size.height;
    final double targetHeight = h * fillLevel;

    final Paint wavePaint = Paint()
      ..color = color
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
    return oldDelegate.waveAnimation != waveAnimation ||
        oldDelegate.fillLevel != fillLevel ||
        oldDelegate.color != color;
  }
}

class _ParticlesPainter extends CustomPainter {
  final List<_FoamBubble> bubbles;
  final List<_Sparkle> sparkles;

  _ParticlesPainter({required this.bubbles, required this.sparkles});

  @override
  void paint(Canvas canvas, Size size) {
    final bubblePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    final bubbleStroke = Paint()
      ..color = Colors.blue.shade200.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (var b in bubbles) {
      if (b.life > 0) {
        bubblePaint.color = Colors.white.withValues(alpha: b.life * 0.6);
        bubbleStroke.color = Colors.blue.shade200.withValues(alpha: b.life * 0.4);
        canvas.drawCircle(b.position, b.radius, bubblePaint);
        canvas.drawCircle(b.position, b.radius, bubbleStroke);
      }
    }

    final sparklePaint = Paint()..style = PaintingStyle.fill;
    for (var s in sparkles) {
      final double progress = s.progress;
      final double alpha = (progress < 0.5 ? progress * 2 : (1.0 - progress) * 2).clamp(0.0, 1.0);
      sparklePaint.color = s.color.withValues(alpha: alpha);

      if (s.isStar) {
        _drawStar(canvas, s.position, s.size * (1.0 - progress * 0.3), sparklePaint);
      } else {
        canvas.drawCircle(s.position, s.size * (1.0 - progress), sparklePaint);
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final double angle = i * (math.pi * 2 / 5) - math.pi / 2;
      final double innerAngle = angle + (math.pi / 5);
      final double ox = center.dx + math.cos(angle) * size;
      final double oy = center.dy + math.sin(angle) * size;
      final double ix = center.dx + math.cos(innerAngle) * (size * 0.4);
      final double iy = center.dy + math.sin(innerAngle) * (size * 0.4);

      if (i == 0) {
        path.moveTo(ox, oy);
      } else {
        path.lineTo(ox, oy);
      }
      path.lineTo(ix, iy);
    }
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
    for (var c in confetti) {
      canvas.save();
      canvas.translate(c.position.dx, c.position.dy);
      canvas.rotate(c.rotation);

      final paint = Paint()
        ..color = c.color
        ..style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: c.size, height: c.size * 0.5),
        paint,
      );
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
