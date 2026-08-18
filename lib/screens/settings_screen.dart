import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/news_provider.dart';
import '../providers/theme_provider.dart';
import 'reading_history_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _clearNewsCache(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Borrar caché'),
          content: const Text(
            '¿Seguro que deseas eliminar las noticias guardadas '
            'en el dispositivo?\n\n'
            'Los favoritos y el historial de lectura no serán eliminados.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await context.read<NewsProvider>().clearNewsCache();

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'La caché de noticias fue eliminada.',
            ),
          ),
        );
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'No fue posible borrar la caché.',
            ),
          ),
        );
    }
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Freepi News',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.newspaper_rounded,
          size: 36,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      children: const [
        Text(
          'Aplicación móvil de noticias conectada a WordPress REST API.',
        ),
        SizedBox(height: 12),
        Text(
          'Incluye búsqueda, categorías, favoritos, historial, '
          'modo oscuro y funcionamiento con caché.',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              8,
            ),
            child: Text(
              'Apariencia',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          SwitchListTile(
            secondary: Icon(
              themeProvider.isDarkMode
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            title: const Text('Modo oscuro'),
            subtitle: const Text(
              'Cambiar la apariencia de la aplicación',
            ),
            value: themeProvider.isDarkMode,
            onChanged: themeProvider.isLoading
                ? null
                : (value) {
                    themeProvider.setDarkMode(value);
                  },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              8,
            ),
            child: Text(
              'Actividad',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Historial de lectura'),
            subtitle: const Text(
              'Consultar las noticias que has abierto',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return const ReadingHistoryScreen();
                  },
                ),
              );
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              8,
            ),
            child: Text(
              'Almacenamiento',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ListTile(
            leading: const Icon(
              Icons.cleaning_services_outlined,
            ),
            title: const Text('Borrar caché de noticias'),
            subtitle: const Text(
              'Eliminar las noticias guardadas para uso sin conexión',
            ),
            trailing: const Icon(Icons.delete_outline),
            onTap: () {
              _clearNewsCache(context);
            },
          ),
          const ListTile(
            leading: Icon(Icons.storage_outlined),
            title: Text('Almacenamiento local'),
            subtitle: Text(
              'Los favoritos, el tema, el historial y el caché '
              'se guardan en el dispositivo.',
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              8,
            ),
            child: Text(
              'Información',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Acerca de Freepi News'),
            subtitle: const Text(
              'Información y versión de la aplicación',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showAboutDialog(context);
            },
          ),
          const ListTile(
            leading: Icon(Icons.newspaper_outlined),
            title: Text('Freepi News'),
            subtitle: Text(
              'Aplicación conectada a WordPress REST API',
            ),
          ),
          const ListTile(
            leading: Icon(Icons.tag),
            title: Text('Versión'),
            subtitle: Text('1.0.0'),
          ),
        ],
      ),
    );
  }
}