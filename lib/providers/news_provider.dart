import 'package:flutter/material.dart';

import '../models/news_category.dart';
import '../models/news_post.dart';
import '../services/news_cache_service.dart';
import '../services/wordpress_service.dart';

class NewsProvider extends ChangeNotifier {
  NewsProvider({
    WordPressService? service,
    NewsCacheService? cacheService,
  })  : _service = service ?? WordPressService(),
        _cacheService = cacheService ?? NewsCacheService();

  final WordPressService _service;
  final NewsCacheService _cacheService;

  static const int _postsPerPage = 10;

  final List<NewsPost> _posts = [];
  final List<NewsCategory> _categories = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isLoadingCategories = false;
  bool _hasMorePosts = true;
  bool _isShowingCachedData = false;
  bool _isInitialized = false;

  String? _errorMessage;
  String? _loadMoreError;
  String? _categoriesErrorMessage;

  String _searchQuery = '';
  int? _selectedCategoryId;
  int _currentPage = 0;

  DateTime? _lastUpdated;

  List<NewsPost> get posts => List.unmodifiable(_posts);

  List<NewsCategory> get categories =>
      List.unmodifiable(_categories);

  bool get isLoading => _isLoading;

  bool get isLoadingMore => _isLoadingMore;

  bool get isLoadingCategories => _isLoadingCategories;

  bool get hasMorePosts => _hasMorePosts;

  bool get isShowingCachedData => _isShowingCachedData;

  String? get errorMessage => _errorMessage;

  String? get loadMoreError => _loadMoreError;

  String? get categoriesErrorMessage =>
      _categoriesErrorMessage;

  String get searchQuery => _searchQuery;

  int? get selectedCategoryId => _selectedCategoryId;

  DateTime? get lastUpdated => _lastUpdated;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    _isInitialized = true;

    await loadCachedPosts();

