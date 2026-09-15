import 'package:flutter/widgets.dart';
import '../../../core/game_module.dart';
import '../../../core/coming_soon_screen.dart';

class ConectadosModule extends GameModule {
  @override
  String get id => 'conectados';
  @override
  String get name => 'Conectados';
  @override
  String get description => 'Cada uno responde por separado y comparan qué tan sincronizados están.';
  @override
  GameCategory get category => GameCategory.couples;
  @override
  int get minPlayers => 2;
  @override
  int get maxPlayers => 2;

  @override
  Widget buildScreen(BuildContext context) => const ComingSoonScreen(
        gameName: 'Conectados',
        description: 'Reusar el patrón de En Palabras: mazo en JSON + pantalla de reveal por turnos.',
      );
}
