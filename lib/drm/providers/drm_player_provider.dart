import 'package:flutter/material.dart';
import '../models/drm_auth.dart';
import '../models/video_item.dart';
import '../services/drm_service.dart';

enum DrmPlayerState { idle, loading, ready, error }

class DrmPlayerProvider extends ChangeNotifier {
  final DrmService drmService;

  DrmPlayerProvider({required this.drmService});

  DrmPlayerState _state = DrmPlayerState.idle;
  DrmPlayerState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  DrmAuth? _auth;
  DrmAuth? get auth => _auth;

  VideoItem? _currentVideo;
  VideoItem? get currentVideo => _currentVideo;

  Future<void> loadVideo(VideoItem video, {int ttlSeconds = 300}) async {
    if (!drmService.isPlatformSupported) {
      _setState(
        DrmPlayerState.error,
        'DRM playback is not supported on this platform.',
      );
      return;
    }

    _setState(DrmPlayerState.loading);
    _currentVideo = video;
    try {
      final auth = await drmService.fetchAuth(
        video: video,
        ttlSeconds: ttlSeconds,
      );
      _auth = auth;
      _setState(DrmPlayerState.ready);
    } catch (e) {
      _setState(DrmPlayerState.error, e.toString());
    }
  }

  void reset() {
    _auth = null;
    _currentVideo = null;
    _errorMessage = null;
    _setState(DrmPlayerState.idle);
  }

  void _setState(DrmPlayerState state, [String? errorMessage]) {
    _state = state;
    _errorMessage = errorMessage;
    notifyListeners();
  }

  void setError(DrmPlayerState state, String errorMessage) {
    _setState(state, errorMessage);
  }
}
