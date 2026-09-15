import 'dart:math';
import '../../shared/spanish_deck.dart';
import 'truco_rules.dart';

/// Motor de Truco Argentino para 2 jugadores, sin ninguna dependencia de
/// Flutter — testeable con `flutter test` sin UI.
///
/// SIMPLIFICACIONES respecto al juego "de mesa" completo (documentadas a
/// propósito, como con el resto de los motores de esta app):
///  - Solo 2 jugadores (1 contra 1) — no equipos de 2v2.
///  - No incluye Flor (variante regional opcional).
///  - El envido es "de un solo tiro": se puede cantar Envido, Real Envido
///    o Falta Envido una sola vez por mano, sin cadenas de re-canto
///    (envido-envido-real-envido). Es la simplificación más grande;
///    documentarlo bien para no confundir a alguien que sepa jugar.
///  - "Irse al mazo" con un canto pendiente se resuelve como si se
///    hubiese dicho "no quiero" a ese canto.
enum TrickOutcome { player1, player2, parda }

enum TrucoLevel { none, truco, retruco, valeCuatro }

enum EnvidoCall { envido, realEnvido, faltaEnvido }

enum TrucoPhase { playing, awaitingEnvidoResponse, awaitingTrucoResponse, manoFinished, gameFinished }

class TrucoEngine {
  static const int pointsToWin = 15;

  final List<List<SpanishCard>> hands = [[], []];
  final List<int> scores = [0, 0];

  int manoPlayer; // quién es "mano" (lidera la primera baza) esta ronda
  int trickLeader = 0;
  int currentPlayer = 0;
  int currentTrick = 0;

  final List<TrickOutcome?> trickResults = [null, null, null];
  final List<List<SpanishCard?>> playedCards = [
    [null, null, null],
    [null, null, null],
  ];

  TrucoLevel pendingTrucoLevel = TrucoLevel.none;
  TrucoLevel acceptedTrucoLevel = TrucoLevel.none;
  int? trucoCallerId;

  bool envidoResolvedThisMano = false;
  EnvidoCall? pendingEnvidoCall;
  int? envidoCallerId;

  int? manoWinner;
  int? gameWinner;
  TrucoPhase phase = TrucoPhase.playing;

  TrucoEngine({Random? random}) : manoPlayer = 0 {
    _dealNewMano(random);
  }

  void _dealNewMano(Random? random) {
    final deck = generateSpanishDeck()..shuffle(random ?? Random());
    hands[0] = deck.sublist(0, 3);
    hands[1] = deck.sublist(3, 6);
    trickResults.setAll(0, [null, null, null]);
    for (final row in playedCards) {
      row.setAll(0, [null, null, null]);
    }
    pendingTrucoLevel = TrucoLevel.none;
    acceptedTrucoLevel = TrucoLevel.none;
    trucoCallerId = null;
    envidoResolvedThisMano = false;
    pendingEnvidoCall = null;
    envidoCallerId = null;
    manoWinner = null;
    trickLeader = manoPlayer;
    currentPlayer = manoPlayer;
    currentTrick = 0;
    phase = TrucoPhase.playing;
  }

  // ---------------- Envido ----------------

  bool get canCallEnvido =>
      phase == TrucoPhase.playing &&
      !envidoResolvedThisMano &&
      currentTrick == 0 &&
      playedCards[0][0] == null &&
      playedCards[1][0] == null &&
      pendingEnvidoCall == null;

  void callEnvido(int player, EnvidoCall call) {
    assert(canCallEnvido);
    pendingEnvidoCall = call;
    envidoCallerId = player;
    phase = TrucoPhase.awaitingEnvidoResponse;
  }

  void respondEnvido(bool accept) {
    final call = pendingEnvidoCall!;
    final caller = envidoCallerId!;

    if (!accept) {
      scores[caller] += 1; // declinar cualquier envido da 1 punto a quien cantó
    } else {
      final e0 = calculateEnvido(hands[0]);
      final e1 = calculateEnvido(hands[1]);
      final winner = e0 == e1 ? manoPlayer : (e0 > e1 ? 0 : 1); // empate: gana el mano
      final points = switch (call) {
        EnvidoCall.envido => 2,
        EnvidoCall.realEnvido => 3,
        EnvidoCall.faltaEnvido => pointsToWin - scores[winner],
      };
      scores[winner] += points;
    }

    envidoResolvedThisMano = true;
    pendingEnvidoCall = null;
    envidoCallerId = null;
    phase = TrucoPhase.playing;
    _checkGameOver();
  }

  // ---------------- Truco / Retruco / Vale cuatro ----------------

  bool get canCallTruco =>
      phase == TrucoPhase.playing &&
      pendingTrucoLevel == TrucoLevel.none &&
      acceptedTrucoLevel == TrucoLevel.none;

  bool canRaiseTruco(int player) =>
      phase == TrucoPhase.playing &&
      pendingTrucoLevel == TrucoLevel.none &&
      acceptedTrucoLevel != TrucoLevel.none &&
      acceptedTrucoLevel != TrucoLevel.valeCuatro &&
      trucoCallerId != player;

