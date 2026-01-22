enum DrmErrorType {
  network,
  authentication,
  platform,
  security,
  configuration,
  timeout,
  server,
  unknown,
}

class DrmError {
  final DrmErrorType type;
  final String title;
  final String message;
  final String? technicalDetails;
  final int? statusCode;
  final bool isRetryable;

  const DrmError({
    required this.type,
    required this.title,
    required this.message,
    this.technicalDetails,
    this.statusCode,
    this.isRetryable = true,
  });

  factory DrmError.network({
    required String message,
    String? technicalDetails,
    bool isRetryable = true,
  }) {
    return DrmError(
      type: DrmErrorType.network,
      title: 'Network Error',
      message: message,
      technicalDetails: technicalDetails,
      isRetryable: isRetryable,
    );
  }

  factory DrmError.authentication({
    required String message,
    String? technicalDetails,
  }) {
    return DrmError(
      type: DrmErrorType.authentication,
      title: 'Authentication Failed',
      message: message,
      technicalDetails: technicalDetails,
      isRetryable: false,
    );
  }

  factory DrmError.platform({required String message}) {
    return DrmError(
      type: DrmErrorType.platform,
      title: 'Platform Not Supported',
      message: message,
      isRetryable: false,
    );
  }

  factory DrmError.security({required String message}) {
    return DrmError(
      type: DrmErrorType.security,
      title: 'Security Check Failed',
      message: message,
      isRetryable: false,
    );
  }

  factory DrmError.configuration({required String message}) {
    return DrmError(
      type: DrmErrorType.configuration,
      title: 'Configuration Error',
      message: message,
      isRetryable: false,
    );
  }

  factory DrmError.timeout({
    required String message,
    String? technicalDetails,
  }) {
    return DrmError(
      type: DrmErrorType.timeout,
      title: 'Connection Timeout',
      message: message,
      technicalDetails: technicalDetails,
      isRetryable: true,
    );
  }

  factory DrmError.server({
    required String message,
    int? statusCode,
    String? technicalDetails,
  }) {
    return DrmError(
      type: DrmErrorType.server,
      title: 'Server Error',
      message: message,
      statusCode: statusCode,
      technicalDetails: technicalDetails,
      isRetryable: statusCode != null && statusCode >= 500,
    );
  }

  factory DrmError.unknown({
    required String message,
    String? technicalDetails,
  }) {
    return DrmError(
      type: DrmErrorType.unknown,
      title: 'Unexpected Error',
      message: message,
      technicalDetails: technicalDetails,
      isRetryable: true,
    );
  }

  @override
  String toString() {
    return 'DrmError(type: $type, title: $title, message: $message)';
  }
}
