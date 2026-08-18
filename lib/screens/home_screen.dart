import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/news_provider.dart';
import '../widgets/news_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  final FocusNode _searchFocusNode = FocusNode();

  final ScrollController _scrollController =
      ScrollController();

  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_handleScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      context.read<NewsProvider>().initialize();
    });
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final newsProvider = context.read<NewsProvider>();

    if (newsProvider.isLoading ||
        newsProvider.isLoadingMore ||
        !newsProvider.hasMorePosts) {
      return;
    }

    final position = _scrollController.position;

    if (position.pixels >=
        position.maxScrollExtent - 300) {
      newsProvider.loadMorePosts();
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();

    _searchDebounce = Timer(
      const Duration(milliseconds: 500),
      () async {
        if (!mounted) {
          return;
        }

        final query = value.trim();
        final newsProvider = context.read<NewsProvider>();

        // Evita repetir exactamente la misma búsqueda.
        if (query == newsProvider.searchQuery) {
          return;
        }

        if (query.isEmpty) {
          await newsProvider.clearSearch();
        } else {
          await newsProvider.searchPosts(query);
        }
      },
    );
  }

  Future<void> _search() async {
    _searchDebounce?.cancel();

    final query = _searchController.text.trim();

    _searchFocusNode.unfocus();

    final newsProvider = context.read<NewsProvider>();

    if (query == newsProvider.searchQuery) {
      return;
    }

    if (query.isEmpty) {
      await newsProvider.clearSearch();
      return;
    }

    await newsProvider.searchPosts(query);
  }

  Future<void> _clearSearch() async {
    _searchDebounce?.cancel();

    _searchController.clear();
    _searchFocusNode.unfocus();

    await context.read<NewsProvider>().clearSearch();
  }

  Future<void> _refreshPosts() async {
    final newsProvider = context.read<NewsProvider>();

    await newsProvider.loadPosts(
      search: newsProvider.searchQuery,
      categoryId: newsProvider.selectedCategoryId,
      reset: true,
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();

    _searchController.dispose();
    _searchFocusNode.dispose();

    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final newsProvider = context.watch<NewsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Freepi News'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              enabled: !newsProvider.isLoading,
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Buscar noticias...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: newsProvider.isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : _searchController.text.isNotEmpty ||
                            newsProvider.searchQuery.isNotEmpty
                        ? IconButton(
                            tooltip: 'Limpiar búsqueda',
                            onPressed: _clearSearch,
                            icon: const Icon(Icons.close),
                          )
                        : IconButton(
                            tooltip: 'Buscar',
                            onPressed: _search,
                            icon: const Icon(
                              Icons.arrow_forward,
                            ),
                          ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),

          SizedBox(
            height: 56,
            child: Builder(
              builder: (context) {
                if (newsProvider.isLoadingCategories &&
                    newsProvider.categories.isEmpty) {
                  return const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  );
                }

                if (newsProvider.categoriesErrorMessage !=
                        null &&
                    newsProvider.categories.isEmpty) {
                  return Center(
                    child: TextButton.icon(
                      onPressed:
                          newsProvider.loadCategories,
                      icon: const Icon(Icons.refresh),
                      label: const Text(
                        'Reintentar categorías',
                      ),
                    ),
                  );
                }

                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: const Text('Todas'),
                        selected: newsProvider
                                .selectedCategoryId ==
                            null,
                        onSelected: newsProvider.isLoading
                            ? null
                            : (_) {
                                newsProvider
                                    .selectCategory(null);
                              },
                      ),
                    ),
                    ...newsProvider.categories.map(
                      (category) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            right: 8,
                          ),
                          child: ChoiceChip(
                            label: Text(category.name),
                            selected: newsProvider
                                    .selectedCategoryId ==
                                category.id,
                            onSelected:
                                newsProvider.isLoading
                                    ? null
                                    : (_) {
                                        newsProvider
                                            .selectCategory(
                                          category.id,
                                        );
                                      },
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),

          if (newsProvider.isLoading)
            const LinearProgressIndicator(),

          if (newsProvider.isShowingCachedData)
            Container(
              width: double.infinity,
              margin:
                  const EdgeInsets.fromLTRB(16, 4, 16, 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_off_outlined),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      newsProvider.lastUpdated == null
                          ? 'Mostrando noticias guardadas '
                              'sin conexión.'
                          : 'Sin conexión. Última '
                              'actualización: '
                              '${DateFormat(
                                'dd/MM/yyyy HH:mm',
                              ).format(
                                newsProvider.lastUpdated!
                                    .toLocal(),
                              )}',
                    ),
                  ),
                  IconButton(
                    tooltip: 'Reintentar conexión',
                    onPressed: newsProvider.isLoading
                        ? null
                        : _refreshPosts,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),

          if (newsProvider.searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Resultados para: '
                  '"${newsProvider.searchQuery}"',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),

          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshPosts,
              child: Builder(
                builder: (context) {
                  if (newsProvider.isLoading &&
                      newsProvider.posts.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (newsProvider.errorMessage != null &&
                      newsProvider.posts.isEmpty) {
                    return ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 120),
                        const Icon(
                          Icons.cloud_off_outlined,
                          size: 70,
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 24,
                          ),
                          child: Text(
                            newsProvider.errorMessage!,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: FilledButton.icon(
                            onPressed:
                                newsProvider.isLoading
                                    ? null
                                    : _refreshPosts,
                            icon:
                                const Icon(Icons.refresh),
                            label:
                                const Text('Reintentar'),
                          ),
                        ),
                      ],
                    );
                  }

                  if (newsProvider.posts.isEmpty) {
                    return ListView(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 150),
                        const Icon(
                          Icons.search_off_outlined,
                          size: 70,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          newsProvider.searchQuery.isEmpty
                              ? 'No hay noticias disponibles.'
                              : 'No se encontraron noticias.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  }

                  final showFooter =
                      newsProvider.isLoadingMore ||
                          newsProvider.loadMoreError !=
                              null;

                  return ListView.builder(
                    controller: _scrollController,
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    itemCount:
                        newsProvider.posts.length +
                            (showFooter ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >=
                          newsProvider.posts.length) {
                        if (newsProvider.loadMoreError !=
                            null) {
                          return Padding(
                            padding:
                                const EdgeInsets.all(24),
                            child: Center(
                              child: Column(
                                mainAxisSize:
                                    MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons
                                        .cloud_off_outlined,
                                    size: 36,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    newsProvider
                                        .loadMoreError!,
                                    textAlign:
                                        TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  FilledButton.icon(
                                    onPressed: newsProvider
                                            .isLoadingMore
                                        ? null
                                        : () {
                                            newsProvider
                                                .loadMorePosts();
                                          },
                                    icon: const Icon(
                                      Icons.refresh,
                                    ),
                                    label: const Text(
                                      'Reintentar',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child:
                                CircularProgressIndicator(),
                          ),
                        );
                      }

                      final post =
                          newsProvider.posts[index];

                      return NewsCard(post: post);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}