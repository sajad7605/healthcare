import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../widgets/custom_painters.dart';
import '../widgets/squish_pop.dart';

class FlossScreen extends StatefulWidget {
  const FlossScreen({Key? key}) : super(key: key);

  @override
  State<FlossScreen> createState() => _FlossScreenState();
}

class _FlossScreenState extends State<FlossScreen> {
  double _flossY = 160.0; // Vertical position of the floss
  bool _isSuccess = false;

  // Food bug items inside the gap. Positioned at specific Y coordinates
  final List<Map<String, dynamic>> _foodBugs = [
    {'id': 1, 'y': 90.0, 'cleared': false, 'color': Colors.lightGreenAccent.shade700},
    {'id': 2, 'y': 140.0, 'cleared': false, 'color': Colors.redAccent.shade400},
    {'id': 3, 'y': 200.0, 'cleared': false, 'color': Colors.amber.shade700},
  ];

  void _onVerticalDragUpdate(DragUpdateDetails details, double maxHeight) {
    if (_isSuccess) return;

    setState(() {
      // Restrict floss movement within tooth gap boundaries (between Y=50 and Y=250)
      _flossY = (_flossY + details.delta.dy).clamp(50.0, 250.0);

      // Check intersection with food bugs
      for (var bug in _foodBugs) {
        if (!bug['cleared']) {
          final double distance = (_flossY - bug['y']).abs();
          if (distance < 12.0) {
            bug['cleared'] = true;
            _checkVictory();
          }
        }
      }
    });
  }

  void _checkVictory() {
    final allCleared = _foodBugs.every((bug) => bug['cleared']);
    if (allCleared) {
      setState(() {
        _isSuccess = true;
      });
      _showSuccessDialog();
    }
  }

  void _resetGame() {
    setState(() {
      _flossY = 160.0;
      _isSuccess = false;
      for (var bug in _foodBugs) {
        bug['cleared'] = false;
      }
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text(
              'عالی بود دوست من! 🌟',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFA801)),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                SizedBox(
                  height: 100,
                  width: 100,
                  child: CustomPaint(
                    painter: ToothPainter(expression: 'winking'),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'تمام ذره‌های غذا رو با نخ دندان تمیز کردی! دندان‌ها ازت تشکر می‌کنن. 😍',
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
                    _resetGame();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA801),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'بازی دوباره',
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
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFF3E0), // Soft light orange
                Color(0xFFFFF8E1),
              ],
            ),
          ),
          child: SafeArea(
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
                        'بازی با نخ دندان',
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

                // Tutorial instructions
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    'انگشت خودت رو روی نخ دندان بکش و اون رو بین دندان‌ها حرکت بده تا جرم‌ها رو پاک کنی! 🦷',
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

                // Flossing Interactive Board
                Center(
                  child: SizedBox(
                    width: 320,
                    height: 320,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Left giant tooth
                        Positioned(
                          left: 0,
                          top: 40,
                          child: CustomPaint(
                            size: const Size(120, 150),
                            painter: ToothPainter(expression: _isSuccess ? 'happy' : 'dizzy'),
                          ),
                        ),

                        // Right giant tooth
                        Positioned(
                          right: 0,
                          top: 40,
                          child: CustomPaint(
                            size: const Size(120, 150),
                            painter: ToothPainter(expression: _isSuccess ? 'winking' : 'dizzy'),
                          ),
                        ),

                        // Food Bugs positioned in the central gap (X=140 to 180)
                        ..._foodBugs.map((bug) {
                          if (bug['cleared']) {
                            // Shrink scale-out animation when cleared
                            return Positioned(
                              left: 140,
                              top: bug['y'],
                              child: AnimatedScale(
                                scale: 0.0,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutBack,
                                child: _buildFoodBug(bug['color']),
                              ),
                            );
                          }
                          return Positioned(
                            left: 140,
                            top: bug['y'],
                            child: _buildFoodBug(bug['color']),
                          );
                        }).toList(),

                        // The draggable Floss line
                        Positioned(
                          left: 40,
                          top: _flossY,
                          child: GestureDetector(
                            onVerticalDragUpdate: (details) => _onVerticalDragUpdate(details, 300.0),
                            child: SizedBox(
                              width: 240,
                              height: 40,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // The white floss string thread
                                  Container(
                                    height: 6,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(3),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFFA801).withOpacity(0.5),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Left anchor clip handle
                                  Positioned(
                                    left: 0,
                                    child: Container(
                                      width: 16,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFA801),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  // Right anchor clip handle
                                  Positioned(
                                    right: 0,
                                    child: Container(
                                      width: 16,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFA801),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
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
                ),

                const Spacer(),

                // Reset game button in UI
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: SquishPopButton(
                    onTap: _resetGame,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFFA801).withOpacity(0.3), width: 1.5),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh, color: Color(0xFFFFA801)),
                          SizedBox(width: 8),
                          Text(
                            'شروع مجدد بازی',
                            style: TextStyle(
                              color: Color(0xFFFFA801),
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
        ),
      ),
    );
  }

  // Cute Food Bug widget
  Widget _buildFoodBug(Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Monster Eyes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Center(
                  child: Container(width: 3, height: 3, decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle)),
                ),
              ),
              const SizedBox(width: 3),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Center(
                  child: Container(width: 3, height: 3, decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle)),
                ),
              ),
            ],
          ),
          // Teeth/spikes of bug
          Positioned(
            bottom: 4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (index) => Container(
                  width: 3,
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
