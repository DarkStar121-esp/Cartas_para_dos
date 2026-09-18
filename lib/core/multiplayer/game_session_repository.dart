import 'dart:async';
import 'game_session.dart';

/// Contrato para sincronizar el estado de una partida entre los dos
/// dispositivos de la pareja. Cualquier motor de juego (UNO, Chinchón,
/// Truco) usa la misma interfaz: no sabe si detrás hay Firestore o una
/// implementación en memoria para desarrollo.
abstract class GameSessionRepository {
  /// Lee el estado actual una sola vez (para saber si la sesión ya
  /// existe antes de decidir quién reparte las cartas).
  Future<GameSession?> fetchSession(String sessionId);

  /// Escucha cambios en tiempo real — cada vez que CUALQUIERA de los dos
  /// dispositivos llama a [pushState], el otro recibe un evento acá.
  Stream<GameSession?> watchSession(String sessionId);

  Future<void> pushState(
    String sessionId,
    Map<String, dynamic> stateJson, {
    required String coupleId,
    required String gameId,
    required int actingPlayer,
  });
}

/// Implementación en memoria — simula sincronización en tiempo real
/// dentro del mismo proceso de la app (dos StreamControllers broadcast
/// por sesión). Sirve para:
///  1) desarrollar y probar toda la UI de multijugador sin tener un
///     proyecto de Firebase todavía;
///  2) probar la lógica en un solo teléfono alternando de qué cuenta se
///     está "logueado" (ver AppSession.devSignInAs / DevAccountSwitcherFab)
///     — como el estado vive acá, las dos perspectivas ven la MISMA partida.
///
/// NO sirve para jugar de verdad entre dos teléfonos distintos — para
/// eso hay que usar [FirestoreGameSessionRepository] (o el backend que
/// se elija) una vez que el proyecto de Firebase esté configurado.
class InMemoryGameSessionRepository implements GameSessionRepository {
  final Map<String, GameSession> _sessions = {};
  final Map<String, StreamController<GameSession?>> _controllers = {};

  StreamController<GameSession?> _controllerFor(String id) =>
      _controllers.putIfAbsent(id, () => StreamController<GameSession?>.broadcast());

  @override
  Future<GameSession?> fetchSession(String sessionId) async => _sessions[sessionId];

  @override
  Stream<GameSession?> watchSession(String sessionId) {
    final controller = _controllerFor(sessionId);
    // Al conectarse, emite el valor actual (si existe) — imita el
    // comportamiento de Firestore de mandar el snapshot inicial.
    Future.microtask(() {
      final current = _sessions[sessionId];
      if (current != null) controller.add(current);
    });
    return controller.stream;
  }

  @override
  Future<void> pushState(
    String sessionId,
    Map<String, dynamic> stateJson, {
    required String coupleId,
    required String gameId,
    required int actingPlayer,
  }) async {
    final session = GameSession(
      sessionId: sessionId,
      coupleId: coupleId,
      gameId: gameId,
      stateJson: stateJson,
      lastActionByPlayer: actingPlayer,
      updatedAt: DateTime.now(),
    );
    _sessions[sessionId] = session;
    _controllerFor(sessionId).add(session);
  }

  /// Borra una sesión — útil para "reiniciar partida" en desarrollo.
  void clear(String sessionId) {
    _sessions.remove(sessionId);
    _controllerFor(sessionId).add(null);
  }
}

/// Implementación real con Cloud Firestore. Cada partida es un
/// documento en `game_sessions/{sessionId}`, y la sincronización en
/// tiempo real sale gratis con `.snapshots()`.
///
/// NO se pudo probar contra un proyecto de Firebase real en este
/// entorno de desarrollo (sin acceso a red) — es código de referencia,
/// escrito con cuidado contra la API de `cloud_firestore` v5, pero
/// conviene revisarlo con un dispositivo real antes de confiar en él a
/// ciegas. Limitación conocida: "el último que escribe gana" — si los
/// dos dispositivos escriben casi al mismo tiempo (no debería pasar en
/// un juego por turnos bien implementado, pero podría pasar si hay un
/// bug de UI que deja tocar dos veces), se pisan sin fusionarse.
///
/// Para usarla: reemplazar `InMemoryGameSessionRepository()` por
/// `FirestoreGameSessionRepository(FirebaseFirestore.instance)` donde se
/// arma el árbol de widgets (ver lib/main.dart).
class FirestoreGameSessionRepository implements GameSessionRepository {
  /// Se recibe como `dynamic` para no obligar a este archivo a importar
  /// `cloud_firestore` si todavía no se está usando esta implementación
  /// (evita el costo de compilación/paquete para quien solo usa la
  /// versión en memoria). Al activarla, tipear como
  /// `FirebaseFirestore` normalmente.
  final dynamic firestore;

  FirestoreGameSessionRepository(this.firestore);

  dynamic get _col => firestore.collection('game_sessions');

  @override
  Future<GameSession?> fetchSession(String sessionId) async {
    final doc = await _col.doc(sessionId).get();
    if (doc.data() == null) return null;
    return _fromDoc(sessionId, doc.data() as Map<String, dynamic>);
  }

  @override
  Stream<GameSession?> watchSession(String sessionId) {
    return _col.doc(sessionId).snapshots().map((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      return data == null ? null : _fromDoc(sessionId, data);
    });
  }

  @override
  Future<void> pushState(
    String sessionId,
    Map<String, dynamic> stateJson, {
    required String coupleId,
    required String gameId,
    required int actingPlayer,
  }) async {
    await _col.doc(sessionId).set({
      'coupleId': coupleId,
      'gameId': gameId,
      'state': stateJson,
      'lastActionByPlayer': actingPlayer,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  GameSession _fromDoc(String id, Map<String, dynamic> data) {
    return GameSession(
      sessionId: id,
      coupleId: data['coupleId'] as String,
      gameId: data['gameId'] as String,
      stateJson: Map<String, dynamic>.from(data['state'] as Map),
      lastActionByPlayer: data['lastActionByPlayer'] as int? ?? 0,
      updatedAt: DateTime.tryParse(data['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
