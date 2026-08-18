import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/news_post.dart';

class ReadingHistoryService {
  static const String _historyKey = 'reading_history';

  Future<List<NewsPost>> getHistory() async {
    final preferences = await SharedPreferences.getInstance();
    final savedHistory = preferences.getStringList(_historyKey) ?? [];

    final history = <NewsPost>[];

    for (final item in savedHistory) {
      try {
        final decodedItem = jsonDecode(item);

        if (decodedItem is Map<String, dynamic>) {
          history.add(
            NewsPost.fromLocalJson(decodedItem),
          );
        }
      } catch (_) {
        // Ignora registros dañados.
      }
    }

    return history;
  }

  Future<void> addPost(NewsPost post) async {
    final preferences = await SharedPreferences.getInstance();
    final history = await getHistory();

    history.removeWhere(
      (savedPost) => savedPost.id == post.id,
    );

    history.insert(0, post);

    // Conservamos únicamente las últimas 50 noticias leídas.
    if (history.length > 50) {
      history.removeRange(50, history.length);
    }

    final encodedHistory = history
        .map(
          (savedPost) => jsonEncode(savedPost.toJson()),
        )
        .toList();

    await preferences.setStringList(
      _historyKey,
      encodedHistory,
    );
  }

  Future<void> removePost(int postId) async {
    final preferences = await SharedPreferences.getInstance();
    final history = await getHistory();

    history.removeWhere(
      (post) => post.id == postId,
    );

    final encodedHistory = history
        .map(
          (post) => jsonEncode(post.toJson()),
        )
        .toList();

    await preferences.setStringList(
      _historyKey,
      encodedHistory,
    );
  }

  Future<void> clearHistory() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_historyKey);
  }
}