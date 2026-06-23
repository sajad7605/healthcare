import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../widgets/custom_painters.dart';
import '../widgets/squish_pop.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _gridController;
  final List<Animation<double>> _gridAnimations = [];

  final List<Map<String, dynamic>> _gridItems = [
    {
      'title': 'نخ دندان',
      'subtitle': 'تمیزکاری لای دندون‌ها',
      'bgColor': const Color(0xFFFFA801),
      'painter': 'floss',
      'route': '/floss',
    },
    {
      'title': 'مسواک بزن',
      'subtitle': 'بازی مسواک زدن تعاملی',
      'bgColor': const Color(0xFF9B59B6),
      'painter': 'brush',
      'route': '/brushing',
    },
    {
      'title': 'دهان‌شویه',
      'subtitle': 'نفس تازه و خوشبو',
      'bgColor': const Color(0xFF2ECC71),
      'painter': 'mouthwash',
      'route': '/mouthwash',
    },
    {
      'title': 'گالری دندان',
      'subtitle': 'عکس‌های دندونی قشنگ',
      'bgColor': const Color(0xFFF368E0),
      'painter': 'gallery',
      'route': '/gallery',
    },
    {
      'title': 'کارتون‌ها',
      'subtitle': 'آموزش‌های جذاب و بازی',
      'bgColor': const Color(0xFF341F97),
      'painter': 'cartoons',
      'route': '/video',
    },
    {
      'title': 'تنظیمات',
      'subtitle': 'سلامت دندان‌ها',
      'bgColor': const Color(0xFF00D2D3),
      'painter': 'settings',
      'route': '/settings',
    },
  ];

  @override
  void initState() {
    super.initState();

    _gridController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    const double step = 0.15;
    for (int i = 0; i < 6; i++) {
      final double start = i * step;
      final double end = (start + 0.35).clamp(0.0, 1.0);
      _gridAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _gridController,
            curve: Interval(start, end, curve: Curves.easeOutBack),
          ),
        ),
      );
    }

    _gridController.forward();
  }

  @override
  void dispose() {
    _gridController.dispose();
    super.dispose();
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
              colors: [Color(0xFFE3F2FD), Color(0xFFF5F6FA)],
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'سلام دوست من! 👋',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'امروز برای دندون‌هات چیکار کردی؟',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      SquishPopButton(
                        onTap: () {
                          Navigator.pushNamed(context, '/settings');
                        },
                        child: Container(
                          width: 56,
                          height: 56,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF35B8FF),
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
                          child: CustomPaint(
                            painter: ToothPainter(expression: 'winking'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.88,
                          ),
                      itemCount: _gridItems.length,
                      itemBuilder: (context, index) {
                        final item = _gridItems[index];
                        final animation = _gridAnimations[index];

                        return AnimatedBuilder(
                          animation: animation,
                          builder: (context, child) {
                            return Opacity(
                              opacity: animation.value.clamp(0.0, 1.0),
                              child: Transform.translate(
                                offset: Offset(0, (1 - animation.value) * 50),
                                child: child,
                              ),
                            );
                          },
                          child: SquishPopButton(
                            onTap: () {
                              Navigator.pushNamed(context, item['route']);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: item['bgColor'],
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: item['bgColor'].withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    bottom: -20,
                                    right: -20,
                                    child: CircleAvatar(
                                      radius: 60,
                                      backgroundColor: Colors.white.withValues(
                                        alpha: 0.12,
                                      ),
                                    ),
                                  ),

                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['title'],
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),

                                        Text(
                                          item['subtitle'],
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.white.withValues(
                                              alpha: 0.85,
                                            ),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),

                                        const Spacer(),

                                        Expanded(
                                          child: Center(
                                            child: AspectRatio(
                                              aspectRatio: 1.0,
                                              child: CustomPaint(
                                                painter: _getPainter(
                                                  item['painter'],
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
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  CustomPainter _getPainter(String name) {
    switch (name) {
      case 'floss':
        return FlossBoxPainter();
      case 'brush':
        return ToothPainter(expression: 'happy', hasToothbrush: true);
      case 'mouthwash':
        return MouthwashBottlePainter();
      case 'gallery':
        return _SimpleGalleryIconPainter();
      case 'cartoons':
        return _SimplePlayIconPainter();
      case 'settings':
        return _SimpleSettingsIconPainter();
      default:
        return ToothPainter();
    }
  }
}

class _SimpleGalleryIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final framePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(w * 0.1, h * 0.1);
    path.lineTo(w * 0.9, h * 0.15);
    path.lineTo(w * 0.85, h * 0.85);
    path.lineTo(w * 0.15, h * 0.8);
    path.close();
    canvas.drawPath(path, framePaint);

    final picPaint = Paint()
      ..color = const Color(0xFFF368E0).withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final innerPath = Path();
    innerPath.moveTo(w * 0.18, h * 0.18);
    innerPath.lineTo(w * 0.82, h * 0.22);
    innerPath.lineTo(w * 0.78, h * 0.78);
    innerPath.lineTo(w * 0.22, h * 0.74);
    innerPath.close();
    canvas.drawPath(innerPath, picPaint);

    final toothPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.15, toothPaint);
    canvas.drawCircle(
      Offset(w * 0.45, h * 0.5),
      w * 0.05,
      Paint()..color = const Color(0xFF2C3E50),
    );
    canvas.drawCircle(
      Offset(w * 0.55, h * 0.5),
      w * 0.05,
      Paint()..color = const Color(0xFF2C3E50),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SimplePlayIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final screenPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.1, h * 0.2, w * 0.8, h * 0.55),
        const Radius.circular(10),
      ),
      screenPaint,
    );

    final playPaint = Paint()
      ..color = const Color(0xFF341F97)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(w * 0.42, h * 0.35);
    path.lineTo(w * 0.62, h * 0.475);
    path.lineTo(w * 0.42, h * 0.6);
    path.close();
    canvas.drawPath(path, playPaint);

    final basePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(w * 0.42, h * 0.75, w * 0.16, h * 0.08),
      basePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.3, h * 0.82, w * 0.4, h * 0.06),
        const Radius.circular(4),
      ),
      basePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SimpleSettingsIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final platePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.6),
        width: w * 0.7,
        height: h * 0.35,
      ),
      0,
      math.pi,
      false,
      platePaint,
    );

    final applePaint = Paint()
      ..color = const Color(0xFFFF5252)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.42, h * 0.48), w * 0.14, applePaint);

    final leafPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.48, h * 0.33),
        width: w * 0.08,
        height: h * 0.12,
      ),
      leafPaint,
    );

    final bananaPaint = Paint()
      ..color = const Color(0xFFFFEB3B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.1
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(w * 0.62, h * 0.46),
        width: w * 0.18,
        height: h * 0.18,
      ),
      -math.pi / 4,
      math.pi / 1.5,
      false,
      bananaPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
