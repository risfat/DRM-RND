import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'dart:async';
import '../lib/drm/models/drm_error.dart';
import '../lib/drm/models/video_item.dart';
import '../lib/drm/services/network_service.dart';
import '../lib/drm/services/drm_service.dart';

void main() {
  group('Drm Error Handling Tests', () {
    test('should create network error correctly', () {
      final error = DrmError.network(
        message: 'Connection failed',
        technicalDetails: 'SocketException: Connection refused',
      );

      expect(error.type, DrmErrorType.network);
      expect(error.title, 'Network Error');
      expect(error.message, 'Connection failed');
      expect(error.isRetryable, true);
    });

    test('should create authentication error correctly', () {
      final error = DrmError.authentication(
        message: 'Invalid credentials',
        technicalDetails: '401 Unauthorized',
      );

      expect(error.type, DrmErrorType.authentication);
      expect(error.title, 'Authentication Failed');
      expect(error.message, 'Invalid credentials');
      expect(error.isRetryable, false);
    });

    test('should create timeout error correctly', () {
      final error = DrmError.timeout(
        message: 'Request timed out',
        technicalDetails: 'TimeoutException after 30 seconds',
      );

      expect(error.type, DrmErrorType.timeout);
      expect(error.title, 'Connection Timeout');
      expect(error.message, 'Request timed out');
      expect(error.isRetryable, true);
    });

    test('should create platform error correctly', () {
      final error = DrmError.platform(message: 'Platform not supported');

      expect(error.type, DrmErrorType.platform);
      expect(error.title, 'Platform Not Supported');
      expect(error.message, 'Platform not supported');
      expect(error.isRetryable, false);
    });

    test('should create server error correctly', () {
      final error = DrmError.server(
        message: 'Server error occurred',
        statusCode: 500,
        technicalDetails: 'Internal server error',
      );

      expect(error.type, DrmErrorType.server);
      expect(error.title, 'Server Error');
      expect(error.message, 'Server error occurred');
      expect(error.statusCode, 500);
      expect(error.isRetryable, true);
    });

    test('should create VideoItem correctly', () {
      final video = VideoItem(
        videoId: 'test-video',
        title: 'Test Video',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        durationLabel: '5:00',
        drmType: DrmType.vdocipher,
      );

      expect(video.videoId, 'test-video');
      expect(video.title, 'Test Video');
      expect(video.thumbnailUrl, 'https://example.com/thumb.jpg');
      expect(video.durationLabel, '5:00');
      expect(video.drmType, DrmType.vdocipher);
    });

    test('should create DrmServiceException correctly', () {
      final exception = DrmServiceException('Test error', 404);

      expect(exception.message, 'Test error');
      expect(exception.statusCode, 404);
      expect(exception.toString(), 'DrmServiceException: Test error');
    });
  });

  group('Network Service Tests', () {
    test('should provide appropriate error messages for SocketException', () {
      final socketException = SocketException('Connection refused');
      final message = NetworkService.getErrorMessage(socketException);
      expect(message, contains('Unable to connect to the server'));
    });

    test('should provide appropriate error messages for TimeoutException', () {
      final timeoutException = TimeoutException(
        'Request timeout',
        const Duration(seconds: 30),
      );
      final timeoutMessage = NetworkService.getErrorMessage(timeoutException);
      expect(timeoutMessage, contains('Connection timed out'));
    });

    test('should provide appropriate error messages for HttpException', () {
      final httpException = HttpException('404 Not Found');
      final message = NetworkService.getErrorMessage(httpException);
      expect(message, contains('HTTP error occurred'));
    });

    test('should provide appropriate error messages for FormatException', () {
      final formatException = FormatException('Invalid JSON');
      final message = NetworkService.getErrorMessage(formatException);
      expect(message, contains('Invalid response format'));
    });

    test('should provide generic error message for unknown errors', () {
      final unknownError = Exception('Unknown error');
      final message = NetworkService.getErrorMessage(unknownError);
      expect(message, contains('Network error occurred'));
    });
  });
}
