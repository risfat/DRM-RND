import '../models/drm_auth.dart';
import '../models/video_item.dart';

abstract class DrmService {
  Future<DrmAuth> fetchAuth({required VideoItem video, int ttlSeconds = 300});

  bool get isPlatformSupported;
}

class DrmServiceException implements Exception {
  final String message;
  final int? statusCode;
  const DrmServiceException(this.message, [this.statusCode]);

  @override
  String toString() => 'DrmServiceException: $message';
}
