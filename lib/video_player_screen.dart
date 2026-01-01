import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:safe_device/safe_device.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:vdocipher_flutter/vdocipher_flutter.dart';

class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({super.key});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VdoCipherAuth {
  final String otp;
  final String playbackInfo;

  const _VdoCipherAuth({required this.otp, required this.playbackInfo});
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with WidgetsBindingObserver {
  BetterPlayerController? _betterPlayerController;
  VdoPlayerController? _vdoPlayerController;
  EmbedInfo? _vdoEmbedInfo;
  bool _isVdoLoading = false;
  String? _vdoErrorMessage;
  int _currentVideoIndex = 0;
  bool _isSafeStatus = true;

  static const String _vdoCipherOtpEndpoint = String.fromEnvironment(
    'VDOCIPHER_OTP_ENDPOINT',
    defaultValue: 'https://drm-backend-psi.vercel.app/vdocipher/otp',
  );

  final List<Map<String, String>> _videos = [
    {
      'title': 'DRM Video 1',
      'source': 'vdocipher',
      'videoId': 'c5d0d27026fa79a49c1c94655e587f8a',
      'thumbnail':
          'https://storage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg',
      'duration': 'DRM',
    },
    {
      'title': 'DRM Video 2',
      'source': 'vdocipher',
      'videoId': 'YOUR_VDOCIPHER_VIDEO_ID_2',
      'thumbnail':
          'https://storage.googleapis.com/gtv-videos-bucket/sample/images/ElephantsDream.jpg',
      'duration': 'DRM',
    },
    {
      'title': 'DRM Video 3',
      'source': 'vdocipher',
      'videoId': 'YOUR_VDOCIPHER_VIDEO_ID_3',
      'thumbnail':
          'https://storage.googleapis.com/gtv-videos-bucket/sample/images/ElephantsDream.jpg',
      'duration': 'DRM',
    },
    {
      'title': 'DRM Video 4',
      'source': 'vdocipher',
      'videoId': 'YOUR_VDOCIPHER_VIDEO_ID_4',
      'thumbnail':
          'https://storage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerBlazes.jpg',
      'duration': 'DRM',
    },
    {
      'title': 'DRM Video 5',
      'source': 'vdocipher',
      'videoId': 'YOUR_VDOCIPHER_VIDEO_ID_5',
      'thumbnail':
          'https://storage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerEscapes.jpg',
      'duration': 'DRM',
    },
    {
      'title': 'DRM Video 6',
      'source': 'vdocipher',
      'videoId': 'YOUR_VDOCIPHER_VIDEO_ID_6',
      'thumbnail':
          'https://storage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerFun.jpg',
      'duration': 'DRM',
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _runInitializationSequence();
  }

  Future<void> _runInitializationSequence() async {
    // Lock app to portrait initially
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    bool isSafe = await _checkDeviceSafety();
    setState(() {
      _isSafeStatus = isSafe;
    });
    if (isSafe) {
      await _initializeScreenProtection();
      await _initializePlayer();
    }
  }

  bool _isVdoCipherVideo(Map<String, String> video) {
    return video['source'] == 'vdocipher';
  }

  Future<bool> _checkDeviceSafety() async {
    // 1. Check for Jailbreak/Root
    bool isJailBroken = await SafeDevice.isJailBroken;
    // 2. (Optional) Check if it's a physical device for stricter DRM
    bool isRealDevice = await SafeDevice.isRealDevice;

    if (isJailBroken || !isRealDevice) {
      if (!mounted) return false;

      String message = isJailBroken
          ? "This device appears to be Jailbroken or Rooted. Content playback is disabled for security reasons."
          : "This device appears to be an Emulator. Content playback is disabled for security reasons.";

      _showUnsafeDeviceDialog(message);
      return false;
    }
    return true;
  }

  void _showUnsafeDeviceDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          title: const Text("Security Violation"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                if (Platform.isIOS) {
                  exit(0); // Force exit on iOS
                } else {
                  SystemNavigator.pop(); // Standard exit on Android
                }
              },
              child: const Text(
                "Exit App",
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initializeScreenProtection() async {
    // 1. Activates generic protection:
    //    - Android: Sets FLAG_SECURE (Prevents Screenshots & Screen Recording)
    //    - iOS: Adds a secure UITextField (Prevents Screen Recording -> Black Screen)
    await ScreenProtector.preventScreenshotOn();

    // 2. Activates App Switcher protection (iOS specific mostly):
    //    - Shows a blur effect over the app when in the recent apps list.
    await ScreenProtector.protectDataLeakageWithBlur();

    // 3. Listener for Screenshot events (iOS):
    //    - Triggers if the user presses Power + Volume Up.
    //    - Note: On iOS 11+, we can't physically stop the screenshot file from being created
    //      (it's a system right), but 'preventScreenshotOn' hides the content (black/hidden)
    //      in the screenshot for most modern implementations.
    //      If it fails to hide, this listener lets us punish/warn the user.
    ScreenProtector.addListener(
      () {
        _handleScreenshotDetected();
      },
      (isCapturing) {
        // Listener for Screen Recording status change
        if (isCapturing) {
          _betterPlayerController?.pause();
          _vdoPlayerController?.pause();
          _showRecordingWarning();
        }
      },
    );
  }

  void _handleScreenshotDetected() {
    // Show a warning or log the incident
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '⚠️ Screenshot detected! This incident has been reported.',
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showRecordingWarning() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        title: Text("Security Alert"),
        content: Text(
          "Screen recording is not allowed. Playback has been paused.",
        ),
      ),
    );
  }

  Future<void> _disableScreenProtection() async {
    await ScreenProtector.preventScreenshotOff();
    await ScreenProtector.protectDataLeakageOff();
    ScreenProtector.removeListener();
  }

  Future<void> _initializePlayer() async {
    final video = _videos[_currentVideoIndex];
    if (!_isVdoCipherVideo(video)) {
      if (!mounted) return;
      setState(() {
        _vdoEmbedInfo = null;
        _isVdoLoading = false;
        _vdoErrorMessage =
            'All videos must be DRM-protected. Configure this item with a VdoCipher videoId.';
      });
      return;
    }

    await _initializeVdoCipherPlayer(video);
  }

  Future<void> _initializeVdoCipherPlayer(Map<String, String> video) async {
    _betterPlayerController?.dispose();
    _betterPlayerController = null;

    if (!Platform.isAndroid) {
      if (!mounted) return;
      setState(() {
        _vdoEmbedInfo = null;
        _isVdoLoading = false;
        _vdoErrorMessage =
            'VdoCipher Widevine DRM playback is Android-only in this MVP.';
      });
      return;
    }

    final videoId = video['videoId'];
    if (videoId == null ||
        videoId.isEmpty ||
        videoId.startsWith('YOUR_VDOCIPHER_VIDEO_ID')) {
      if (!mounted) return;
      setState(() {
        _vdoEmbedInfo = null;
        _isVdoLoading = false;
        _vdoErrorMessage =
            'Set a valid VdoCipher videoId in the playlist item.';
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isVdoLoading = true;
      _vdoErrorMessage = null;
      _vdoEmbedInfo = null;
    });

    try {
      final auth = await _fetchVdoCipherOtp(videoId: videoId, ttlSeconds: 300);
      final embedInfo = EmbedInfo.streaming(
        otp: auth.otp,
        playbackInfo: auth.playbackInfo,
        embedInfoOptions: const EmbedInfoOptions(autoplay: true),
      );

      if (!mounted) return;
      setState(() {
        _vdoEmbedInfo = embedInfo;
        _isVdoLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVdoLoading = false;
        _vdoErrorMessage = e.toString();
      });
    }
  }

  Future<_VdoCipherAuth> _fetchVdoCipherOtp({
    required String videoId,
    required int ttlSeconds,
  }) async {
    final uri = Uri.parse(_vdoCipherOtpEndpoint);
    final response = await http.post(
      uri,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'videoId': videoId, 'ttl': ttlSeconds}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'OTP endpoint error: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid OTP response JSON');
    }

    final otp = decoded['otp'];
    final playbackInfo = decoded['playbackInfo'];
    if (otp is! String || playbackInfo is! String) {
      throw Exception(
        'OTP response must include string fields: otp, playbackInfo',
      );
    }

    return _VdoCipherAuth(otp: otp, playbackInfo: playbackInfo);
  }

