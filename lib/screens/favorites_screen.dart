import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/favorites_provider.dart';
import '../widgets/news_card.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  Future<void> _confirmClearFavorites(
    BuildContext context,
  ) async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar favoritos'),
          content: const Text(
            '¿Seguro que deseas eliminar todas las noticias favoritas?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (shouldClear != true || !context.mounted) {
      return;
    }

    await context.read<FavoritesProvider>().clearFavorites();

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Se eliminaron todos los favoritos'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = context.watch<FavoritesProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          favoritesProvider.favorites.isEmpty
              ? 'Noticias favoritas'
              : 'Favoritos (${favoritesProvider.favoritesCount})',
        ),
        centerTitle: true,
        actions: [
          if (favoritesProvider.favorites.isNotEmpty)
            IconButton(
              tooltip: 'Eliminar todos',
              onPressed: favoritesProvider.isLoading
                  ? null
                  : () {
                      _confirmClearFavorites(context);
                    },
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (favoritesProvider.isLoading &&
              favoritesProvider.favorites.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (favoritesProvider.favorites.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 80,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Todavía no tienes noticias favoritas.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Presiona el corazón de una noticia para guardarla.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(
              top: 8,
              bottom: 16,
            ),
            itemCount: favoritesProvider.favorites.length,
            itemBuilder: (context, index) {
              final post = favoritesProvider.favorites[index];

              return NewsCard(post: post);
            },
          );
        },
      ),
    );
  }
}