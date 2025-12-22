import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
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
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(
            errorMessage,
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
    );
    setState(() {});
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
  void dispose() {
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
        title: const Text('DRM Video Player'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
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
                Text(
                  _videos[_currentVideoIndex]['title'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
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
