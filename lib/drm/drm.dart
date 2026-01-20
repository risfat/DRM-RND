import 'package:flutter/material.dart';
import 'models/drm_config.dart';
import 'models/video_item.dart';
import 'drm_player_screen.dart';
import 'drm_document_screen.dart';
import 'services/drm_security_service.dart';

export 'models/video_item.dart';
export 'models/drm_config.dart';
export 'models/drm_auth.dart';
export 'drm_player_screen.dart';
export 'drm_document_screen.dart';

class Drm {
  static DrmConfig? _config;
  static final DrmSecurityService security = DrmSecurityService();

  /// Initialize the DRM module with global configuration.
  static void init({required DrmConfig config}) {
    _config = config;
  }

  static DrmConfig get config {
    if (_config == null) {
      throw Exception('DRM Module not initialized. Call Drm.init() first.');
    }
    return _config!;
  }

  /// Opens the DRM Video Player.
  static Future<void> openPlayer(
    BuildContext context, {
    required List<VideoItem> videos,
    String? otpEndpoint,
    String? apiKey,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DrmPlayerScreen(
          videos: videos,
          otpEndpoint: otpEndpoint ?? config.otpEndpoint,
          apiKey: apiKey ?? config.apiKey,
        ),
      ),
    );
  }

  /// Opens the DRM Document Viewer.
  static Future<void> openDocument(
    BuildContext context, {
    required String title,
    required String url,
    String? password,
    String? userIdentifier,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DrmDocumentScreen(
          title: title,
          url: url,
          password: password ?? '',
          userIdentifier: userIdentifier ?? config.defaultUserIdentifier,
        ),
      ),
    );
  }
}
