import 'package:flutter/widgets.dart';
import '../../../core/game_module.dart';
import 'en_palabras_screen.dart';

class EnPalabrasModule extends GameModule {
  @override
  String get id => 'en_palabras';
  @override
  String get name => 'En Palabras';
  @override
  String get description => 'Describí sin decir las palabras prohibidas. Contrarreloj.';
  @override
  GameCategory get category => GameCategory.couples;
  @override
  int get minPlayers => 2;
  @override
  int get maxPlayers => 2;

  @override
  Widget buildScreen(BuildContext context) => const EnPalabrasScreen();
}
