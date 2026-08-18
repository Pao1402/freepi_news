import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/news_post.dart';
import '../providers/favorites_provider.dart';
import '../providers/reading_history_provider.dart';
import '../utils/html_helper.dart';
import '../widgets/favorite_button.dart';

class NewsDetailScreen extends StatefulWidget {
  const NewsDetailScreen({
    super.key,
    required this.post,
  });

  final NewsPost post;

  @override
  State<NewsDetailScreen> createState() =>
      _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  final ScrollController _scrollController = ScrollController();

  static const double _readProgressThreshold = 0.60;

  bool _hasMarkedAsRead = false;
  double _readingProgress = 0;

  NewsPost get post => widget.post;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_handleScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      final historyProvider =
          context.read<ReadingHistoryProvider>();

      _hasMarkedAsRead =
          historyProvider.wasRead(post.id);

      _checkInitialReadingState();

      if (mounted) {
        setState(() {});
      }
    });
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;
    final maxScrollExtent = position.maxScrollExtent;

    if (maxScrollExtent <= 0) {
      _updateReadingProgress(1);
      return;
    }

    final progress = (
      position.pixels / maxScrollExtent
    ).clamp(0.0, 1.0);

    _updateReadingProgress(progress);
  }

  void _checkInitialReadingState() {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position;

    if (position.maxScrollExtent <= 0) {
      _updateReadingProgress(1);
    }
  }

  void _updateReadingProgress(double progress) {
    final normalizedProgress =
        progress.clamp(0.0, 1.0);

    if (mounted &&
        (normalizedProgress - _readingProgress).abs() >
            0.01) {
      setState(() {
        _readingProgress = normalizedProgress;
      });
    }

    if (!_hasMarkedAsRead &&
        normalizedProgress >=
            _readProgressThreshold) {
      _markAsRead();
    }
  }

  Future<void> _markAsRead() async {
    if (_hasMarkedAsRead || !mounted) {
      return;
    }

    _hasMarkedAsRead = true;

    await context
        .read<ReadingHistoryProvider>()
        .addPost(post);

    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Future<void> _toggleFavorite(
    BuildContext context,
  ) async {
    final favoritesProvider =
        context.read<FavoritesProvider>();

    final wasFavorite =
        favoritesProvider.isFavorite(post.id);

    await favoritesProvider.toggleFavorite(post);

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            wasFavorite
                ? 'Noticia eliminada de favoritos'
                : 'Noticia guardada en favoritos',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> _openOriginalArticle(
    BuildContext context,
  ) async {
    final link = post.link.trim();

    if (link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Esta noticia no tiene un enlace disponible.',
          ),
        ),
      );

      return;
    }

    await _openExternalUrl(
      context,
      link,
      failureMessage:
          'No fue posible abrir la noticia.',
    );
  }

  Future<bool> _openHtmlUrl(
    String url,
  ) async {
    final uri = Uri.tryParse(url);

    if (uri == null ||
        !(uri.scheme == 'http' ||
            uri.scheme == 'https')) {
      return false;
    }

    try {
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }

  Future<void> _openExternalUrl(
    BuildContext context,
    String url, {
    required String failureMessage,
  }) async {
    final uri = Uri.tryParse(url);

    if (uri == null ||
        !(uri.scheme == 'http' ||
            uri.scheme == 'https')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El enlace no es válido.',
          ),
        ),
      );

      return;
    }

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failureMessage),
          ),
        );
      }
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(failureMessage),
        ),
      );
    }
  }

  Future<void> _shareArticle(
    BuildContext context,
  ) async {
    final cleanTitle =
        HtmlHelper.parseHtmlString(
          post.title,
        ).trim();

    final cleanExcerpt =
        HtmlHelper.parseHtmlString(
          post.excerpt,
        ).trim();

    final articleLink = post.link.trim();

    final buffer = StringBuffer();

    buffer.writeln(cleanTitle);

    if (cleanExcerpt.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(cleanExcerpt);
    }

    if (articleLink.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(articleLink);
    }

    buffer
      ..writeln()
      ..write(
        'Compartido desde Freepi News',
      );

    try {
      await SharePlus.instance.share(
        ShareParams(
          title: cleanTitle,
          subject: cleanTitle,
          text: buffer.toString(),
        ),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No fue posible compartir la noticia.',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favoritesProvider =
        context.watch<FavoritesProvider>();

    final isFavorite =
        favoritesProvider.isFavorite(post.id);

    final formattedDate = DateFormat(
      'dd/MM/yyyy - HH:mm',
    ).format(post.date.toLocal());

    final cleanTitle =
        HtmlHelper.parseHtmlString(post.title);

    final hasContent =
        post.content.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detalle de noticia',
        ),
        actions: [
          IconButton(
            tooltip: 'Compartir noticia',
            onPressed: () {
              _shareArticle(context);
            },
            icon: const Icon(
              Icons.share_outlined,
            ),
          ),
          IconButton(
            tooltip:
                'Abrir noticia original',
            onPressed:
                post.link.trim().isEmpty
                    ? null
                    : () {
                        _openOriginalArticle(
                          context,
                        );
                      },
            icon: const Icon(
              Icons.open_in_browser,
            ),
          ),
          FavoriteButton(
            isFavorite: isFavorite,
            enabled:
                !favoritesProvider.isLoading,
            onPressed: () {
              _toggleFavorite(context);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize:
              const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: _readingProgress,
            minHeight: 4,
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            if (post.imageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: post.imageUrl,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                placeholder: (
                  context,
                  url,
                ) {
                  return const SizedBox(
                    height: 250,
                    child: Center(
                      child:
                          CircularProgressIndicator(),
                    ),
                  );
                },
                errorWidget: (
                  context,
                  url,
                  error,
                ) {
                  return const SizedBox(
                    height: 250,
                    child: Center(
                      child: Icon(
                        Icons
                            .broken_image_outlined,
                        size: 60,
                      ),
                    ),
                  );
                },
              ),
            Padding(
              padding:
                  const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    cleanTitle,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          fontWeight:
                              FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons
                            .calendar_today_outlined,
                        size: 17,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          formattedDate,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(
                      milliseconds: 250,
                    ),
                    child: _hasMarkedAsRead
                        ? Row(
                            key: const ValueKey(
                              'read-indicator',
                            ),
                            children: [
                              Icon(
                                Icons
                                    .check_circle,
                                size: 18,
                                color: Theme.of(
                                  context,
                                )
                                    .colorScheme
                                    .primary,
                              ),
                              const SizedBox(
                                width: 6,
                              ),
                              Text(
                                'Noticia leída',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  )
                                      .colorScheme
                                      .primary,
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            key: const ValueKey(
                              'reading-indicator',
                            ),
                            'Desplázate por la noticia '
                            'para marcarla como leída',
                            style: Theme.of(
                              context,
                            )
                                .textTheme
                                .bodySmall,
                          ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  if (!hasContent)
                    const Text(
                      'Esta noticia no contiene '
                      'información disponible.',
                    )
                  else
                    HtmlWidget(
                      post.content,
                      textStyle: Theme.of(
                        context,
                      )
                          .textTheme
                          .bodyLarge
                          ?.copyWith(
                            height: 1.6,
                          ),
                      onTapUrl: _openHtmlUrl,
                      renderMode:
                          RenderMode.column,
                    ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _shareArticle(context);
                      },
                      icon: const Icon(
                        Icons.share_outlined,
                      ),
                      label: const Text(
                        'Compartir noticia',
                      ),
                    ),
                  ),
                  if (post.link
                      .trim()
                      .isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          _openOriginalArticle(
                            context,
                          );
                        },
                        icon: const Icon(
                          Icons.language,
                        ),
                        label: const Text(
                          'Leer noticia original',
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}