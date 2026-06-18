import 'package:flutter/material.dart';
import '../widgets/custom_painters.dart';
import '../widgets/squish_pop.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({Key? key}) : super(key: key);

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.82);
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _galleryCards = [
    {
      'title': 'قهرمان مسواک زدن! 🦸‍♂️',
      'desc': 'یک هفته مسواک زدن منظم و بدون فراموشی در صبح و شب.',
      'badgeColor': const Color(0xFFFF7675),
      'toothExpr': 'happy',
    },
    {
      'title': 'اولین دندون افتاده! 🦷✨',
      'desc': 'یک دندون شیری افتاد و جا برای رشد دندون‌های دائمی محکم باز شد.',
      'badgeColor': const Color(0xFFF39C12),
      'toothExpr': 'winking',
    },
    {
      'title': 'معاینه طلایی دندانپزشک 🩺',
      'desc': 'ملاقات با دکتر دندانپزشک مهربان بدون کوچک‌ترین ترس و نگرانی.',
      'badgeColor': const Color(0xFF2ECC71),
      'toothExpr': 'happy',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
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
              colors: [
                Color(0xFFFCE4EC), // Light pink gradient
                Color(0xFFFFF8F9),
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
                        'آلبوم موفقیت‌های من',
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
                const Text(
                  'کارت‌های افتخاری که تا الان به دست آوردی! 🏆',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF57606F),
                  ),
                ),

                const SizedBox(height: 30),

                // Carousel Slider
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    itemCount: _galleryCards.length,
                    itemBuilder: (context, index) {
                      final card = _galleryCards[index];
                      final isSelected = _currentIndex == index;

                      return AnimatedRotation(
                        turns: isSelected ? 0 : (index > _currentIndex ? 0.02 : -0.02),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        child: AnimatedScale(
                          scale: isSelected ? 1.0 : 0.9,
                          duration: const Duration(milliseconds: 300),
                          child: _buildGalleryCard(card),
                        ),
                      );
                    },
                  ),
                ),

                // Indicator dots
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _galleryCards.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentIndex == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentIndex == index ? const Color(0xFFF368E0) : Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(4),
                        ),
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

  Widget _buildGalleryCard(Map<String, dynamic> card) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white, width: 4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Graphic Area
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: card['badgeColor'].withOpacity(0.12),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Center(
                child: SizedBox(
                  width: 140,
                  height: 160,
                  child: CustomPaint(
                    painter: ToothPainter(expression: card['toothExpr']),
                  ),
                ),
              ),
            ),
          ),

          // Detail Area
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    card['title'],
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: card['badgeColor'],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    card['desc'],
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF57606F),
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
