import 'dart:async';
import 'dart:math';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with WidgetsBindingObserver {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  int _currentVideoIndex = 0;

  final List<Map<String, String>> _videos = [
    {
      'title': 'Big Buck Bunny',
      'url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      'thumbnail':
          'https://storage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg',
      'duration': '9:56',
    },
    {
      'title': 'Elephant Dream',
      'url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
      'thumbnail':
          'https://storage.googleapis.com/gtv-videos-bucket/sample/images/ElephantsDream.jpg',
      'duration': '10:53',
    },
    {
      'title': 'For Bigger Blazes',
      'url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      'thumbnail':
          'https://storage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerBlazes.jpg',
      'duration': '0:15',
    },
    {
      'title': 'For Bigger Escapes',
      'url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
      'thumbnail':
          'https://storage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerEscapes.jpg',
      'duration': '0:15',
    },
    {
      'title': 'For Bigger Fun',
      'url':
          'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
      'thumbnail':
          'https://storage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerFun.jpg',
      'duration': '1:00',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enableScreenProtection();
    _initializePlayer();
  }

  Future<void> _enableScreenProtection() async {
    // Prevent screenshot
    await ScreenProtector.preventScreenshotOn();
    // Protect data leakage (iOS feature mostly, shows black screen in app switcher)
    await ScreenProtector.protectDataLeakageWithBlur();
  }

  Future<void> _disableScreenProtection() async {
    await ScreenProtector.preventScreenshotOff();
    await ScreenProtector.protectDataLeakageOff();
  }

  Future<void> _initializePlayer() async {
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(_videos[_currentVideoIndex]['url']!),
    );
    await _videoPlayerController.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: false,
      aspectRatio: 16 / 9,
      allowPlaybackSpeedChanging: false,
      allowFullScreen: true,
      // The overlay persists in fullscreen mode
      overlay: const WatermarkOverlay(),
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(
            errorMessage,
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
    );
    if (mounted) setState(() {});
  }

  void _playVideo(int index) {
    if (_currentVideoIndex == index) return;

    setState(() {
      _currentVideoIndex = index;
      _chewieController?.dispose();
      _videoPlayerController.dispose();
      _chewieController = null;
    });
    _initializePlayer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Auto-pause and obscure if user switches apps
    if (state == AppLifecycleState.resumed) {
      ScreenProtector.preventScreenshotOn();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _chewieController?.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disableScreenProtection();
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Secure Player (DRM)'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: const [
          Icon(Icons.security, color: Colors.green),
          SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Video Player Area
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Colors.black,
              child:
                  _chewieController != null &&
                      _chewieController!
                          .videoPlayerController
                          .value
                          .isInitialized
                  ? Chewie(controller: _chewieController!)
                  : const Center(child: CircularProgressIndicator()),
            ),
          ),

          // Video Info
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _videos[_currentVideoIndex]['title'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Chip(
                      label: Text("AIT", style: TextStyle(fontSize: 10)),
                      backgroundColor: Colors.white10,
                      labelPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "Protected Content • do not distribute",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const Divider(color: Colors.grey),
              ],
            ),
          ),

          // Playlist
          Expanded(
            child: ListView.builder(
              itemCount: _videos.length,
              itemBuilder: (context, index) {
                final video = _videos[index];
                final isPlaying = index == _currentVideoIndex;

                return InkWell(
                  onTap: () => _playVideo(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    color: isPlaying ? Colors.grey[900] : Colors.black,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thumbnail placeholder
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Image.network(
                                video['thumbnail']!,
                                width: 120,
                                height: 68,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      width: 120,
                                      height: 68,
                                      color: Colors.grey[800],
                                      child: const Icon(
                                        Icons.play_circle_outline,
                                        color: Colors.white,
                                      ),
                                    ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  video['duration'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Title and info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                video['title']!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isPlaying ? Colors.blue : Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (isPlaying)
                                const Text(
                                  'Now Playing',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A self-contained widget that bounces a watermark around the available space.
/// We use this as an 'overlay' in Chewie so it persists in FullScreen mode.
class WatermarkOverlay extends StatefulWidget {
  const WatermarkOverlay({super.key});

  @override
  State<WatermarkOverlay> createState() => _WatermarkOverlayState();
}

class _WatermarkOverlayState extends State<WatermarkOverlay> {
  Timer? _animTimer;
  final Random _random = Random();

  // Normalized positions (0.0 to 1.0) to be independent of screen size
  double _topPct = 0.1;
  double _leftPct = 0.1;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() {
    _animTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {
        // Move to a random position
        // Keep some padding so it doesn't clip (0.1 to 0.8 range)
        _topPct = 0.1 + _random.nextDouble() * 0.7;
        _leftPct = 0.1 + _random.nextDouble() * 0.7;
      });
    });
  }

  @override
  void dispose() {
    _animTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Positioned(
              top: _topPct * constraints.maxHeight,
              left: _leftPct * constraints.maxWidth,
              child: Opacity(
                opacity: 0.5,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Text(
                    "AIT-2323",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white24,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
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
}
