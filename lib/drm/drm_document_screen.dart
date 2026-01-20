import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'services/drm_security_service.dart';
import 'widgets/watermark_overlay.dart';

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
  final _security = DrmSecurityService();

  @override
  void initState() {
    super.initState();
    _initSecureMode();
  }

  Future<void> _initSecureMode() async {
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
  }

  void _handleScreenshotDetected() {
    _security.showViolationDialog(
      context,
      message: 'Screenshots are prohibited to protect document privacy.',
    );
  }

  void _showRecordingWarning() {
    _security.showViolationDialog(
      context,
      message: 'Screen recording detected. Secure content hidden.',
    );
  }

  @override
  void dispose() {
    _security.disableScreenProtection();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDeviceSafe) {
      // Trigger critical error dialog after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _security.showCriticalError(
          context,
          'This content cannot be viewed on a compromised or emulated device.',
        );
      });
      return const Scaffold(backgroundColor: Colors.black);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        // Remove the action buttons to ensure no "Download" or "Share" option is available
        actions: const [],
      ),
      body: Stack(
        children: [
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
                _isDeviceSafe = false; // Using this state to show error UI
              });
              _security.showViolationDialog(
                context,
                title: 'Loading Failed',
                message: 'Failed to load document: ${details.description}',
              );
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
}