  void _playVideo(int index) {
    if (!_isSafeStatus) return;
    if (_currentVideoIndex == index) return;

    setState(() {
      _currentVideoIndex = index;
      _betterPlayerController?.dispose();
      _betterPlayerController = null;
      _vdoPlayerController?.dispose();
      _vdoPlayerController = null;
      _vdoEmbedInfo = null;
      _isVdoLoading = false;
      _vdoErrorMessage = null;
    });
    _initializePlayer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-enforce protection when coming back to foreground
    if (state == AppLifecycleState.resumed) {
      ScreenProtector.preventScreenshotOn();
      ScreenProtector.protectDataLeakageWithBlur();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      // Pause video when going to background
      _betterPlayerController?.pause();
      _vdoPlayerController?.pause();
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    WidgetsBinding.instance.removeObserver(this);
    _disableScreenProtection();
    _betterPlayerController?.dispose();
    _vdoPlayerController?.dispose();
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
              child: _isSafeStatus
                  ? _isVdoCipherVideo(_videos[_currentVideoIndex])
                        ? (_isVdoLoading
                              ? const Center(child: CircularProgressIndicator())
                              : (_vdoErrorMessage != null
                                    ? Center(
                                        child: Text(
                                          _vdoErrorMessage!,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      )
                                    : (_vdoEmbedInfo != null
                                          ? Stack(
                                              children: [
                                                Positioned.fill(
                                                  child: VdoPlayer(
                                                    embedInfo: _vdoEmbedInfo!,
                                                    onPlayerCreated:
                                                        (controller) {
                                                          _vdoPlayerController =
                                                              controller;
                                                        },
                                                    onFullscreenChange: (_) {},
                                                    onError: (vdoError) {
                                                      if (!mounted) return;
                                                      setState(() {
                                                        _vdoErrorMessage =
                                                            vdoError.toString();
                                                      });
                                                    },
                                                  ),
                                                ),
                                                const Positioned.fill(
                                                  child: IgnorePointer(
                                                    child: WatermarkOverlay(),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : const Center(
                                              child: Text(
                                                'DRM video not initialized',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ))))
                        : (_betterPlayerController != null &&
                                  _betterPlayerController!
                                          .videoPlayerController !=
                                      null
                              ? BetterPlayer(
                                  controller: _betterPlayerController!,
                                )
                              : const Center(
                                  child: CircularProgressIndicator(),
                                ))
                  : const Center(
                      child: Icon(Icons.lock, color: Colors.red, size: 48),
                    ),
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
                                  color: Colors.black.withValues(alpha: 0.8),
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
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Text(
                    "AIT",
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
