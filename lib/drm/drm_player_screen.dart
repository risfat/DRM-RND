import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vdocipher_flutter/vdocipher_flutter.dart';
import 'drm.dart';
import 'models/video_item.dart';
import 'providers/drm_player_provider.dart';
import 'services/vdocipher_service.dart';
import 'services/drm_security_service.dart';
import 'widgets/watermark_overlay.dart';

class DrmPlayerScreen extends StatefulWidget {
  final List<VideoItem> videos;
  final String? otpEndpoint;
  final String? apiKey;

  const DrmPlayerScreen({
    super.key,
    required this.videos,
    this.otpEndpoint,
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
  final _security = DrmSecurityService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _provider = DrmPlayerProvider(
      drmService: VdoCipherService(
        otpEndpoint: widget.otpEndpoint ?? Drm.config.otpEndpoint,
        apiKey: widget.apiKey ?? Drm.config.apiKey,
      ),
    );
    _runInitializationSequence();
  }

  Future<void> _runInitializationSequence() async {
    try {
      await _security.setSecureOrientation();

      final isSafe = await _security.checkDeviceSafety();
      if (!mounted) return;

      setState(() {
        _isSafeStatus = isSafe;
      });

      if (isSafe) {
        await _security.initializeScreenProtection(
          onScreenshotDetected: _handleScreenshotDetected,
          onScreenRecordingStatusChanged: (isCapturing) {
            if (isCapturing) {
              _vdoPlayerController?.pause();
              _showRecordingWarning();
            }
          },
        );
        await _loadCurrentVideo();
      } else {
        _security.showCriticalError(
          context,
          'Security check failed. Rooted devices or emulators are not allowed for this secure content.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSafeStatus = false;
      });
      _showErrorDialog('Initialization failed: ${e.toString()}');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Security Check'),
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

  void _handleScreenshotDetected() {
    _security.showViolationDialog(
      context,
      message:
          'Screenshots are strictly prohibited for this content to protect digital rights.',
    );
  }

  void _showRecordingWarning() {
    _security.showViolationDialog(
      context,
      message:
          'Screen recording detected. Playback has been paused to protect content.',
    );
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
      _security.initializeScreenProtection();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _security.resetOrientation();
    _security.disableScreenProtection();
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
                      builder: (_, _) {
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
                                        customPlayerId: "G6PJBZ1OIQypBmWt",
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
