import 'package:flutter/widgets.dart';
import '../../../core/game_module.dart';
import 'chinchon_game_screen.dart';

class ChinchonModule extends GameModule {
  @override
  String get id => 'chinchon';
  @override
  String get name => 'Chinchón';
  @override
  String get description => 'Formá escaleras y grupos, el que menos puntos suma gana.';
  @override
  GameCategory get category => GameCategory.classic;
  @override
  int get minPlayers => 2;
  @override
  int get maxPlayers => 4;
  @override
  bool get isCompetitive => true;

  @override
  Widget buildScreen(BuildContext context) => const ChinchonGameScreen();
}
