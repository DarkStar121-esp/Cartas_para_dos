import 'en_palabras_deck.dart';

/// Estado compartido de una partida de En Palabras. A diferencia de
/// UNO/Chinchón/Truco no hace falta un "motor" con reglas complejas —
/// es básicamente: el mazo ya barajado (por eso viaja completo en el
/// JSON: si cada dispositivo lo barajara por su cuenta, terminarían
/// viendo palabras distintas), quién describe, el puntaje, y si la
/// ronda está activa.
///
/// El cronómetro NO se sincroniza tick a tick (sería un tráfico de red
/// innecesario) — se sincroniza [roundStartedAt] una sola vez al
/// arrancar la ronda, y cada dispositivo calcula los segundos restantes
/// localmente a partir de esa marca de tiempo compartida.
class EnPalabrasSession {
  static const roundDuration = Duration(seconds: 60);

  final List<WordCard> deck;
  int cardIndex;
  int describerIndex;
  int score;
  DateTime? roundStartedAt;
  bool roundActive;

  EnPalabrasSession({
    required this.deck,
    this.cardIndex = 0,
    this.describerIndex = 0,
    this.score = 0,
    this.roundStartedAt,
    this.roundActive = false,
  });

  WordCard get currentCard => deck[cardIndex % deck.length];

  void markResult({required bool correct}) {
    if (correct) score++;
    cardIndex = (cardIndex + 1) % deck.length;
  }

  void startRound(DateTime now) {
    roundActive = true;
    roundStartedAt = now;
  }

  void endRound() {
    roundActive = false;
  }

  void swapDescriberAndReset() {
    describerIndex = 1 - describerIndex;
    score = 0;
    roundActive = false;
    roundStartedAt = null;
  }

  Map<String, dynamic> toJson() => {
        'deck': [
          for (final c in deck) {'word': c.word, 'forbidden': c.forbidden},
        ],
        'cardIndex': cardIndex,
        'describerIndex': describerIndex,
        'score': score,
        'roundStartedAt': roundStartedAt?.toIso8601String(),
        'roundActive': roundActive,
      };

  factory EnPalabrasSession.fromJson(Map<String, dynamic> json) => EnPalabrasSession(
        deck: [
          for (final c in json['deck'] as List) WordCard.fromJson(Map<String, dynamic>.from(c as Map)),
        ],
        cardIndex: json['cardIndex'] as int,
        describerIndex: json['describerIndex'] as int,
        score: json['score'] as int,
        roundStartedAt:
            json['roundStartedAt'] == null ? null : DateTime.parse(json['roundStartedAt'] as String),
        roundActive: json['roundActive'] as bool,
      );
}
