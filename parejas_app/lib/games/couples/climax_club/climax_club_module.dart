import 'package:flutter/widgets.dart';
import '../../../core/game_module.dart';
import '../../../core/coming_soon_screen.dart';

/// Juego con contenido para adultos. isAdultContent = true hace que
/// el catálogo muestre el badge +18; conviene además agregar una
/// verificación de edad antes de entrar (ver ARCHITECTURE.md).
class ClimaxClubModule extends GameModule {
  @override
  String get id => 'climax_club';
  @override
  String get name => 'Climax Club';
  @override
  String get description => 'Cartas más íntimas para subir la temperatura de a dos.';
  @override
  GameCategory get category => GameCategory.couples;
  @override
  int get minPlayers => 2;
  @override
  int get maxPlayers => 2;
  @override
  bool get isAdultContent => true;

  @override
  Widget buildScreen(BuildContext context) => const ComingSoonScreen(
        gameName: 'Climax Club',
        description: 'Mismo patrón que En Palabras (mazo JSON). Definir niveles de intensidad antes de escribir el contenido.',
      );
}
