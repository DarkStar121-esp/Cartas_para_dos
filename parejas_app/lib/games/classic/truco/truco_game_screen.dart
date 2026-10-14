import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_session.dart';
import '../../../core/multiplayer/game_session.dart';
import '../../../core/multiplayer/game_sync_controller.dart';
import '../../../widgets/cards/card_animations.dart';
import '../../../widgets/cards/spanish_card_face.dart';
import '../../shared/spanish_deck.dart';
import 'truco_engine.dart';

class TrucoGameScreen extends StatefulWidget {
  const TrucoGameScreen({super.key});

  @override
  State<TrucoGameScreen> createState() => _TrucoGameScreenState();
}

class _TrucoGameScreenState extends State<TrucoGameScreen> {
  late final GameSyncController<TrucoEngine> _controller;
  TrucoEngine? _engine;
  bool _manoDialogShown = false;

  @override
  void initState() {
    super.initState();
    final session = context.read<AppSession>();
    final couple = session.couple!;
    _controller = GameSyncController<TrucoEngine>(
      repository: session.gameSessionRepository,
      sessionId: buildGameSessionId(couple.id, 'truco'),
      coupleId: couple.id,
      gameId: 'truco',
      myPlayerIndex: session.myPlayerIndex,
      decode: TrucoEngine.fromJson,
      encode: (e) => e.toJson(),
    );
    _controller.connect(buildInitialState: () => TrucoEngine());
    _controller.stream.listen((engine) {
      setState(() => _engine = engine);
      if (engine.phase == TrucoPhase.manoFinished && !_manoDialogShown) {
        _manoDialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _showManoResult());
      } else if (engine.phase == TrucoPhase.playing) {
        _manoDialogShown = false;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _myIndex => context.read<AppSession>().myPlayerIndex;

  void _showManoResult() {
    final engine = _engine!;
    final myIndex = _myIndex;
    if (engine.phase == TrucoPhase.gameFinished) {
      _showGameOver();
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(engine.manoWinner == myIndex ? 'Ganaste la mano' : 'Tu pareja se llevó la mano'),
        content: Text('Puntaje: ${engine.scores[0]} - ${engine.scores[1]}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (myIndex == 0) _controller.act((e) => e.startNextMano());
            },
            child: const Text('Siguiente mano'),
          ),
        ],
      ),
    );
  }

