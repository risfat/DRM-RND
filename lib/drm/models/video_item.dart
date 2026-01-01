enum DrmType { vdocipher, fairplay }

class VideoItem {
  final String title;
  final String thumbnailUrl;
  final String durationLabel;
  final DrmType drmType;
  final String videoId;

  const VideoItem({
    required this.title,
    required this.thumbnailUrl,
    required this.durationLabel,
    required this.drmType,
    required this.videoId,
  });

  Map<String, String> toMap() {
    return {
      'title': title,
      'thumbnail': thumbnailUrl,
      'duration': durationLabel,
      'source': drmType.name,
      'videoId': videoId,
    };
  }

  factory VideoItem.fromMap(Map<String, String> map) {
    final drmTypeStr = map['source'] ?? '';
    final drmType = DrmType.values.firstWhere(
      (e) => e.name == drmTypeStr,
      orElse: () => DrmType.vdocipher,
    );
    return VideoItem(
      title: map['title'] ?? '',
      thumbnailUrl: map['thumbnail'] ?? '',
      durationLabel: map['duration'] ?? '',
      drmType: drmType,
      videoId: map['videoId'] ?? '',
    );
  }
}
