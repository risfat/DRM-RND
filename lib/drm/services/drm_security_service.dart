import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safe_device/safe_device.dart';
import 'package:screen_protector/screen_protector.dart';

class DrmSecurityService {
  static final DrmSecurityService _instance = DrmSecurityService._internal();
  factory DrmSecurityService() => _instance;
  DrmSecurityService._internal();

  bool _isProtectionActive = false;
  bool get isProtectionActive => _isProtectionActive;

  /// Checks if the device is safe for DRM content (not rooted, not an emulator).
  Future<bool> checkDeviceSafety() async {
    final isJailBroken = await SafeDevice.isJailBroken;
    final isRealDevice = await SafeDevice.isRealDevice;

    // In development/testing, you might want to allow emulators.
    // However, for production DRM, we usually block them.
    return !isJailBroken && isRealDevice;
  }

  /// Initializes screen protection (prevents screenshots and screen recording).
  Future<void> initializeScreenProtection({
    VoidCallback? onScreenshotDetected,
    Function(bool isCapturing)? onScreenRecordingStatusChanged,
  }) async {
    try {
      await ScreenProtector.preventScreenshotOn();
      await ScreenProtector.protectDataLeakageWithBlur();

      if (onScreenshotDetected != null ||
          onScreenRecordingStatusChanged != null) {
        ScreenProtector.addListener(
          () => onScreenshotDetected?.call(),
          (isCapturing) => onScreenRecordingStatusChanged?.call(isCapturing),
        );
      }

      _isProtectionActive = true;
    } catch (e) {
      debugPrint('DRM: Screen protection initialization failed: $e');
    }
  }

  /// Disables screen protection.
  Future<void> disableScreenProtection() async {
    try {
      await ScreenProtector.preventScreenshotOff();
      await ScreenProtector.protectDataLeakageOff();
      ScreenProtector.removeListener();
      _isProtectionActive = false;
    } catch (e) {
      debugPrint('DRM: Screen protection removal failed: $e');
    }
  }

  /// Sets portrait orientation as required for many DRM scenarios.
  Future<void> setSecureOrientation() async {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  /// Resets orientation to system default.
  Future<void> resetOrientation() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  /// Shows a standard violation dialog when security rules are breached.
  void showViolationDialog(
    BuildContext context, {
    required String message,
    String title = 'Security Violation',
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }

  /// Shows a critical error dialog that returns to the previous screen.
  void showCriticalError(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Secure Access Blocked'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context)
              ..pop()
              ..pop(),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}
