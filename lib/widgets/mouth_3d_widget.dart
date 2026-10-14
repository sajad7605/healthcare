import 'package:flutter/material.dart';
import 'package:flutter_cube/flutter_cube.dart' as cube;
import 'squish_pop.dart';

/// Reusable 3D Mouth Viewer Widget using the corrected 3D model
class Mouth3DViewer extends StatefulWidget {
  final double yaw; // In degrees
  final double pitch; // In degrees
  final double zoom;
  final double targetY;
  final bool interactive;
  final String modelPath;
  final bool isAsset;

  const Mouth3DViewer({
    super.key,
    this.yaw = 0.0,
    this.pitch = 0.0,
    this.zoom = 6.8,
    this.targetY = 0.0,
    this.interactive = false,
    this.modelPath = 'assets/models/mouth.obj',
    this.isAsset = true,
  });

  @override
  State<Mouth3DViewer> createState() => _Mouth3DViewerState();
}

class _Mouth3DViewerState extends State<Mouth3DViewer> {
  cube.Scene? _scene;
  cube.Object? _mouthObject;
  bool _isLoading = true;
  double _localYaw = 0.0;
  double _localPitch = 0.0;

  @override
  void initState() {
    super.initState();
    _localYaw = widget.yaw;
    _localPitch = widget.pitch;
  }

  @override
  void didUpdateWidget(covariant Mouth3DViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.interactive) {
      if (oldWidget.pitch != widget.pitch ||
          oldWidget.yaw != widget.yaw ||
          oldWidget.zoom != widget.zoom ||
          oldWidget.targetY != widget.targetY) {
        _localYaw = widget.yaw;
        _localPitch = widget.pitch;
        _applyTransforms();
      }
    }
  }

  void _applyTransforms() {
    if (_mouthObject == null || _scene == null) return;
    _mouthObject!.rotation.setValues(
      _localPitch,
      _localYaw,
      0.0,
    );
    _mouthObject!.updateTransform();
    _scene!.camera.zoom = widget.zoom;
    _scene!.camera.target.setValues(0, widget.targetY, 0);
    _scene!.update();
  }

  @override
  Widget build(BuildContext context) {
    Widget viewer = cube.Cube(
      interactive: false,
      onObjectCreated: (cube.Object object) {
        _mouthObject = object;
        _applyTransforms();
      },
      onSceneCreated: (cube.Scene scene) {
        _scene = scene;
        scene.camera.zoom = widget.zoom;
        scene.camera.target.setValues(0, widget.targetY, 0);

        final mouth = cube.Object(
          fileName: widget.modelPath,
          isAsset: widget.isAsset,
          lighting: false,
          backfaceCulling: false,
        );
        _mouthObject = mouth;
        scene.world.add(mouth);

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        _applyTransforms();
      },
    );

    if (widget.interactive) {
      viewer = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) {
          setState(() {
            _localYaw += details.delta.dx * 0.75;
            _localPitch = (_localPitch - details.delta.dy * 0.75).clamp(-65.0, 65.0);
            _applyTransforms();
          });
        },
        child: viewer,
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        viewer,
        if (_isLoading)
          const Center(
            child: SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00A2E8)),
              ),
            ),
          ),
      ],
    );
  }
}

/// Modal Bottom Sheet allowing the child to inspect and rotate the mouth in 360 degrees
class Mouth3DInspectionSheet extends StatefulWidget {
  const Mouth3DInspectionSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => const Mouth3DInspectionSheet(),
    );
  }

  @override
  State<Mouth3DInspectionSheet> createState() => _Mouth3DInspectionSheetState();
}

class _Mouth3DInspectionSheetState extends State<Mouth3DInspectionSheet> {
  cube.Scene? _scene;
  cube.Object? _mouthObject;
  double _yaw = 0.0;
  double _pitch = 0.0;
  double _zoom = 7.5;
  double _startZoom = 7.5;

  void _applyTransforms() {
    if (_mouthObject == null || _scene == null) return;
    _mouthObject!.rotation.setValues(_pitch, _yaw, 0.0);
    _mouthObject!.updateTransform();
    _scene!.camera.zoom = _zoom;
    _scene!.camera.target.setValues(0, 0, 0);
    _scene!.update();
  }

