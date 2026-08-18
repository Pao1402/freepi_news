import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/news_post.dart';

class NewsCacheService {
  static const String _postsKey = 'cached_news_posts';
  static const String _updatedAtKey = 'cached_news_updated_at';

  Future<void> savePosts(List<NewsPost> posts) async {
    final preferences = await SharedPreferences.getInstance();

    final encodedPosts = posts
        .map(
          (post) => jsonEncode(post.toJson()),
        )
        .toList();

    await preferences.setStringList(
      _postsKey,
      encodedPosts,
    );

    await preferences.setString(
      _updatedAtKey,
      DateTime.now().toIso8601String(),
    );
  }

  Future<List<NewsPost>> getPosts() async {
    final preferences = await SharedPreferences.getInstance();
    final encodedPosts = preferences.getStringList(_postsKey) ?? [];

    final posts = <NewsPost>[];

    for (final encodedPost in encodedPosts) {
      try {
        final decodedPost = jsonDecode(encodedPost);

        if (decodedPost is Map<String, dynamic>) {
          posts.add(
            NewsPost.fromLocalJson(decodedPost),
          );
        }
      } catch (_) {
        // Ignora una noticia dañada sin afectar el resto del caché.
      }
    }

    return posts;
  }

  Future<DateTime?> getLastUpdated() async {
    final preferences = await SharedPreferences.getInstance();
    final savedDate = preferences.getString(_updatedAtKey);

    if (savedDate == null) {
      return null;
    }

    return DateTime.tryParse(savedDate);
  }

  Future<void> clearCache() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_postsKey);
    await preferences.remove(_updatedAtKey);
  }
}