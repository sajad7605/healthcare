import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../widgets/custom_painters.dart';
import '../widgets/squish_pop.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;

  // Animation controllers for various elements
  late AnimationController _cloudFloatController;
  late AnimationController _brushingController;
  late AnimationController _breathingController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Cloud floating animation (gentle and slow)
    _cloudFloatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Brushing movement animation (quick back & forth)
    _brushingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Character breathing animation (gentle floating)
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _cloudFloatController.dispose();
    _brushingController.dispose();
    _breathingController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutBack,
      );
    } else {
      Navigator.pushReplacementNamed(context, '/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF00A2E8),
        body: Stack(
          children: [
            // Background Elements (Continuous gently bobbing clouds)
            _buildCloudBackground(),

            // Onboarding Pages
            PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                _buildPageOne(screenWidth),
                _buildPageTwo(screenWidth),
                _buildPageThree(screenWidth),
              ],
            ),

            // Top Header Bar
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Tooth Logo
                  Row(
                    children: [
                      CustomPaint(
                        size: const Size(32, 32),
                        painter: ToothPainter(expression: 'happy'),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'دندون یار',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Skip / Login Button
                  SquishPopButton(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/auth');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white38, width: 1.5),
                      ),
                      child: const Text(
                        'ورود / ثبت نام',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Navigation Area
            Positioned(
              bottom: 40,
              left: 30,
              right: 30,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page Indicators (Dots)
                  Row(
                    children: List.generate(
                      3,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 10,
                        width: _currentPage == index ? 24 : 10,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? Colors.white : Colors.white54,
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: _currentPage == index
                              ? [BoxShadow(color: Colors.white.withValues(alpha: 0.5), blurRadius: 6, spreadRadius: 1)]
                              : null,
                        ),
                      ),
                    ),
                  ),

                  // Next Button
                  SquishPopButton(
                    onTap: _nextPage,
                    child: Container(
                      height: 60,
                      width: 60,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          )
                        ],
                      ),
                      child: Icon(
                        _currentPage == 2 ? Icons.done : Icons.arrow_back_ios_new,
                        color: const Color(0xFF00A2E8),
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Beautiful floating clouds background
  Widget _buildCloudBackground() {
    return AnimatedBuilder(
      animation: _cloudFloatController,
      builder: (context, child) {
        final floatValue = _cloudFloatController.value;
        return Stack(
          children: [
            // Cloud 1
            Positioned(
              top: 80 + (math.sin(floatValue * math.pi * 2) * 10),
              right: -30 + (floatValue * 15),
              child: CustomPaint(
                size: const Size(180, 100),
                painter: CloudPainter(cloudColor: Colors.white.withValues(alpha: 0.2)),
              ),
            ),
            // Cloud 2
            Positioned(
              top: 140 - (math.sin(floatValue * math.pi * 2) * 8),
              left: -50 + ((1 - floatValue) * 20),
              child: CustomPaint(
                size: const Size(220, 120),
                painter: CloudPainter(cloudColor: Colors.white.withValues(alpha: 0.15)),
              ),
            ),
            // Cloud 3
            Positioned(
              top: 240 + (math.cos(floatValue * math.pi * 2) * 12),
              right: 60 - (floatValue * 20),
              child: CustomPaint(
                size: const Size(140, 80),
                painter: CloudPainter(cloudColor: Colors.white.withValues(alpha: 0.1)),
              ),
            ),
          ],
        );
      },
    );
  }

  // Page 1: Three teeth, toothbrush brushing them, foam bubbles
  Widget _buildPageOne(double screenWidth) {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // Animated Brushing Section
          SizedBox(
            height: 250,
            width: screenWidth,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Three teeth standing side by side
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Left Tooth
                    CustomPaint(
                      size: const Size(90, 110),
                      painter: ToothPainter(expression: 'happy'),
                    ),
                    const SizedBox(width: 8),
                    // Center Tooth
                    CustomPaint(
                      size: const Size(100, 120),
                      painter: ToothPainter(expression: 'brushing'),
                    ),
                    const SizedBox(width: 8),
                    // Right Tooth
                    CustomPaint(
                      size: const Size(90, 110),
                      painter: ToothPainter(expression: 'happy'),
                    ),
                  ],
                ),
                // Foam Bubbles
                AnimatedBuilder(
                  animation: _brushingController,
                  builder: (context, child) {
                    final double brushPos = math.sin(_brushingController.value * math.pi * 2);
                    return Stack(
                      children: [
                        Positioned(
                          top: 130 + (brushPos * 5),
                          left: (screenWidth / 2) - 30 + (brushPos * 40),
                          child: _buildBubble(12),
                        ),
                        Positioned(
                          top: 145 - (brushPos * 3),
                          left: (screenWidth / 2) + 10 + (brushPos * 35),
                          child: _buildBubble(8),
                        ),
                        Positioned(
                          top: 125,
                          left: (screenWidth / 2) - 5 + (brushPos * 25),
                          child: _buildBubble(10),
                        ),
                      ],
                    );
                  },
                ),
                // Floating moving Toothbrush
                AnimatedBuilder(
                  animation: _brushingController,
                  builder: (context, child) {
                    final double val = _brushingController.value;
                    final double brushX = math.sin(val * math.pi * 2) * 70;
                    final double brushY = math.cos(val * math.pi * 4) * 8;
                    return Positioned(
                      top: 100 + brushY,
                      left: (screenWidth / 2) - 60 + brushX,
                      child: Transform.rotate(
                        angle: -math.pi / 12 + (math.sin(val * math.pi * 2) * 0.1),
                        child: CustomPaint(
                          size: const Size(120, 120),
                          painter: ToothbrushPainter(mainColor: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          // Description
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                Text(
                  'همدم دندون‌ها باش!',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  'یاد می‌گیریم چجوری دندون‌هامون رو مثل مروارید سفید و درخشان نگه داریم. مسواک زدن یه بازی شیرینه!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // Page 2: Standalone tooth holding toothbrush, with floss and mouthwash around
  Widget _buildPageTwo(double screenWidth) {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // Animated Floating Character Scene
          AnimatedBuilder(
            animation: _breathingController,
            builder: (context, child) {
              final floatY = math.sin(_breathingController.value * math.pi) * 12;
              return SizedBox(
                height: 250,
                width: screenWidth,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Main Tooth character holding toothbrush
                    Transform.translate(
                      offset: Offset(0, floatY),
                      child: CustomPaint(
                        size: const Size(150, 170),
                        painter: ToothPainter(
                          expression: 'winking',
                          hasToothbrush: true,
                          brushAnimationValue: _breathingController.value,
                        ),
                      ),
                    ),
                    // Floating Floss Box (Left)
                    Positioned(
                      left: (screenWidth / 2) - 130,
                      top: 60 - floatY,
                      child: Transform.rotate(
                        angle: 0.15,
                        child: CustomPaint(
                          size: const Size(70, 70),
                          painter: FlossBoxPainter(),
                        ),
                      ),
                    ),
                    // Floating Mouthwash Bottle (Right)
                    Positioned(
                      right: (screenWidth / 2) - 130,
                      top: 50 + floatY,
                      child: Transform.rotate(
                        angle: -0.15,
                        child: CustomPaint(
                          size: const Size(70, 90),
                          painter: MouthwashBottlePainter(),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          // Description
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                Text(
                  'ابزارهای قهرمانی دندون',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  'مسواک، نخ دندان و دهان‌شویه سه تفنگدار محافظ دندون‌ها در برابر میکروب‌های بدجنس هستن!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // Page 3: Happy tooth in front of dental office/posters
  Widget _buildPageThree(double screenWidth) {
    return SafeArea(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // Office Poster Scene
          AnimatedBuilder(
            animation: _breathingController,
            builder: (context, child) {
              final floatY = math.sin(_breathingController.value * math.pi) * 8;
              return SizedBox(
                height: 250,
                width: screenWidth,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Wall Posters (Dentistry basics & generosity)
                    Positioned(
                      left: (screenWidth / 2) - 110,
                      top: 20,
                      child: _buildPoster('بخشندگی دندان', const Color(0xFFFF7675)),
                    ),
                    Positioned(
                      right: (screenWidth / 2) - 110,
                      top: 20,
                      child: _buildPoster('اصول دندان', const Color(0xFF2ECC71)),
                    ),

                    // Cute Office Plant
                    Positioned(
                      right: (screenWidth / 2) - 160,
                      bottom: 20,
                      child: Icon(Icons.yard, size: 50, color: Colors.greenAccent.shade400),
                    ),

                    // Tooth Character standing in front
                    Positioned(
                      bottom: 10 + floatY,
                      child: CustomPaint(
                        size: const Size(130, 150),
                        painter: ToothPainter(expression: 'happy'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          // Description
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                Text(
                  'دانستنی‌های دندانپزشکی',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  'کارهای ساده مثل معاینه و مراقبت‌های دندونپزشکی رو با پوسترها و فیلم‌های بامزه باهم یاد می‌گیریم.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // Helper widget to construct foam bubbles
  Widget _buildBubble(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1),
      ),
    );
  }

  // Helper widget to draw dental posters
  Widget _buildPoster(String title, Color accentColor) {
    return Container(
      width: 90,
      height: 120,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          )
        ],
        border: Border.all(color: const Color(0xFFF1F2F6), width: 2),
      ),
      child: Column(
        children: [
          // Simulated image area in poster
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: CustomPaint(
                  size: const Size(30, 30),
                  painter: ToothPainter(expression: 'happy'),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Poster Title text
          Text(
            title,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// Finished onboarding screen layout
