import 'dart:math';
import '../../shared/spanish_deck.dart';
import 'chinchon_melds.dart';

/// Motor de Chinchón para 2 jugadores (pasar y jugar), sin ninguna
/// dependencia de Flutter — testeable con `flutter test` sin UI.
///
/// SIMPLIFICACIONES respecto al reglamento "oficial" (hay variantes
/// regionales para casi todo esto, se documentan acá las elegidas):
///  - Se puede "cortar" apenas, después de robar, el descarte de UNA
///    carta deja el resto (7) partido en combinaciones con deadwood
///    ≤ [maxDeadwoodToCut] (acá 5) — no hace falta deadwood == 0 exacto.
///  - Chinchón (7 cartas en una sola escalera) duplica los puntos de los
///    rivales en vez de sumar/restar bonus fijos.
///  - La partida termina cuando alguien llega a [targetScore] (100);
///    gana quien tenga MENOS puntos acumulados en ese momento.
class ChinchonEngine {
  static const int maxDeadwoodToCut = 5;
  static const int targetScore = 100;

  final int playerCount;
  late final List<List<SpanishCard>> hands;
  final List<SpanishCard> drawPile = [];
  final List<SpanishCard> discardPile = [];
  late final List<int> totalScores;

  int currentPlayer = 0;
  bool roundOver = false;
  int? roundWinner;
  bool? roundWinnerHadChinchon;
  Map<int, MeldResult>? lastRoundBreakdown;

  ChinchonEngine(this.playerCount, {Random? random}) {
    hands = List.generate(playerCount, (_) => <SpanishCard>[]);
    totalScores = List.filled(playerCount, 0);
    _startNewRound(random);
  }

  /// Constructor "vacío" usado solo por [ChinchonEngine.fromJson].
  ChinchonEngine._empty(this.playerCount)
      : hands = List.generate(playerCount, (_) => <SpanishCard>[]),
        totalScores = List.filled(playerCount, 0);

  /// Serializa el estado para mandarlo al otro dispositivo (ver
  /// core/multiplayer/). No incluye [lastRoundBreakdown]: es más simple
  /// recalcularlo localmente con ChinchonMelds.bestPartition a partir de
  /// las manos ya sincronizadas que serializar un MeldResult completo.
  Map<String, dynamic> toJson() => {
        'playerCount': playerCount,
        'hands': [
          for (final h in hands) [for (final c in h) c.toJson()],
        ],
        'drawPile': [for (final c in drawPile) c.toJson()],
        'discardPile': [for (final c in discardPile) c.toJson()],
        'totalScores': totalScores,
        'currentPlayer': currentPlayer,
        'roundOver': roundOver,
        'roundWinner': roundWinner,
        'roundWinnerHadChinchon': roundWinnerHadChinchon,
      };

  factory ChinchonEngine.fromJson(Map<String, dynamic> json) {
    final engine = ChinchonEngine._empty(json['playerCount'] as int);
    final handsJson = json['hands'] as List;
    for (var i = 0; i < handsJson.length; i++) {
      engine.hands[i].addAll([
        for (final c in handsJson[i] as List) SpanishCard.fromJson(Map<String, dynamic>.from(c as Map)),
      ]);
    }
    engine.drawPile.addAll([
      for (final c in json['drawPile'] as List) SpanishCard.fromJson(Map<String, dynamic>.from(c as Map)),
    ]);
    engine.discardPile.addAll([
      for (final c in json['discardPile'] as List) SpanishCard.fromJson(Map<String, dynamic>.from(c as Map)),
    ]);
    final scoresJson = json['totalScores'] as List;
    for (var i = 0; i < scoresJson.length; i++) {
      engine.totalScores[i] = scoresJson[i] as int;
    }
    engine.currentPlayer = json['currentPlayer'] as int;
    engine.roundOver = json['roundOver'] as bool;
    engine.roundWinner = json['roundWinner'] as int?;
    engine.roundWinnerHadChinchon = json['roundWinnerHadChinchon'] as bool?;
    if (engine.roundOver) {
      engine.lastRoundBreakdown = {
        for (var p = 0; p < engine.playerCount; p++) p: ChinchonMelds.bestPartition(engine.hands[p]),
      };
    }
    return engine;
  }

  void _startNewRound(Random? random) {
    final deck = generateSpanishDeck()..shuffle(random ?? Random());
    drawPile
      ..clear()
      ..addAll(deck);
    discardPile.clear();
    for (final h in hands) {
      h.clear();
    }
    for (var i = 0; i < 7; i++) {
      for (var p = 0; p < playerCount; p++) {
        hands[p].add(drawPile.removeLast());
      }
    }
    discardPile.add(drawPile.removeLast());
    roundOver = false;
    roundWinner = null;
    roundWinnerHadChinchon = null;
    lastRoundBreakdown = null;
  }

  SpanishCard get topDiscard => discardPile.last;

  void drawFromPile(int player) {
    if (drawPile.isEmpty) _reshuffleDiscardIntoDraw();
    if (drawPile.isEmpty) return;
    hands[player].add(drawPile.removeLast());
  }

  void drawFromDiscard(int player) {
    hands[player].add(discardPile.removeLast());
  }

  /// La mano tiene 8 cartas (recién robó). Prueba, sacando cada carta
  /// posible como descarte, si lo que queda puede cortar la ronda.
  bool canCut(int player) {
    final hand = hands[player];
    if (hand.length != 8) return false;
    for (final candidate in hand) {
      final rest = [...hand]..remove(candidate);
      if (ChinchonMelds.bestPartition(rest).deadwoodPoints <= maxDeadwoodToCut) return true;
    }
    return false;
  }

  /// Descarta [card]. Si [declaringCorte] es true, en vez de pasar el
  /// turno termina la ronda y liquida los puntos.
  void discard(int player, SpanishCard card, {bool declaringCorte = false}) {
    hands[player].remove(card);
    if (declaringCorte) {
      _endRound(cutterId: player);
      return;
    }
    discardPile.add(card);
    currentPlayer = (currentPlayer + 1) % playerCount;
  }

  void _endRound({required int cutterId}) {
    roundOver = true;
    roundWinner = cutterId;
    final cutterChinchon = ChinchonMelds.isChinchon(hands[cutterId]);
    roundWinnerHadChinchon = cutterChinchon;

    final breakdown = <int, MeldResult>{};
    for (var p = 0; p < playerCount; p++) {
      final result = ChinchonMelds.bestPartition(hands[p]);
      breakdown[p] = result;
      final points = p == cutterId
          ? (cutterChinchon ? 0 : result.deadwoodPoints)
          : (cutterChinchon ? result.deadwoodPoints * 2 : result.deadwoodPoints);
      totalScores[p] += points;
    }
    lastRoundBreakdown = breakdown;
  }

  bool get isGameOver => totalScores.any((s) => s >= targetScore);

  int? get gameWinner {
    if (!isGameOver) return null;
    var winner = 0;
    for (var p = 1; p < playerCount; p++) {
      if (totalScores[p] < totalScores[winner]) winner = p;
    }
    return winner;
  }

  void startNextRound({Random? random}) => _startNewRound(random);

  void _reshuffleDiscardIntoDraw() {
    if (discardPile.length <= 1) return;
    final top = discardPile.removeLast();
    drawPile.addAll(discardPile);
    discardPile
      ..clear()
      ..add(top);
    drawPile.shuffle(Random());
  }
}
