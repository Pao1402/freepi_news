import 'package:flutter/material.dart';

import '../models/news_post.dart';
import '../services/favorites_service.dart';

class FavoritesProvider extends ChangeNotifier {
  FavoritesProvider({
    FavoritesService? service,
  }) : _service = service ?? FavoritesService();

  final FavoritesService _service;

  final List<NewsPost> _favorites = [];

  bool _isLoading = false;

  List<NewsPost> get favorites => List.unmodifiable(_favorites);

  bool get isLoading => _isLoading;

  int get favoritesCount => _favorites.length;

  Future<void> loadFavorites() async {
    _isLoading = true;
    notifyListeners();

    try {
      final loadedFavorites = await _service.getFavorites();

      _favorites
        ..clear()
        ..addAll(loadedFavorites);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isFavorite(int id) {
    return _favorites.any(
      (favorite) => favorite.id == id,
    );
  }

  Future<void> toggleFavorite(NewsPost post) async {
    await _service.toggleFavorite(post);
    await loadFavorites();
  }

  Future<void> clearFavorites() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.clearFavorites();
      _favorites.clear();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}