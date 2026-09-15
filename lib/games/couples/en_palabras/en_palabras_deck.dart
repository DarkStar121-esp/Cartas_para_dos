import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

class WordCard {
  final String word;
  final List<String> forbidden;
  const WordCard({required this.word, required this.forbidden});

  factory WordCard.fromJson(Map<String, dynamic> json) => WordCard(
        word: json['word'] as String,
        forbidden: List<String>.from(json['forbidden'] as List),
      );
}

/// Carga y baraja el mazo de cartas desde el JSON en assets/data/.
/// Este patrón (contenido como JSON, no hardcodeado en Dart) es el
/// mismo que conviene usar para Conectados y Climax Club: permite
/// agregar/editar cartas sin tocar código, y eventualmente traerlas
/// desde un backend para actualizar el mazo sin re-publicar la app.
class WordDeck {
  static Future<List<WordCard>> load({Random? random}) async {
    final raw = await rootBundle.loadString('assets/data/en_palabras_cards.json');
    final list = (jsonDecode(raw) as List)
        .map((e) => WordCard.fromJson(e as Map<String, dynamic>))
        .toList();
    list.shuffle(random ?? Random());
    return list;
  }
}
