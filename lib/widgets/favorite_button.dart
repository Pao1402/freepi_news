import 'package:flutter/material.dart';

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.isFavorite,
    required this.onPressed,
    this.enabled = true,
  });

  final bool isFavorite;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: child,
        );
      },
      child: IconButton(
        key: ValueKey(isFavorite),
        tooltip: isFavorite
            ? 'Eliminar de favoritos'
            : 'Agregar a favoritos',
        onPressed: enabled ? onPressed : null,
        icon: Icon(
          isFavorite
              ? Icons.favorite
              : Icons.favorite_border,
          color: isFavorite ? Colors.red : null,
        ),
      ),
    );
  }
}