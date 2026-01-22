import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'drm_service.dart';
import '../models/drm_auth.dart';
import '../models/video_item.dart';
import 'network_service.dart';

class VdoCipherService implements DrmService {
  final String otpEndpoint;
  final String? apiKey;

  VdoCipherService({required this.otpEndpoint, this.apiKey});

  @override
  bool get isPlatformSupported => Platform.isAndroid || Platform.isIOS;

  @override
  Future<DrmAuth> fetchAuth({
    required VideoItem video,
    int ttlSeconds = 300,
  }) async {
    if (video.videoId.startsWith('YOUR_VDOCIPHER_VIDEO_ID')) {
      throw DrmServiceException(
        'Set a valid VdoCipher videoId in the playlist item.',
      );
    }

    try {
      final response = await NetworkService.makeRequest(
        otpEndpoint,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (apiKey != null) 'x-api-key': apiKey!,
        },
        body: jsonEncode({'videoId': video.videoId, 'ttl': ttlSeconds}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw DrmServiceException(
          'OTP endpoint error: ${response.statusCode} ${response.body}',
          response.statusCode,
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const DrmServiceException('Invalid OTP response JSON');
      }

      final otp = decoded['otp'];
      final playbackInfo = decoded['playbackInfo'];
      if (otp is! String || playbackInfo is! String) {
        throw const DrmServiceException(
          'OTP response must include string fields: otp, playbackInfo',
        );
      }

      return DrmAuth.fromJson({'otp': otp, 'playbackInfo': playbackInfo});
    } on SocketException catch (e) {
      throw DrmServiceException(
        'Network connection failed: ${NetworkService.getErrorMessage(e)}',
      );
    } on TimeoutException catch (e) {
      throw DrmServiceException(
        'Request timeout: ${NetworkService.getErrorMessage(e)}',
      );
    } catch (e) {
      throw DrmServiceException(
        'Failed to fetch authentication: ${e.toString()}',
      );
    }
  }
}
