import 'dart:io';
import 'package:flutter/material.dart' hide Badge;
import 'package:image_picker/image_picker.dart';
import '../widgets/custom_painters.dart';
import '../widgets/squish_pop.dart';
import '../api/healthcare_api.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController =
      PageController(viewportFraction: 0.82);
  int _currentIndex = 0;

  List<TeethPhoto> _photos = [];
  List<Badge> _badges = [];
  bool _isLoadingPhotos = true;
  bool _isLoadingBadges = true;
  bool _isUploading = false;

  // Tab: 0 = photos, 1 = badges
  int _tab = 0;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadData();
  }

  Future<void> _loadData() async {
    final child = HealthcareApi.instance.currentChild;
    if (child == null) {
      setState(() {
        _isLoadingPhotos = false;
        _isLoadingBadges = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لطفاً ابتدا وارد حساب کاربری شوید.')),
        );
      }
      return;
    }

    try {
      final photosResult = await HealthcareApi.instance.children
          .getTeethPhotos(child.id);
      if (mounted) {
        setState(() {
          _photos = photosResult;
          _isLoadingPhotos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPhotos = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('خطا در بارگذاری عکس‌ها')),
        );
      }
    }

    try {
      final badgesResult = await HealthcareApi.instance.children
          .getUnlockedBadges(child.id);
      if (mounted) {
        setState(() {
          _badges = badgesResult;
          _isLoadingBadges = false;
        });
        _animController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingBadges = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final source = await _showPickerDialog();
    if (source == null) return;

    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (pickedFile == null) return;

    final child = HealthcareApi.instance.currentChild;
    if (child == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final photo = await HealthcareApi.instance.children.uploadToothPhoto(
        child.id,
        photoFile: File(pickedFile.path),
        title: 'عکس دندون ${DateTime.now().day}/${DateTime.now().month}',
      );
      setState(() {
        _photos.insert(0, photo);
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('عکس با موفقیت آپلود شد! 📸'),
            backgroundColor: Color(0xFF2ECC71),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در آپلود: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    }
  }

  Future<ImageSource?> _showPickerDialog() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'انتخاب تصویر',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _PickerOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'دوربین',
                      color: const Color(0xFF2ECC71),
                      onTap: () => Navigator.pop(context, ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PickerOption(
                      icon: Icons.photo_library_rounded,
                      label: 'گالری',
                      color: const Color(0xFFF368E0),
                      onTap: () => Navigator.pop(context, ImageSource.gallery),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deletePhoto(TeethPhoto photo) async {
    final child = HealthcareApi.instance.currentChild;
    if (child == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('حذف عکس'),
          content: const Text('آیا مطمئنی می‌خوای این عکس رو حذف کنی؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('نه'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('بله', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    try {
      await HealthcareApi.instance.children.deleteToothPhoto(
          child.id, photo.id);
      setState(() {
        _photos.removeWhere((p) => p.id == photo.id);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در حذف: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animController.dispose();
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
              colors: [Color(0xFFFCE4EC), Color(0xFFFFF8F9)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // App Bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SquishPopButton(
                        onTap: () => Navigator.of(context).pop(),
                        child: const CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(Icons.arrow_back,
                              color: Color(0xFF2C3E50)),
                        ),
                      ),
                      const Text(
                        'آلبوم دندونی من',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      SquishPopButton(
                        onTap: _isUploading ? null : _pickAndUploadPhoto,
                        child: CircleAvatar(
                          backgroundColor: const Color(0xFFF368E0),
                          child: _isUploading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.add_a_photo_rounded,
                                  color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tabs
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _TabButton(
                          label: 'عکس‌های دندون',
                          icon: Icons.photo_camera_rounded,
                          isSelected: _tab == 0,
                          onTap: () => setState(() => _tab = 0),
                          count: _photos.length,
                        ),
                        _TabButton(
                          label: 'مدال‌های افتخار',
                          icon: Icons.emoji_events_rounded,
                          isSelected: _tab == 1,
                          onTap: () => setState(() => _tab = 1),
                          count: _badges.length,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Content
                Expanded(
                  child: _tab == 0
                      ? _buildPhotosTab()
                      : _buildBadgesTab(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotosTab() {
    if (_isLoadingPhotos) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFF368E0)),
      );
    }

    if (_photos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: CustomPaint(
                painter: ToothPainter(expression: 'winking'),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'هنوز عکسی آپلود نکردی! 📸',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'از دوربین یا گالری عکس دندونت رو بگیر',
              style: TextStyle(color: Color(0xFF57606F), fontSize: 14),
            ),
            const SizedBox(height: 24),
            SquishPopButton(
              onTap: _pickAndUploadPhoto,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF368E0), Color(0xFFFF9FF3)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF368E0).withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_a_photo_rounded,
                        color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'اولین عکسم رو بگیر!',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) =>
                setState(() => _currentIndex = index),
            itemCount: _photos.length,
            itemBuilder: (context, index) {
              final photo = _photos[index];
              final isSelected = _currentIndex == index;

              return AnimatedScale(
                scale: isSelected ? 1.0 : 0.9,
                duration: const Duration(milliseconds: 300),
                child: AnimatedRotation(
                  turns: isSelected ? 0 : (index > _currentIndex ? 0.02 : -0.02),
                  duration: const Duration(milliseconds: 300),
                  child: GestureDetector(
                    onLongPress: () => _deletePhoto(photo),
                    child: _buildPhotoCard(photo),
                  ),
                ),
              );
            },
          ),
        ),
        // Indicator dots
        if (_photos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _photos.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentIndex == index
                        ? const Color(0xFFF368E0)
                        : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'برای حذف، روی عکس نگه دار 🗑️',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoCard(TeethPhoto photo) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              child: Image.network(
                photo.photoUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: const Color(0xFFFCE4EC),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFF368E0),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stack) => Container(
                  color: const Color(0xFFFCE4EC),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image_rounded,
                            color: Color(0xFFF368E0), size: 48),
                        SizedBox(height: 8),
                        Text('خطا در بارگذاری'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                Text(
                  photo.title.isEmpty ? 'عکس دندونی 🦷' : photo.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  '${photo.createdAt.year}/${photo.createdAt.month}/${photo.createdAt.day}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF57606F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesTab() {
    if (_isLoadingBadges) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFFD700)),
      );
    }

    if (_badges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: CustomPaint(
                painter: ToothPainter(expression: 'happy'),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'هنوز مدالی نگرفتی! 🏅',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'با انجام فعالیت‌های دندونی مدال کسب کن',
              style: TextStyle(color: Color(0xFF57606F), fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'مدال‌های افتخاری که به دست آوردی! 🏆',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF57606F),
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.82),
            itemCount: _badges.length,
            itemBuilder: (context, index) {
              final badge = _badges[index];
              Color badgeColor;
              try {
                badgeColor = Color(
                  int.parse(badge.badgeColor.replaceAll('#', '0xFF')),
                );
              } catch (_) {
                badgeColor = const Color(0xFFFFD700);
              }
              return AnimatedScale(
                scale: 1.0,
                duration: const Duration(milliseconds: 300),
                child: _buildBadgeCard(badge, badgeColor),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeCard(Badge badge, Color badgeColor) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    size: 64,
                    color: Color(0xFFFFD700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '🏅',
                    style: const TextStyle(fontSize: 32),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    badge.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    badge.description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF57606F),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'تاریخ: ${badge.unlockedAt.year}/${badge.unlockedAt.month}/${badge.unlockedAt.day}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF95A5A6),
                    ),
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

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final int count;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF368E0) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.3)
                        : const Color(0xFFF368E0).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFFF368E0),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PickerOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
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
