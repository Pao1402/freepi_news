import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/news_post.dart';
import '../providers/favorites_provider.dart';
import '../providers/reading_history_provider.dart';
import '../screens/news_detail_screen.dart';
import '../utils/html_helper.dart';
import 'favorite_button.dart';

class NewsCard extends StatelessWidget {
  const NewsCard({
    super.key,
    required this.post,
  });

  final NewsPost post;

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = context.watch<FavoritesProvider>();
    final historyProvider = context.watch<ReadingHistoryProvider>();

    final isFavorite = favoritesProvider.isFavorite(post.id);
    final wasRead = historyProvider.wasRead(post.id);

    final formattedDate = DateFormat(
      'dd/MM/yyyy',
    ).format(post.date.toLocal());

    final cleanTitle = HtmlHelper.parseHtmlString(post.title);
    final cleanExcerpt = HtmlHelper.parseHtmlString(post.excerpt);

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return NewsDetailScreen(post: post);
              },
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.imageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: post.imageUrl,
                width: double.infinity,
                height: 190,
                fit: BoxFit.cover,
                placeholder: (context, url) {
                  return const SizedBox(
                    height: 190,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                },
                errorWidget: (context, url, error) {
                  return const SizedBox(
                    height: 190,
                    child: Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 55,
                      ),
                    ),
                  );
                },
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                14,
                8,
                14,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cleanTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        if (cleanExcerpt.isNotEmpty)
                          Text(
                            cleanExcerpt,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(formattedDate),
                          ],
                        ),
                        if (wasRead) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 17,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Leída',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  FavoriteButton(
                    isFavorite: isFavorite,
                    enabled: !favoritesProvider.isLoading,
                    onPressed: () async {
                      await context
                          .read<FavoritesProvider>()
                          .toggleFavorite(post);

                      if (!context.mounted) {
                        return;
                      }

                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text(
                              isFavorite
                                  ? 'Noticia eliminada de favoritos'
                                  : 'Noticia guardada en favoritos',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}