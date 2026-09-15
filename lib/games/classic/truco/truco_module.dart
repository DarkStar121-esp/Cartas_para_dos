import 'package:flutter/widgets.dart';
import '../../../core/game_module.dart';
import 'truco_game_screen.dart';

class TrucoModule extends GameModule {
  @override
  String get id => 'truco';
  @override
  String get name => 'Truco';
  @override
  String get description => 'Envido, truco y mucho bluff con el mazo español.';
  @override
  GameCategory get category => GameCategory.classic;
  @override
  int get minPlayers => 2;
  @override
  int get maxPlayers => 2;
  @override
  bool get isCompetitive => true;

  @override
  Widget buildScreen(BuildContext context) => const TrucoGameScreen();
}
