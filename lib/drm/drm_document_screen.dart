import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'models/drm_error.dart';
import 'services/drm_security_service.dart';
import 'widgets/watermark_overlay.dart';
import 'widgets/drm_error_widget.dart';
import 'services/network_service.dart';

/// A secure PDF viewer screen that prevents:
/// 1. Screenshots and screen recording.
/// 2. Text copying and selection.
/// 3. Unauthorized downloads (no UI option).
/// 4. Analog holes (via dynamic watermark).
class DrmDocumentScreen extends StatefulWidget {
  final String title;
  final String url;
  final String password;
  final String userIdentifier; // Used for the watermark

  const DrmDocumentScreen({
    super.key,
    required this.title,
    required this.url,
    required this.password,
    required this.userIdentifier,
  });

  @override
  State<DrmDocumentScreen> createState() => _DrmDocumentScreenState();
}

class _DrmDocumentScreenState extends State<DrmDocumentScreen> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  bool _isDeviceSafe = true;
  bool _isLoading = false;
  DrmError? _drmError;
  final _security = DrmSecurityService();

  @override
  void initState() {
    super.initState();
    _initSecureMode();
  }

  Future<void> _initSecureMode() async {
    try {
      // Check internet connectivity first
      final hasConnection = await NetworkService.hasInternetConnection(
        useCache: false,
      );
      if (!hasConnection) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _drmError = DrmError.network(
              message:
                  'No internet connection. Please check your network settings and try again.',
            );
          });
        }
        return;
      }

      setState(() => _isLoading = true);
      _drmError = null;

      await _security.initializeScreenProtection(
        onScreenshotDetected: _handleScreenshotDetected,
        onScreenRecordingStatusChanged: (isCapturing) {
          if (isCapturing) _showRecordingWarning();
        },
      );

      final isSafe = await _security.checkDeviceSafety();
      if (mounted) {
        setState(() => _isDeviceSafe = isSafe);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _drmError = DrmError.unknown(
            message: 'Failed to initialize secure document viewer.',
            technicalDetails: e.toString(),
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleScreenshotDetected() {
    final error = DrmError.security(
      message: 'Screenshots are prohibited to protect document privacy.',
    );
    DrmErrorDialog.show(context, error: error, onDismiss: () {});
  }

  void _showRecordingWarning() {
    final error = DrmError.security(
      message: 'Screen recording detected. Secure content hidden.',
    );
    DrmErrorDialog.show(context, error: error, onDismiss: () {});
  }

  @override
  void dispose() {
    _security.disableScreenProtection();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_drmError != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Error'),
          actions: const [],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: DrmErrorWidget(
              error: _drmError!,
              onRetry: _drmError!.isRetryable ? _retryInitialization : null,
            ),
          ),
        ),
      );
    }

    if (!_isDeviceSafe) {
      // Trigger critical error dialog after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final error = DrmError.security(
          message:
              'This content cannot be viewed on a compromised or emulated device.',
        );
        DrmErrorDialog.show(
          context,
          error: error,
          onDismiss: () => Navigator.of(context).pop(),
        );
      });
      return const Scaffold(backgroundColor: Colors.black);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        // Remove action buttons to ensure no "Download" or "Share" option is available
        actions: const [],
      ),
      body: Stack(
        children: [
          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.8),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),

          // The PDF Viewer
          SfPdfViewer.network(
            widget.url,
            key: _pdfViewerKey,
            password: widget.password,
            enableTextSelection: false,
            enableDoubleTapZooming: true,
            canShowPaginationDialog: false,
            canShowScrollHead: false,
            canShowScrollStatus: false,
            onDocumentLoadFailed: (details) {
              setState(() {
                _isLoading = false;
                _drmError = DrmError.server(
                  message: 'Failed to load document: ${details.description}',
                  technicalDetails: details.description,
                );
              });
            },
          ),

          // Anti-Analog Hole Watermark Overlay
          IgnorePointer(
            child: WatermarkOverlay(
              text: widget.userIdentifier,
              textColor: Colors.white60,
            ),
          ),

          // Custom Overlay to block long-press or other interactions if necessary
          // (SfPdfViewer handles most, but we can add more layers here)
        ],
      ),
    );
  }

  void _retryInitialization() {
    _initSecureMode();
  }
}
