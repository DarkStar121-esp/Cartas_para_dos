import 'package:flutter/material.dart';

/// Pantalla placeholder reutilizable para juegos que todavía
/// no tienen su lógica implementada. Sirve para poder registrar
/// el módulo en el catálogo desde el día 1 y desarrollar cada
/// juego de forma independiente después.
class ComingSoonScreen extends StatelessWidget {
  final String gameName;
  final String description;

  const ComingSoonScreen({
    super.key,
    required this.gameName,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(gameName)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction, size: 48),
              const SizedBox(height: 16),
              Text(
                '$gameName — próximamente',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
