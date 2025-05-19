class IslamicVideo {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String youtubeId;
  final String category;

  IslamicVideo({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.youtubeId,
    required this.category,
  });

  // Extract YouTube video ID from full URL
  static String extractYoutubeId(String url) {
    RegExp regExp = RegExp(
      r'^.*((youtu.be\/)|(v\/)|(\/u\/\w\/)|(embed\/)|(watch\?))\??v?=?([^#&?]*).*',
      caseSensitive: false,
      multiLine: false,
    );
    String? match = regExp.firstMatch(url)?.group(7);
    return match ?? '';
  }

  // Factory to create from a full YouTube URL
  factory IslamicVideo.fromYoutubeUrl({
    required String id,
    required String title,
    required String description,
    required String youtubeUrl,
    required String category,
  }) {
    String youtubeId = extractYoutubeId(youtubeUrl);
    String thumbnailUrl = 'https://img.youtube.com/vi/$youtubeId/0.jpg';

    return IslamicVideo(
      id: id,
      title: title,
      description: description,
      thumbnailUrl: thumbnailUrl,
      youtubeId: youtubeId,
      category: category,
    );
  }

  // Convert to Map for Firestore (if needed)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'youtubeId': youtubeId,
      'category': category,
    };
  }

  // Create from Map for Firestore (if needed)
  factory IslamicVideo.fromMap(Map<String, dynamic> map) {
    return IslamicVideo(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      youtubeId: map['youtubeId'] ?? '',
      category: map['category'] ?? '',
    );
  }
}
