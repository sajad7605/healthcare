import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/custom_painters.dart';
import '../widgets/squish_pop.dart';
import '../api/healthcare_api.dart';
import 'intro_video_screen.dart';

class VideoScreen extends StatefulWidget {
  const VideoScreen({super.key});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  List<Video> _videos = [];
  bool _isLoading = true;
  String? _errorMsg;

  final List<Color> _accentColors = const [
    Color(0xFF341F97),
    Color(0xFF10AC84),
    Color(0xFFEE5253),
  ];

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    try {
      final data = await HealthcareApi.instance.educational.listVideos();
      setState(() {
        _videos = data.isEmpty
            ? [
                Video(id: '1', title: 'کارتون آموزشی مسواک زدن 🦷', description: 'آموزش شستن صحیح دندان‌ها', videoUrl: 'assets/video/msvak.mp4', durationSeconds: 60),
                Video(id: '2', title: 'کارتون آموزشی نخ دندان 🧵', description: 'چگونه از نخ دندان استفاده کنیم؟', videoUrl: 'assets/video/nakh.mp4', durationSeconds: 60),
              ]
            : data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _videos = [
          Video(id: '1', title: 'کارتون آموزشی مسواک زدن 🦷', description: 'آموزش شستن صحیح دندان‌ها', videoUrl: 'assets/video/msvak.mp4', durationSeconds: 60),
          Video(id: '2', title: 'کارتون آموزشی نخ دندان 🧵', description: 'چگونه از نخ دندان استفاده کنیم؟', videoUrl: 'assets/video/nakh.mp4', durationSeconds: 60),
        ];
        _isLoading = false;
      });
    }
  }

  void _playVideo(Video video) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IntroVideoScreen(
          videoPath: video.videoUrl.isNotEmpty ? video.videoUrl : 'assets/video/msvak.mp4',
          nextRoute: '',
          title: video.title,
        ),
      ),
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
                Color(0xFFE8EAF6), 
                Color(0xFFF5F5F5),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                
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
                        'کارتون‌های دندونی',
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Text(
                    'کارتون‌های مورد علاقه‌ات رو تماشا کن و یاد بگیر چطور قهرمان دندون‌هات باشی! 🎬',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Color(0xFF57606F),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF341F97),
                          ),
                        )
                      : _errorMsg != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _errorMsg!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF2C3E50),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _isLoading = true;
                                        _errorMsg = null;
                                      });
                                      _loadVideos();
                                    },
                                    child: const Text('تلاش مجدد'),
                                  )
                                ],
                              ),
                            )
                          : _videos.isEmpty
                              ? const Center(
                                  child: Text(
                                    'ویدیویی پیدا نشد 🧐',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  itemCount: _videos.length,
                                  itemBuilder: (context, index) {
                                    final video = _videos[index];
                                    final accent = _accentColors[index % _accentColors.length];
                                    
                                    final minutes = video.durationSeconds ~/ 60;
                                    final remainingSeconds = video.durationSeconds % 60;
                                    final durationText = '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          )
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(24),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () => _playVideo(video),
                                            child: Row(
                                              children: [
                                                
                                                Container(
                                                  width: 110,
                                                  height: 110,
                                                  color: accent.withValues(alpha: 0.12),
                                                  child: video.thumbnailUrl != null && video.thumbnailUrl!.startsWith('http')
                                                      ? Image.network(
                                                          video.thumbnailUrl!,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (c, e, s) => Center(
                                                            child: Icon(
                                                              Icons.play_circle_filled,
                                                              size: 48,
                                                              color: accent,
                                                            ),
                                                          ),
                                                        )
                                                      : Center(
                                                          child: Icon(
                                                            Icons.play_circle_filled,
                                                            size: 48,
                                                            color: accent,
                                                          ),
                                                        ),
                                                ),

                                                Expanded(
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(16.0),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          video.title,
                                                          style: const TextStyle(
                                                            fontSize: 14,
                                                            fontWeight: FontWeight.bold,
                                                            color: Color(0xFF2C3E50),
                                                          ),
                                                        ),
                                                        const SizedBox(height: 12),
                                                        Row(
                                                          children: [
                                                            Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              durationText,
                                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                                            ),
                                                            const SizedBox(width: 16),
                                                            Icon(Icons.video_library_outlined, size: 14, color: Colors.grey.shade500),
                                                            const SizedBox(width: 4),
                                                            Expanded(
                                                              child: Text(
                                                                video.description ?? 'کارتون آموزشی دندان',
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors.grey.shade500,
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
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
}

class _MockVideoPlayerSheet extends StatefulWidget {
  final String title;

  const _MockVideoPlayerSheet({required this.title});

  @override
  State<_MockVideoPlayerSheet> createState() => _MockVideoPlayerSheetState();
}

class _MockVideoPlayerSheetState extends State<_MockVideoPlayerSheet> {
  bool _isPlaying = true;
  double _playbackProgress = 0.05; 
  Timer? _playbackTimer;

  @override
  void initState() {
    super.initState();
    _startPlayback();
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    super.dispose();
  }

  void _startPlayback() {
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (_isPlaying && _playbackProgress < 1.0) {
        setState(() {
          _playbackProgress += 0.005;
        });
      }
    });
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(3)),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              widget.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    )
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    
                    Opacity(
                      opacity: 0.65,
                      child: Center(
                        child: CustomPaint(
                          size: const Size(120, 140),
                          painter: ToothPainter(expression: _isPlaying ? 'happy' : 'winking'),
                        ),
                      ),
                    ),

                    if (!_isPlaying)
                      const CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.white70,
                        child: Icon(Icons.play_arrow, size: 40, color: Colors.black87),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Slider(
              value: _playbackProgress,
              activeColor: const Color(0xFF341F97),
              inactiveColor: Colors.grey.shade300,
              onChanged: (val) {
                setState(() {
                  _playbackProgress = val;
                });
              },
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0:0${(_playbackProgress * 10).toInt()}', style: TextStyle(color: Colors.grey.shade500)),
                Text('۵:۳۰', style: TextStyle(color: Colors.grey.shade500)),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.replay_10, size: 32),
                  onPressed: () {
                    setState(() {
                      _playbackProgress = (_playbackProgress - 0.05).clamp(0.0, 1.0);
                    });
                  },
                ),
                const SizedBox(width: 20),
                SquishPopButton(
                  onTap: _togglePlay,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF341F97),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(Icons.forward_10, size: 32),
                  onPressed: () {
                    setState(() {
                      _playbackProgress = (_playbackProgress + 0.05).clamp(0.0, 1.0);
                    });
                  },
                ),
              ],
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
