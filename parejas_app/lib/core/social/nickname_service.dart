import '../../models/couple.dart';

enum Nickname { dominante, dominado }

/// Toda esta lógica es pura y sin estado propio — los apodos se
/// CALCULAN, nunca se guardan (ver sección 7 del diseño). Eso evita
/// tener que "resetear" nada explícitamente: simplemente, si pasó más
/// de un mes desde la última partida competitiva, la función devuelve
/// null para los dos sin tocar el contador histórico.
class NicknameService {
  static const inactivityResetAfter = Duration(days: 30);

  /// Devuelve el apodo de cada integrante de la pareja en este momento.
  /// null/null si: nunca jugaron un juego competitivo, hay empate de
  /// victorias, o pasó más de un mes desde la última partida competitiva.
  ({Nickname? user1, Nickname? user2}) computeNicknames(Couple couple, DateTime now) {
    final lastGame = couple.lastCompetitiveGameAt;
    if (lastGame == null) return (user1: null, user2: null);
    if (now.difference(lastGame) > inactivityResetAfter) {
      return (user1: null, user2: null);
    }

    final wins1 = couple.competitiveRecordByUserId[couple.user1Id]?.wins ?? 0;
    final wins2 = couple.competitiveRecordByUserId[couple.user2Id]?.wins ?? 0;

    if (wins1 == wins2) return (user1: null, user2: null);
    return wins1 > wins2
        ? (user1: Nickname.dominante, user2: Nickname.dominado)
        : (user1: Nickname.dominado, user2: Nickname.dominante);
  }

  /// Se llama al terminar una partida de un juego marcado `isCompetitive`
  /// (ver GameModule.isCompetitive). Solo suma al contador histórico y
  /// actualiza `lastCompetitiveGameAt` — el apodo se recalcula solo la
  /// próxima vez que se pida con computeNicknames.
  Couple recordResult(
    Couple couple, {
    required String winnerId,
    required String loserId,
    required DateTime playedAt,
  }) {
    final records = Map<String, CompetitiveRecord>.from(couple.competitiveRecordByUserId);
    records[winnerId] = (records[winnerId] ?? const CompetitiveRecord()).addWin();
    records[loserId] = (records[loserId] ?? const CompetitiveRecord()).addLoss();

    return couple.copyWith(
      competitiveRecordByUserId: records,
      lastCompetitiveGameAt: playedAt,
    );
  }
}
