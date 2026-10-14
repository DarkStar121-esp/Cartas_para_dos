/// Snapshot del estado de una partida compartida entre los dos
/// dispositivos de la pareja. `stateJson` es lo que devuelve el
/// `toJson()` del motor de cada juego (UnoEngine, ChinchonEngine,
/// TrucoEngine) — este modelo no sabe nada de las reglas de ningún
/// juego en particular, solo transporta el JSON.
class GameSession {
  final String sessionId;
  final String coupleId;
  final String gameId;
  final Map<String, dynamic> stateJson;

  /// Índice (0/1) de quién hizo el último cambio — útil para debug y,
  /// a futuro, para descartar ecos de la propia escritura si hiciera falta.
  final int lastActionByPlayer;
  final DateTime updatedAt;

  const GameSession({
    required this.sessionId,
    required this.coupleId,
    required this.gameId,
    required this.stateJson,
    required this.lastActionByPlayer,
    required this.updatedAt,
  });
}

/// Arma un sessionId estable y determinístico a partir de la pareja y el
/// juego, para que los dos dispositivos calculen el mismo id sin
/// necesidad de coordinarse antes (no hace falta "crear una sala" ni
/// compartir un código: ambos ya saben su coupleId).
String buildGameSessionId(String coupleId, String gameId) => '${coupleId}_$gameId';
