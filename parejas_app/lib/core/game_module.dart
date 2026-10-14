import 'package:flutter/widgets.dart';

/// Categoría bajo la que se agrupa un juego en el catálogo.
enum GameCategory { classic, couples }

/// Contrato que debe cumplir cada juego para poder
/// registrarse y aparecer en el catálogo de la app.
///
/// Para agregar un juego nuevo:
///   1. Crear una carpeta en lib/games/<classic|couples>/<mi_juego>/
///   2. Implementar esta interfaz en un archivo <mi_juego>_module.dart
///   3. Registrarlo en GameRegistry (core/game_registry.dart)
abstract class GameModule {
  /// Identificador único y estable, ej: 'uno', 'en_palabras'.
  /// Se usa para guardar progreso/estadísticas, no cambiar una vez publicado.
  String get id;

  /// Nombre visible en el catálogo, ej: 'UNO'.
  String get name;

  /// Descripción corta para la tarjeta del catálogo.
  String get description;

  GameCategory get category;

  /// Asset de portada opcional (ruta dentro de assets/).
  String? get coverAsset => null;

  int get minPlayers;
  int get maxPlayers;

  /// Si es true, la tarjeta del catálogo muestra un badge "+18"
  /// y (opcional) pasa por una confirmación de edad antes de entrar.
  bool get isAdultContent => false;

  /// Si es true, el juego tiene un modelo de "ganador y perdedor" y sus
  /// resultados alimentan el contador de victorias/derrotas y los apodos
  /// DOMINANTE/DOMINADO (ver core/social/nickname_service.dart). Los
  /// juegos de conexión/cooperativos dejan esto en false.
  bool get isCompetitive => false;

  /// Construye la pantalla principal / entry point del juego.
  Widget buildScreen(BuildContext context);
}