  void _showGameOver() {
    final engine = _engine!;
    final myIndex = _myIndex;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(engine.gameWinner == myIndex ? '¡Ganaste la partida! 🏆' : 'Tu pareja ganó la partida'),
        content: Text('${engine.scores[0]} - ${engine.scores[1]}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (myIndex == 0) _controller.replaceState(TrucoEngine());
            },
            child: const Text('Jugar de nuevo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final engine = _engine;
    final myIndex = context.watch<AppSession>().myPlayerIndex;

    if (engine == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final myTurn = engine.currentPlayer == myIndex;
    final hand = engine.hands[myIndex];
    final opponentCount = engine.hands[1 - myIndex].length;

    return Scaffold(
      appBar: AppBar(title: const Text('Truco')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Puntos: ${engine.scores[0]} - ${engine.scores[1]}  ·  Pareja: $opponentCount cartas',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(child: _buildTable(engine, myIndex)),
          _buildCantoBar(engine, myIndex),
          const SizedBox(height: 8),
          Text(myTurn ? 'Tu turno' : 'Esperando a tu pareja…', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < hand.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: StaggeredEntrance(
                      index: i,
                      child: GestureDetector(
                        onTap: myTurn && engine.phase == TrucoPhase.playing
                            ? () => _controller.act((e) => e.playCard(myIndex, hand[i]))
                            : null,
                        child: SpanishCardFace(card: hand[i], width: 68),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTable(TrucoEngine engine, int myIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (var trick = 0; trick < 3; trick++)
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _trickSlot(engine.playedCards[1 - myIndex][trick]),
              const SizedBox(height: 8),
              _trickSlot(engine.playedCards[myIndex][trick]),
            ],
          ),
      ],
    );
  }

  Widget _trickSlot(SpanishCard? card) {
    if (card == null) {
      return Container(
        width: 60,
        height: 87,
        decoration:
            BoxDecoration(border: Border.all(color: Colors.black12, width: 1.5), borderRadius: BorderRadius.circular(8)),
      );
    }
    return PopInCard(key: ValueKey(card), child: SpanishCardFace(card: card, width: 60));
  }

  Widget _buildCantoBar(TrucoEngine engine, int myIndex) {
    if (engine.phase == TrucoPhase.awaitingEnvidoResponse) {
      if (engine.envidoCallerId == myIndex) {
        return const Padding(
          padding: EdgeInsets.all(8),
          child: Text('Esperando que tu pareja responda…', style: TextStyle(fontWeight: FontWeight.bold)),
        );
      }
      final label = switch (engine.pendingEnvidoCall!) {
        EnvidoCall.envido => 'Envido',
        EnvidoCall.realEnvido => 'Real Envido',
        EnvidoCall.faltaEnvido => 'Falta Envido',
      };
      return _responseBar('¿Aceptás el $label?', () => _controller.act((e) => e.respondEnvido(true)),
          () => _controller.act((e) => e.respondEnvido(false)));
    }

    if (engine.phase == TrucoPhase.awaitingTrucoResponse) {
      if (engine.trucoCallerId == myIndex) {
        return const Padding(
          padding: EdgeInsets.all(8),
          child: Text('Esperando que tu pareja responda…', style: TextStyle(fontWeight: FontWeight.bold)),
        );
      }
      final label = switch (engine.pendingTrucoLevel) {
        TrucoLevel.truco => 'Truco',
        TrucoLevel.retruco => 'Retruco',
        TrucoLevel.valeCuatro => 'Vale Cuatro',
        TrucoLevel.none => '',
      };
      return _responseBar('¿Aceptás el $label?', () => _controller.act((e) => e.respondTruco(true)),
          () => _controller.act((e) => e.respondTruco(false)));
    }

    if (engine.currentPlayer != myIndex) return const SizedBox(height: 8);

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        if (engine.canCallEnvido) ...[
          _cantoChip('Envido', () => _controller.act((e) => e.callEnvido(myIndex, EnvidoCall.envido))),
          _cantoChip('Real Envido', () => _controller.act((e) => e.callEnvido(myIndex, EnvidoCall.realEnvido))),
          _cantoChip('Falta Envido', () => _controller.act((e) => e.callEnvido(myIndex, EnvidoCall.faltaEnvido))),
        ],
        if (engine.canCallTruco) _cantoChip('Truco', () => _controller.act((e) => e.callTruco(myIndex))),
        if (engine.canRaiseTruco(myIndex))
          _cantoChip(
            engine.acceptedTrucoLevel == TrucoLevel.truco ? 'Retruco' : 'Vale Cuatro',
            () => _controller.act((e) => e.raiseTruco(myIndex)),
          ),
        _cantoChip('Me voy al mazo', () => _controller.act((e) => e.foldMano(myIndex)), danger: true),
      ],
    );
  }

  Widget _responseBar(String question, VoidCallback onAccept, VoidCallback onDecline) {
    return Column(
      children: [
        Text(question, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(onPressed: onAccept, child: const Text('Quiero')),
            const SizedBox(width: 12),
            OutlinedButton(onPressed: onDecline, child: const Text('No quiero')),
          ],
        ),
      ],
    );
  }

  Widget _cantoChip(String label, VoidCallback onTap, {bool danger = false}) {
    return ActionChip(
      label: Text(label),
      backgroundColor: danger ? Colors.red.shade50 : null,
      labelStyle: danger ? const TextStyle(color: Colors.red) : null,
      onPressed: onTap,
    );
  }
}
