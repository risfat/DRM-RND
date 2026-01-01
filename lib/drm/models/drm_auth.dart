class DrmAuth {
  final String otp;
  final String playbackInfo;

  const DrmAuth({required this.otp, required this.playbackInfo});

  factory DrmAuth.fromJson(Map<String, dynamic> json) {
    return DrmAuth(
      otp: json['otp'] as String,
      playbackInfo: json['playbackInfo'] as String,
    );
  }

  Map<String, String> toJson() {
    return {'otp': otp, 'playbackInfo': playbackInfo};
  }
}
