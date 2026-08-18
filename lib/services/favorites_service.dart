import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/news_post.dart';

class FavoritesService {
  static const String _key = 'favorite_posts';

  Future<List<NewsPost>> getFavorites() async {
    final preferences = await SharedPreferences.getInstance();
    final jsonList = preferences.getStringList(_key) ?? [];

    final favorites = <NewsPost>[];

    for (final item in jsonList) {
      try {
        final decodedItem = jsonDecode(item);

        if (decodedItem is Map<String, dynamic>) {
          favorites.add(
            NewsPost.fromLocalJson(decodedItem),
          );
        }
      } catch (_) {
        // Ignora registros dañados.
      }
    }

    return favorites;
  }

  Future<void> toggleFavorite(NewsPost post) async {
    final preferences = await SharedPreferences.getInstance();
    final favorites = await getFavorites();

    final exists = favorites.any(
      (favorite) => favorite.id == post.id,
    );

    if (exists) {
      favorites.removeWhere(
        (favorite) => favorite.id == post.id,
      );
    } else {
      favorites.add(post);
    }

    final jsonList = favorites
        .map(
          (favorite) => jsonEncode(favorite.toJson()),
        )
        .toList();

    await preferences.setStringList(_key, jsonList);
  }

  Future<void> clearFavorites() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_key);
  }
}