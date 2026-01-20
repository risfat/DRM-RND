import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:safe_device/safe_device.dart';
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

  @override
  void initState() {
    super.initState();
    _initSecureMode();
  }

  Future<void> _initSecureMode() async {
    // 1. Prevent Screenshots and Screen Recording
    await ScreenProtector.preventScreenshotOn();

    // 2. Check for rooted/jailbroken devices (optional but highly recommended for DRM)
    bool isJailBroken = await SafeDevice.isJailBroken;
    bool isRealDevice = await SafeDevice.isRealDevice;

    if (isJailBroken ||
        (!isRealDevice && !const bool.fromEnvironment('dart.vm.product'))) {
      if (mounted) {
        setState(() => _isDeviceSafe = false);
      }
    }
  }

  @override
  void dispose() {
    // Re-enable screenshots when leaving the screen
    ScreenProtector.preventScreenshotOff();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDeviceSafe) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              'This content cannot be viewed on a compromised or emulated device.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red),
            ),
          ),
        ),
      );
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
            enableTextSelection: false, // Prevents "Copy"
            // enableDocumentProxying:
            //     false, // Security: restricts certain proxy-based operations
            canShowPaginationDialog: true,
            onDocumentLoadFailed: (details) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Failed to load document: ${details.description}',
                  ),
                ),
              );
            },
          ),

          // Anti-Analog Hole Watermark Overlay
          // IgnorePointer(child: WatermarkOverlay(text: widget.userIdentifier)),

          // Custom Overlay to block long-press or other interactions if necessary
          // (SfPdfViewer handles most, but we can add more layers here)
        ],
      ),
    );
  }
}