  void _setPresetView({required double pitch, required double yaw, required double zoom}) {
    setState(() {
      _pitch = pitch;
      _yaw = yaw;
      _zoom = zoom;
      _applyTransforms();
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: screenSize.height * 0.82,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Drag handle
            const SizedBox(height: 12),
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 12),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A2E8).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.view_in_ar_rounded,
                      color: Color(0xFF00A2E8),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'بررسی سه‌بعدی دندان‌ها 🦷',
                          style: TextStyle(
                            fontFamily: 'YekanBakh',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        Text(
                          'انگشتت رو روی دهان بکش تا ۳۶۰ درجه بچرخه!',
                          style: TextStyle(
                            fontFamily: 'YekanBakh',
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SquishPopButton(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, color: Colors.grey, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),

            // 3D Viewport
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFFE8F4FD),
                            Colors.blue.shade50.withValues(alpha: 0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.blue.shade100, width: 1.5),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onScaleStart: (details) {
                            _startZoom = _zoom;
                          },
                          onScaleUpdate: (details) {
                            setState(() {
                              if (details.scale != 1.0) {
                                _zoom = (_startZoom * details.scale).clamp(4.5, 14.0);
                              }
                              _yaw += details.focalPointDelta.dx * 0.75;
                              _pitch = (_pitch - details.focalPointDelta.dy * 0.75).clamp(-65.0, 65.0);
                              _applyTransforms();
                            });
                          },
                          child: cube.Cube(
                            interactive: false,
                            onObjectCreated: (cube.Object object) {
                              _mouthObject = object;
                              _applyTransforms();
                            },
                            onSceneCreated: (cube.Scene scene) {
                              _scene = scene;
                              scene.camera.zoom = _zoom;
                              scene.camera.target.setValues(0, 0, 0);

                              final mouth = cube.Object(
                                fileName: 'assets/models/mouth.obj',
                                isAsset: true,
                                lighting: false,
                                backfaceCulling: false,
                              );
                              _mouthObject = mouth;
                              scene.world.add(mouth);
                              _applyTransforms();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Interactive hint overlay
                  Positioned(
                    top: 12,
                    left: 28,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.touch_app_rounded, size: 14, color: Color(0xFF00A2E8)),
                          SizedBox(width: 4),
                          Text(
                            'چرخش لمسی فعال',
                            style: TextStyle(
                              fontFamily: 'YekanBakh',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00A2E8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Preset View Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPresetChip(
                      icon: Icons.front_hand_rounded,
                      label: 'نمای روبرو',
                      onTap: () => _setPresetView(pitch: 0, yaw: 0, zoom: 7.5),
                    ),
                    const SizedBox(width: 8),
                    _buildPresetChip(
                      icon: Icons.keyboard_arrow_up_rounded,
                      label: 'فک بالا',
                      onTap: () => _setPresetView(pitch: 35, yaw: 0, zoom: 8.5),
                    ),
                    const SizedBox(width: 8),
                    _buildPresetChip(
                      icon: Icons.keyboard_arrow_down_rounded,
                      label: 'فک پایین',
                      onTap: () => _setPresetView(pitch: -35, yaw: 0, zoom: 8.5),
                    ),
                    const SizedBox(width: 8),
                    _buildPresetChip(
                      icon: Icons.arrow_back_rounded,
                      label: 'سمت راست',
                      onTap: () => _setPresetView(pitch: 0, yaw: 45, zoom: 8.0),
                    ),
                    const SizedBox(width: 8),
                    _buildPresetChip(
                      icon: Icons.arrow_forward_rounded,
                      label: 'سمت چپ',
                      onTap: () => _setPresetView(pitch: 0, yaw: -45, zoom: 8.0),
                    ),
                    const SizedBox(width: 8),
                    _buildPresetChip(
                      icon: Icons.refresh_rounded,
                      label: 'تنظیم مجدد',
                      onTap: () => _setPresetView(pitch: 0, yaw: 0, zoom: 7.5),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SquishPopButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F7FD),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFBCE0FD)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF00A2E8)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'YekanBakh',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