    await Future.wait([
      loadCategories(),
      loadPosts(),
    ]);
  }

  Future<void> loadCachedPosts() async {
    try {
      final cachedPosts = await _cacheService.getPosts();
      final cachedDate =
          await _cacheService.getLastUpdated();

      if (cachedPosts.isEmpty) {
        return;
      }

      _posts
        ..clear()
        ..addAll(cachedPosts);

      _lastUpdated = cachedDate;
      _isShowingCachedData = true;

      notifyListeners();
    } catch (_) {
      /*
       * Si ocurre un error al leer el caché, la aplicación
       * continúa intentando obtener las noticias desde la API.
       */
    }
  }

  Future<void> loadPosts({
    String? search,
    int? categoryId,
    bool clearCategory = false,
    bool reset = true,
  }) async {
    /*
     * Evita ejecutar dos cargas principales al mismo tiempo.
     */
    if (reset && _isLoading) {
      return;
    }

    /*
     * Evita ejecutar varias cargas de paginación y también
     * evita pedir otra página cuando ya llegamos al final.
     */
    if (!reset &&
        (_isLoadingMore || !_hasMorePosts)) {
      return;
    }

    if (reset) {
      if (search != null) {
        _searchQuery = search.trim();
      }

      if (clearCategory) {
        _selectedCategoryId = null;
      } else if (categoryId != null) {
        _selectedCategoryId = categoryId;
      }

      _currentPage = 0;
      _hasMorePosts = true;

      _isLoading = true;
      _isLoadingMore = false;

      _errorMessage = null;
      _loadMoreError = null;
    } else {
      _isLoadingMore = true;
      _loadMoreError = null;
    }

    notifyListeners();

    final nextPage =
        reset ? 1 : _currentPage + 1;

    try {
      final loadedPosts = await _service.getPosts(
        search: _searchQuery,
        categoryId: _selectedCategoryId,
        page: nextPage,
        perPage: _postsPerPage,
      );

      if (reset) {
        _posts
          ..clear()
          ..addAll(loadedPosts);
      } else {
        /*
         * Evita agregar noticias repetidas si la API devuelve
         * algún registro duplicado entre páginas.
         */
        final existingIds =
            _posts.map((post) => post.id).toSet();

        final newPosts = loadedPosts.where(
          (post) => !existingIds.contains(post.id),
        );

        _posts.addAll(newPosts);
      }

      _currentPage = nextPage;

      /*
       * Si la API devuelve menos de 10 registros, significa
       * que ya no existe una página siguiente.
       *
       * Si WordPress devuelve una lista vacía por página
       * inválida, también se establece en false.
       */
      _hasMorePosts =
          loadedPosts.length == _postsPerPage;

      _errorMessage = null;
      _loadMoreError = null;

      final isMainNewsList =
          _searchQuery.isEmpty &&
              _selectedCategoryId == null;

      /*
       * Solamente se guarda en caché la lista principal.
       * No se guardan búsquedas ni filtros por categoría.
       */
      if (isMainNewsList) {
        /*
         * La API respondió correctamente, por lo tanto ya
         * no estamos mostrando únicamente datos guardados.
         */
        _isShowingCachedData = false;

        if (_posts.isNotEmpty) {
          await _cacheService.savePosts(_posts);

          /*
           * Se obtiene la misma fecha que se guardó dentro
           * de NewsCacheService.
           */
          _lastUpdated =
              await _cacheService.getLastUpdated();
        }
      }
    } catch (error) {
      final message = error
          .toString()
          .replaceFirst(
            'Exception: ',
            '',
          );

      if (reset) {
        /*
         * Un error durante la primera página se muestra como
         * un error general.
         */
        _errorMessage = message;

        final isMainNewsList =
            _searchQuery.isEmpty &&
                _selectedCategoryId == null;

        /*
         * El banner de caché solamente aparece si:
         *
         * 1. Falló la carga de la lista principal.
         * 2. Ya existen noticias guardadas.
         * 3. No estamos en una búsqueda o categoría.
         */
        if (_posts.isNotEmpty &&
            isMainNewsList) {
          _isShowingCachedData = true;

          _lastUpdated ??=
              await _cacheService.getLastUpdated();
        }
      } else {
        /*
         * Los errores de paginación no sustituyen la lista
         * ni muestran el error general de conexión.
         *
         * Se muestran únicamente al final de las noticias.
         */
        _loadMoreError = message;
      }
    } finally {
      _isLoading = false;
      _isLoadingMore = false;

      notifyListeners();
    }
  }

  Future<void> loadMorePosts() async {
    if (_isLoading ||
        _isLoadingMore ||
        !_hasMorePosts) {
      return;
    }

    await loadPosts(reset: false);
  }

  Future<void> loadCategories() async {
    if (_isLoadingCategories) {
      return;
    }

    _isLoadingCategories = true;
    _categoriesErrorMessage = null;

    notifyListeners();

    try {
      final loadedCategories =
          await _service.getCategories();

      _categories
        ..clear()
        ..addAll(loadedCategories);

      _categoriesErrorMessage = null;
    } catch (error) {
      _categoriesErrorMessage = error
          .toString()
          .replaceFirst(
            'Exception: ',
            '',
          );
    } finally {
      _isLoadingCategories = false;

      notifyListeners();
    }
  }

  Future<void> searchPosts(
    String query,
  ) async {
    await loadPosts(
      search: query,
      reset: true,
    );
  }

  Future<void> clearSearch() async {
    await loadPosts(
      search: '',
      reset: true,
    );
  }

  Future<void> selectCategory(
    int? categoryId,
  ) async {
    if (categoryId == null) {
      await loadPosts(
        clearCategory: true,
        reset: true,
      );

      return;
    }

    await loadPosts(
      categoryId: categoryId,
      reset: true,
    );
  }

  Future<void> clearNewsCache() async {
    await _cacheService.clearCache();

    _lastUpdated = null;
    _isShowingCachedData = false;

    notifyListeners();
  }
}