  void callTruco(int player) {
    assert(canCallTruco);
    pendingTrucoLevel = TrucoLevel.truco;
    trucoCallerId = player;
    phase = TrucoPhase.awaitingTrucoResponse;
  }

  void raiseTruco(int player) {
    assert(canRaiseTruco(player));
    pendingTrucoLevel = acceptedTrucoLevel == TrucoLevel.truco ? TrucoLevel.retruco : TrucoLevel.valeCuatro;
    trucoCallerId = player;
    phase = TrucoPhase.awaitingTrucoResponse;
  }

  void respondTruco(bool accept) {
    if (accept) {
      acceptedTrucoLevel = pendingTrucoLevel;
      pendingTrucoLevel = TrucoLevel.none;
      phase = TrucoPhase.playing;
    } else {
      scores[trucoCallerId!] += _trucoLevelValue(acceptedTrucoLevel);
      _finishMano(winner: trucoCallerId!);
    }
    _checkGameOver();
  }

  int _trucoLevelValue(TrucoLevel level) => switch (level) {
        TrucoLevel.none => 1,
        TrucoLevel.truco => 2,
        TrucoLevel.retruco => 3,
        TrucoLevel.valeCuatro => 4,
      };

  // ---------------- Irse al mazo ----------------

  void foldMano(int player) {
    final opponent = 1 - player;
    scores[opponent] += _trucoLevelValue(acceptedTrucoLevel);
    _finishMano(winner: opponent);
    _checkGameOver();
  }

  // ---------------- Jugar cartas ----------------

  void playCard(int player, SpanishCard card) {
    assert(phase == TrucoPhase.playing);
    assert(player == currentPlayer);
    hands[player].remove(card);
    playedCards[player][currentTrick] = card;

    if (playedCards[1 - player][currentTrick] != null) {
      _resolveTrick();
    } else {
      currentPlayer = 1 - player;
    }
  }

  void _resolveTrick() {
    final c0 = playedCards[0][currentTrick]!;
    final c1 = playedCards[1][currentTrick]!;
    final p0 = trucoPower(c0);
    final p1 = trucoPower(c1);
    final outcome =
        p0 == p1 ? TrickOutcome.parda : (p0 > p1 ? TrickOutcome.player1 : TrickOutcome.player2);
    trickResults[currentTrick] = outcome;

    if (_resolveManoIfDecided()) {
      scores[manoWinner!] += _trucoLevelValue(acceptedTrucoLevel);
      _finishMano(winner: manoWinner!);
      return;
    }

    trickLeader = outcome == TrickOutcome.parda ? trickLeader : (outcome == TrickOutcome.player1 ? 0 : 1);
    currentPlayer = trickLeader;
    currentTrick++;
  }

  /// Implementa el desempate de bazas del Truco: dos bazas ganadas por el
  /// mismo jugador (sin importar pardas en el medio) definen la mano. Si
  /// la primera es parda, gana la mano quien gane la segunda (o la
  /// tercera si la segunda también empata; si las tres empatan, gana el
  /// jugador "mano"). Si la primera tiene ganador y la segunda es parda,
  /// gana la mano quien ganó la primera.
  bool _resolveManoIfDecided() {
    final t = trickResults;
    final p1Wins = t.where((o) => o == TrickOutcome.player1).length;
    final p2Wins = t.where((o) => o == TrickOutcome.player2).length;
    if (p1Wins >= 2) {
      manoWinner = 0;
      return true;
    }
    if (p2Wins >= 2) {
      manoWinner = 1;
      return true;
    }

    if (t[0] == TrickOutcome.parda) {
      if (t[1] != null && t[1] != TrickOutcome.parda) {
        manoWinner = t[1] == TrickOutcome.player1 ? 0 : 1;
        return true;
      }
      if (t[1] == TrickOutcome.parda && t[2] != null) {
        manoWinner = t[2] == TrickOutcome.parda ? manoPlayer : (t[2] == TrickOutcome.player1 ? 0 : 1);
        return true;
      }
      return false;
    }

    final firstWinner = t[0] == TrickOutcome.player1 ? 0 : 1;
    if (t[1] == null) return false;
    if (t[1] == TrickOutcome.parda) {
      manoWinner = firstWinner;
      return true;
    }
    final secondWinner = t[1] == TrickOutcome.player1 ? 0 : 1;
    if (secondWinner == firstWinner) {
      manoWinner = firstWinner;
      return true;
    }
    if (t[2] == null) return false;
    manoWinner = t[2] == TrickOutcome.parda ? firstWinner : (t[2] == TrickOutcome.player1 ? 0 : 1);
    return true;
  }

  void _finishMano({required int winner}) {
    manoWinner = winner;
    phase = TrucoPhase.manoFinished;
  }

  void startNextMano({Random? random}) {
    manoPlayer = 1 - manoPlayer; // alterna quién es mano
    _dealNewMano(random);
  }

  void _checkGameOver() {
    if (scores[0] >= pointsToWin || scores[1] >= pointsToWin) {
      phase = TrucoPhase.gameFinished;
      gameWinner = scores[0] > scores[1] ? 0 : 1;
    }
  }
}
