import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safe_device/safe_device.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:vdocipher_flutter/vdocipher_flutter.dart';
import 'models/video_item.dart';
import 'providers/drm_player_provider.dart';
import 'services/vdocipher_service.dart';
import 'widgets/watermark_overlay.dart';

class DrmPlayerScreen extends StatefulWidget {
  final List<VideoItem> videos;
  final String otpEndpoint;
  final String? apiKey;

  const DrmPlayerScreen({
    super.key,
    required this.videos,
    required this.otpEndpoint,
    this.apiKey,
  });

  @override
  State<DrmPlayerScreen> createState() => _DrmPlayerScreenState();
}

class _DrmPlayerScreenState extends State<DrmPlayerScreen>
    with WidgetsBindingObserver {
  VdoPlayerController? _vdoPlayerController;
  int _currentVideoIndex = 0;
  bool _isSafeStatus = true;

  late final DrmPlayerProvider _provider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _provider = DrmPlayerProvider(
      drmService: VdoCipherService(
        otpEndpoint: widget.otpEndpoint,
        apiKey: widget.apiKey,
      ),
    );
    _runInitializationSequence();
  }

  Future<void> _runInitializationSequence() async {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      final isSafe = await _checkDeviceSafety();
      if (!mounted) return;
      setState(() {
        _isSafeStatus = isSafe;
      });
      if (isSafe) {
        await _initializeScreenProtection();
        await _loadCurrentVideo();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSafeStatus = false;
      });
      _showErrorDialog('Initialization failed: ${e.toString()}');
    }
  }

  Future<bool> _checkDeviceSafety() async {
    final isJailBroken = await SafeDevice.isJailBroken;
    final isRealDevice = await SafeDevice.isRealDevice;
    if (isJailBroken || !isRealDevice) {
      if (!mounted) return false;
      final message = isJailBroken
          ? 'This device is jailbroken/rooted. Playback is blocked.'
          : 'Emulators are not allowed for DRM content.';
      _showErrorDialog(message);
      return false;
    }
    return true;
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Security Check Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _initializeScreenProtection() async {
    try {
      await ScreenProtector.preventScreenshotOn();
      await ScreenProtector.protectDataLeakageWithBlur();
      ScreenProtector.addListener(() => _handleScreenshotDetected(), (
        isCapturing,
      ) {
        if (isCapturing) {
          _vdoPlayerController?.pause();
          _showRecordingWarning();
        }
      });
    } catch (e) {
      // Log error but don't fail the entire initialization
      print('Screen protection initialization failed: $e');
    }
  }

  void _handleScreenshotDetected() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Screenshot detected!'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showRecordingWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Screen recording detected!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _disableScreenProtection() async {
    await ScreenProtector.preventScreenshotOff();
    await ScreenProtector.protectDataLeakageOff();
    ScreenProtector.removeListener();
  }

  Future<void> _loadCurrentVideo() async {
    try {
      if (!mounted) return;
      final video = widget.videos[_currentVideoIndex];
      await _provider.loadVideo(video);
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Failed to load video: ${e.toString()}');
    }
  }

  void _playVideo(int index) {
    if (!_isSafeStatus) return;
    if (_currentVideoIndex == index) return;
    setState(() {
      _currentVideoIndex = index;
    });
    _vdoPlayerController?.dispose();
    _vdoPlayerController = null;
    _loadCurrentVideo();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ScreenProtector.preventScreenshotOn();
      ScreenProtector.protectDataLeakageWithBlur();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      // _vdoPlayerController?.pause();
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
    _vdoPlayerController?.dispose();
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Secure DRM Player'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: const [
          Icon(Icons.security, color: Colors.green),
          SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 11,
            child: Container(
              color: Colors.black,
              child: _isSafeStatus
                  ? ListenableBuilder(
                      listenable: _provider,
                      builder: (_, __) {
                        switch (_provider.state) {
                          case DrmPlayerState.loading:
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          case DrmPlayerState.error:
                            return Center(
                              child: Text(
                                _provider.errorMessage ?? 'Unknown error',
                                style: const TextStyle(color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                            );
                          case DrmPlayerState.ready:
                            final auth = _provider.auth;
                            if (auth == null) {
                              return const Center(
                                child: Text(
                                  'Authentication data missing',
                                  style: TextStyle(color: Colors.white),
                                ),
                              );
                            }
                            return Stack(
                              children: [
                                Positioned.fill(
                                  child: VdoPlayer(
                                    embedInfo: EmbedInfo.streaming(
                                      otp: auth.otp,
                                      playbackInfo: auth.playbackInfo,
                                      embedInfoOptions: const EmbedInfoOptions(
                                        autoplay: true,
                                      ),
                                    ),
                                    onPlayerCreated: (controller) {
                                      if (mounted) {
                                        _vdoPlayerController = controller;
                                      }
                                    },
                                    onFullscreenChange: (_) {},
                                    onError: (vdoError) {
                                      if (!mounted) return;
                                      // Access provider via widget's property
                                      _provider.setError(
                                        DrmPlayerState.error,
                                        vdoError.toString(),
                                      );
                                    },
                                  ),
                                ),
                                const Positioned.fill(
                                  child: IgnorePointer(
                                    child: WatermarkOverlay(),
                                  ),
                                ),
                              ],
                            );
                          case DrmPlayerState.idle:
                            return const Center(
                              child: Text(
                                'Select a video to play',
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                        }
                      },
                    )
                  : const Center(
                      child: Icon(Icons.lock, color: Colors.red, size: 48),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12.0, right: 12, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.videos[_currentVideoIndex].title,
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
          Expanded(
            child: ListView.builder(
              itemCount: widget.videos.length,
              itemBuilder: (context, index) {
                final video = widget.videos[index];
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
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Image.network(
                                video.thumbnailUrl,
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
                                  video.durationLabel,
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
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                video.title,
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
