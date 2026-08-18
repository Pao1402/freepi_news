import 'package:flutter/material.dart';

import '../models/news_post.dart';
import '../services/reading_history_service.dart';

class ReadingHistoryProvider extends ChangeNotifier {
  ReadingHistoryProvider({
    ReadingHistoryService? service,
  }) : _service = service ?? ReadingHistoryService();

  final ReadingHistoryService _service;

  final List<NewsPost> _history = [];

  bool _isLoading = false;

  List<NewsPost> get history => List.unmodifiable(_history);

  bool get isLoading => _isLoading;

  int get historyCount => _history.length;

  bool wasRead(int postId) {
    return _history.any(
      (post) => post.id == postId,
    );
  }

  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      final savedHistory = await _service.getHistory();

      _history
        ..clear()
        ..addAll(savedHistory);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPost(NewsPost post) async {
    _history.removeWhere(
      (savedPost) => savedPost.id == post.id,
    );

    _history.insert(0, post);

    if (_history.length > 50) {
      _history.removeRange(50, _history.length);
    }

    notifyListeners();

    await _service.addPost(post);
  }

  Future<void> removePost(int postId) async {
    _history.removeWhere(
      (post) => post.id == postId,
    );

    notifyListeners();

    await _service.removePost(postId);
  }

  Future<void> clearHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.clearHistory();
      _history.clear();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}