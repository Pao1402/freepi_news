class NewsPost {
  const NewsPost({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.content,
    required this.date,
    required this.imageUrl,
    required this.link,
  });

  final int id;
  final String title;
  final String excerpt;
  final String content;
  final DateTime date;
  final String imageUrl;
  final String link;

  factory NewsPost.fromJson(Map<String, dynamic> json) {
    final embedded = json['_embedded'];

    String imageUrl = '';

    if (embedded is Map<String, dynamic>) {
      final featuredMedia = embedded['wp:featuredmedia'];

      if (featuredMedia is List && featuredMedia.isNotEmpty) {
        final media = featuredMedia.first;

        if (media is Map<String, dynamic>) {
          imageUrl = media['source_url']?.toString() ?? '';
        }
      }
    }

    return NewsPost(
      id: json['id'] as int? ?? 0,
      title: _getRenderedText(json['title']),
      excerpt: _getRenderedText(json['excerpt']),
      content: _getRenderedText(json['content']),
      date: DateTime.tryParse(
            json['date']?.toString() ?? '',
          ) ??
          DateTime.now(),
      imageUrl: imageUrl,
      link: json['link']?.toString() ?? '',
    );
  }

  factory NewsPost.fromLocalJson(
    Map<String, dynamic> json,
  ) {
    return NewsPost(
      id: json['id'] as int? ?? 0,
      title: json['title']?.toString() ?? '',
      excerpt: json['excerpt']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      date: DateTime.tryParse(
            json['date']?.toString() ?? '',
          ) ??
          DateTime.now(),
      imageUrl: json['imageUrl']?.toString() ?? '',
      link: json['link']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'excerpt': excerpt,
      'content': content,
      'date': date.toIso8601String(),
      'imageUrl': imageUrl,
      'link': link,
    };
  }

  static String _getRenderedText(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value['rendered']?.toString() ?? '';
    }

    return '';
  }
}