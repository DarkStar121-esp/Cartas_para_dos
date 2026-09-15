import 'game_module.dart';

import '../games/classic/uno/uno_module.dart';
import '../games/classic/chinchon/chinchon_module.dart';
import '../games/classic/escoba/escoba_module.dart';
import '../games/classic/truco/truco_module.dart';

import '../games/couples/en_palabras/en_palabras_module.dart';
import '../games/couples/conectados/conectados_module.dart';
import '../games/couples/climax_club/climax_club_module.dart';

/// Punto único donde se registran todos los juegos disponibles.
/// Agregar un juego nuevo = crear su módulo (ver GameModule) + agregarlo acá.
class GameRegistry {
  static final List<GameModule> all = [
    // --- Clásicos ---
    UnoModule(),
    ChinchonModule(),
    EscobaModule(),
    TrucoModule(),

    // --- Para dos ---
    EnPalabrasModule(),
    ConectadosModule(),
    ClimaxClubModule(),
  ];

  static List<GameModule> byCategory(GameCategory category) =>
      all.where((g) => g.category == category).toList();
}
