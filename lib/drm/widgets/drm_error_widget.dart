import 'package:flutter/material.dart';
import '../models/drm_error.dart';

class DrmErrorWidget extends StatelessWidget {
  final DrmError error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const DrmErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getErrorColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getErrorColor().withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getErrorIcon(), color: _getErrorColor(), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  error.title,
                  style: TextStyle(
                    color: _getErrorColor(),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close, size: 20),
                  color: Colors.grey[600],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            error.message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          if (error.technicalDetails != null) ...[
            const SizedBox(height: 8),
            ExpansionTile(
              title: const Text(
                'Technical Details',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    error.technicalDetails!,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (error.statusCode != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getErrorColor().withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Status Code: ${error.statusCode}',
                style: TextStyle(
                  color: _getErrorColor(),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          if (onRetry != null && error.isRetryable) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getErrorColor(),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getErrorColor() {
    switch (error.type) {
      case DrmErrorType.network:
      case DrmErrorType.timeout:
        return Colors.orange;
      case DrmErrorType.authentication:
      case DrmErrorType.security:
        return Colors.red;
      case DrmErrorType.platform:
      case DrmErrorType.configuration:
        return Colors.purple;
      case DrmErrorType.server:
        return Colors.deepOrange;
      case DrmErrorType.unknown:
        return Colors.grey;
    }
  }

  IconData _getErrorIcon() {
    switch (error.type) {
      case DrmErrorType.network:
        return Icons.wifi_off;
      case DrmErrorType.timeout:
        return Icons.timer_off;
      case DrmErrorType.authentication:
        return Icons.lock;
      case DrmErrorType.platform:
        return Icons.device_unknown;
      case DrmErrorType.security:
        return Icons.security;
      case DrmErrorType.configuration:
        return Icons.settings;
      case DrmErrorType.server:
        return Icons.dns;
      case DrmErrorType.unknown:
        return Icons.error_outline;
    }
  }
}

class DrmErrorDialog extends StatelessWidget {
  final DrmError error;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const DrmErrorDialog({
    super.key,
    required this.error,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: DrmErrorWidget(
          error: error,
          onRetry: onRetry,
          onDismiss: onDismiss ?? () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  static void show(
    BuildContext context, {
    required DrmError error,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    showDialog(
      context: context,
      barrierDismissible: onDismiss != null,
      builder: (context) => DrmErrorDialog(
        error: error,
        onRetry: onRetry,
        onDismiss: onDismiss ?? () => Navigator.of(context).pop(),
      ),
    );
  }
}
