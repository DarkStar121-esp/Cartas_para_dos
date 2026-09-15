import 'package:flutter/widgets.dart';
import '../../../core/game_module.dart';
import '../../../core/coming_soon_screen.dart';

class EscobaModule extends GameModule {
  @override
  String get id => 'escoba';
  @override
  String get name => 'Escoba del 15';
  @override
  String get description => 'Sumá 15 con las cartas de la mesa y hacé escobas.';
  @override
  GameCategory get category => GameCategory.classic;
  @override
  int get minPlayers => 2;
  @override
  int get maxPlayers => 4;
  @override
  bool get isCompetitive => true;

  @override
  Widget buildScreen(BuildContext context) => const ComingSoonScreen(
        gameName: 'Escoba del 15',
        description: 'Motor de reglas pendiente — mismo patrón que UNO (ver uno_engine.dart).',
      );
}
