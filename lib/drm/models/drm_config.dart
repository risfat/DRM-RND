class DrmConfig {
  final String otpEndpoint;
  final String? apiKey;
  final String? customPlayerId;
  final String defaultUserIdentifier;

  const DrmConfig({
    required this.otpEndpoint,
    this.apiKey,
    this.customPlayerId,
    this.defaultUserIdentifier = 'anonymous_user',
  });
}
