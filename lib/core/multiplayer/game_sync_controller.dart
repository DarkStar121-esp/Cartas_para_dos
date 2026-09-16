import 'dart:async';
import 'game_session_repository.dart';

/// Envoltorio genérico que conecta CUALQUIER motor de juego (UNO,
/// Chinchón, Truco — cualquiera que tenga `toJson()`/`fromJson()`) con
/// un [GameSessionRepository], para que jugar en un dispositivo se vea
/// reflejado en el otro.
///
/// Patrón de uso en una pantalla de juego:
/// ```dart
/// final controller = GameSyncController<UnoEngine>(
///   repository: context.read<GameSessionRepository>(),
///   sessionId: buildGameSessionId(couple.id, 'uno'),
///   coupleId: couple.id,
///   gameId: 'uno',
///   myPlayerIndex: appSession.myPlayerIndex,
///   decode: UnoEngine.fromJson,
///   encode: (e) => e.toJson(),
/// );
/// await controller.connect(buildInitialState: () => UnoEngine(2));
/// controller.stream.listen((engine) => setState(() => _engine = engine));
/// ...
/// // al jugar una carta:
/// controller.act((engine) => engine.playCard(myPlayerIndex, card));
/// ```
class GameSyncController<E> {
  final GameSessionRepository repository;
  final String sessionId;
  final String coupleId;
  final String gameId;
  final int myPlayerIndex;
  final E Function(Map<String, dynamic> json) decode;
  final Map<String, dynamic> Function(E engine) encode;

  late E state;
  final _stateController = StreamController<E>.broadcast();
  StreamSubscription? _subscription;

  GameSyncController({
    required this.repository,
    required this.sessionId,
    required this.coupleId,
    required this.gameId,
    required this.myPlayerIndex,
    required this.decode,
    required this.encode,
  });

  Stream<E> get stream => _stateController.stream;

  /// Se llama una sola vez al entrar a la pantalla del juego. Si la
  /// sesión ya existe (la pareja ya la abrió antes), se suscribe a ella.
  /// Si no existe todavía, ESTE dispositivo la crea con
  /// [buildInitialState] (por ejemplo, recién repartidas las cartas) y
  /// la publica para que el otro la reciba en cuanto entre al juego.
  /// [buildInitialState] puede ser async (por ejemplo, si necesita
  /// cargar un mazo desde un asset, como En Palabras).
  Future<void> connect({required FutureOr<E> Function() buildInitialState}) async {
    final existing = await repository.fetchSession(sessionId);
    if (existing != null) {
      state = decode(existing.stateJson);
    } else {
      state = await buildInitialState();
      await repository.pushState(
        sessionId,
        encode(state),
        coupleId: coupleId,
        gameId: gameId,
        actingPlayer: myPlayerIndex,
      );
    }
    _stateController.add(state);

    _subscription = repository.watchSession(sessionId).listen((session) {
      if (session == null) return;
      state = decode(session.stateJson);
      _stateController.add(state);
    });
  }

  /// Aplica una mutación LOCAL sobre el motor actual (los motores de
  /// esta app mutan en el lugar, ver *_engine.dart) y publica el nuevo
  /// estado para que el otro dispositivo lo reciba. Se actualiza la UI
  /// local al instante, sin esperar la vuelta del servidor.
  Future<void> act(void Function(E engine) mutate) async {
    mutate(state);
    _stateController.add(state);
    await repository.pushState(
      sessionId,
      encode(state),
      coupleId: coupleId,
      gameId: gameId,
      actingPlayer: myPlayerIndex,
    );
  }

  /// A diferencia de [act], reemplaza el motor ENTERO por uno nuevo —
  /// para "jugar de nuevo" (una partida nueva de cero, no una jugada
  /// sobre la actual). Solo debería llamarlo un dispositivo por vez
  /// (normalmente el jugador 0) para no pisarse con el otro; las
  /// pantallas de juego lo resuelven así con un `if (myPlayerIndex == 0)`.
  Future<void> replaceState(E newState) async {
    state = newState;
    _stateController.add(state);
    await repository.pushState(
      sessionId,
      encode(state),
      coupleId: coupleId,
      gameId: gameId,
      actingPlayer: myPlayerIndex,
    );
  }

  void dispose() {
    _subscription?.cancel();
    _stateController.close();
  }
}
