import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/reading_history_provider.dart';
import '../widgets/news_card.dart';

class ReadingHistoryScreen extends StatelessWidget {
  const ReadingHistoryScreen({super.key});

  Future<void> _confirmClearHistory(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Borrar historial'),
          content: const Text(
            '¿Seguro que deseas eliminar todo el historial de lectura?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await context.read<ReadingHistoryProvider>().clearHistory();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Historial eliminado'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReadingHistoryProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de lectura'),
        actions: [
          if (provider.history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmClearHistory(context),
            ),
        ],
      ),
      body: provider.history.isEmpty
          ? const Center(
              child: Text(
                'Todavía no has leído ninguna noticia.',
              ),
            )
          : ListView.builder(
              itemCount: provider.history.length,
              itemBuilder: (context, index) {
                return NewsCard(
                  post: provider.history[index],
                );
              },
            ),
    );
  }
}