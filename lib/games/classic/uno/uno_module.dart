import 'package:flutter/widgets.dart';
import '../../../core/game_module.dart';
import 'uno_game_screen.dart';

class UnoModule extends GameModule {
  @override
  String get id => 'uno';
  @override
  String get name => 'UNO';
  @override
  String get description => 'El clásico de cartas de colores y números.';
  @override
  GameCategory get category => GameCategory.classic;
  @override
  int get minPlayers => 2;
  @override
  int get maxPlayers => 6;
  @override
  bool get isCompetitive => true;

  @override
  Widget buildScreen(BuildContext context) => const UnoGameScreen();
}
