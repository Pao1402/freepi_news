class NewsCategory {
  final int id;
  final String name;
  final int count;

  const NewsCategory({
    required this.id,
    required this.name,
    required this.count,
  });

  factory NewsCategory.fromJson(Map<String, dynamic> json) {
    return NewsCategory(
      id: json['id'] as int? ?? 0,
      name: json['name']?.toString() ?? 'Sin nombre',
      count: json['count'] as int? ?? 0,
    );
  }
}