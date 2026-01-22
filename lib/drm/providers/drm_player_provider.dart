import 'package:flutter/material.dart';
import '../models/drm_auth.dart';
import '../models/video_item.dart';
import '../models/drm_error.dart';
import '../services/drm_service.dart';

enum DrmPlayerState { idle, loading, ready, error }

class DrmPlayerProvider extends ChangeNotifier {
  final DrmService drmService;

  DrmPlayerProvider({required this.drmService});

  DrmPlayerState _state = DrmPlayerState.idle;
  DrmPlayerState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  DrmError? _drmError;
  DrmError? get drmError => _drmError;

  DrmAuth? _auth;
  DrmAuth? get auth => _auth;

  VideoItem? _currentVideo;
  VideoItem? get currentVideo => _currentVideo;

  Future<void> loadVideo(VideoItem video, {int ttlSeconds = 300}) async {
    if (!drmService.isPlatformSupported) {
      final error = DrmError.platform(
        message: 'DRM playback is not supported on this platform.',
      );
      _setErrorState(error);
      return;
    }

    _setState(DrmPlayerState.loading);
    _currentVideo = video;
    _drmError = null;

    try {
      final auth = await drmService.fetchAuth(
        video: video,
        ttlSeconds: ttlSeconds,
      );
      _auth = auth;
      _setState(DrmPlayerState.ready);
    } on DrmServiceException catch (e) {
      final error = _mapDrmServiceException(e);
      _setErrorState(error);
    } catch (e) {
      final error = DrmError.unknown(
        message: 'An unexpected error occurred while loading the video.',
        technicalDetails: e.toString(),
      );
      _setErrorState(error);
    }
  }

  DrmError _mapDrmServiceException(DrmServiceException exception) {
    final message = exception.message.toLowerCase();

    if (message.contains('network') || message.contains('connection')) {
      return DrmError.network(
        message:
            'Unable to connect to the video service. Please check your internet connection.',
        technicalDetails: exception.message,
      );
    } else if (message.contains('timeout')) {
      return DrmError.timeout(
        message: 'The request timed out. Please try again.',
        technicalDetails: exception.message,
      );
    } else if (message.contains('otp') || message.contains('authentication')) {
      return DrmError.authentication(
        message: 'Failed to authenticate with the video service.',
        technicalDetails: exception.message,
      );
    } else if (exception.statusCode != null) {
      if (exception.statusCode! >= 500) {
        return DrmError.server(
          message:
              'The video service is currently unavailable. Please try again later.',
          statusCode: exception.statusCode,
          technicalDetails: exception.message,
        );
      } else if (exception.statusCode! == 401 || exception.statusCode! == 403) {
        return DrmError.authentication(
          message: 'You are not authorized to access this content.',
          technicalDetails: exception.message,
        );
      } else {
        return DrmError.server(
          message: 'Server error occurred. Please try again.',
          statusCode: exception.statusCode,
          technicalDetails: exception.message,
        );
      }
    } else {
      return DrmError.unknown(
        message: 'An error occurred while loading the video.',
        technicalDetails: exception.message,
      );
    }
  }

  void reset() {
    _auth = null;
    _currentVideo = null;
    _errorMessage = null;
    _drmError = null;
    _setState(DrmPlayerState.idle);
  }

  void _setState(DrmPlayerState state, [String? errorMessage]) {
    _state = state;
    _errorMessage = errorMessage;
    notifyListeners();
  }

  void _setErrorState(DrmError error) {
    _state = DrmPlayerState.error;
    _errorMessage = error.message;
    _drmError = error;
    notifyListeners();
  }

  void setError(DrmPlayerState state, String errorMessage) {
    _setState(state, errorMessage);
  }

  void retryLoadVideo({int ttlSeconds = 300}) {
    if (_currentVideo != null) {
      loadVideo(_currentVideo!, ttlSeconds: ttlSeconds);
    }
  }
}
