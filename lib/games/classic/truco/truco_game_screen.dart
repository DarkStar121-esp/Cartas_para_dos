import 'package:flutter/material.dart';
import '../../shared/spanish_deck.dart';
import '../../../widgets/cards/spanish_card_face.dart';
import '../../../widgets/cards/card_animations.dart';
import 'truco_engine.dart';

class TrucoGameScreen extends StatefulWidget {
  const TrucoGameScreen({super.key});

  @override
  State<TrucoGameScreen> createState() => _TrucoGameScreenState();
}

class _TrucoGameScreenState extends State<TrucoGameScreen> {
  late TrucoEngine _engine;

  @override
  void initState() {
    super.initState();
    _engine = TrucoEngine();
  }

  void _afterAction(VoidCallback action) {
    setState(action);
    if (_engine.phase == TrucoPhase.manoFinished) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showManoResult());
    }
  }

  void _showManoResult() {
    if (_engine.phase == TrucoPhase.gameFinished) {
      _showGameOver();
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('Jugador ${_engine.manoWinner! + 1} se llevó la mano'),
        content: Text('Puntaje: ${_engine.scores[0]} - ${_engine.scores[1]}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _engine.startNextMano());
            },
            child: const Text('Siguiente mano'),
          ),
        ],
      ),
    );
  }

  void _showGameOver() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¡Jugador ${_engine.gameWinner! + 1} ganó la partida! 🏆'),
        content: Text('${_engine.scores[0]} - ${_engine.scores[1]}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _engine = TrucoEngine());
            },
            child: const Text('Jugar de nuevo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _engine.currentPlayer;
    final hand = _engine.hands[current];

    return Scaffold(
      appBar: AppBar(title: const Text('Truco')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Puntos: ${_engine.scores[0]} - ${_engine.scores[1]}  ·  Mano: Jugador ${_engine.manoPlayer + 1}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(child: _buildTable(context)),
          _buildCantoBar(context),
          const SizedBox(height: 8),
          Text('Turno: Jugador ${current + 1}', style: Theme.of(context).textTheme.titleSmall),
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
                        onTap: _engine.phase == TrucoPhase.playing
                            ? () => _afterAction(() => _engine.playCard(current, hand[i]))
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

  Widget _buildTable(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (var trick = 0; trick < 3; trick++)
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _trickSlot(_engine.playedCards[0][trick]),
              const SizedBox(height: 8),
              _trickSlot(_engine.playedCards[1][trick]),
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
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }
    return PopInCard(key: ValueKey(card), child: SpanishCardFace(card: card, width: 60));
  }

  Widget _buildCantoBar(BuildContext context) {
    if (_engine.phase == TrucoPhase.awaitingEnvidoResponse) {
      final label = switch (_engine.pendingEnvidoCall!) {
        EnvidoCall.envido => 'Envido',
        EnvidoCall.realEnvido => 'Real Envido',
        EnvidoCall.faltaEnvido => 'Falta Envido',
      };
      return _responseBar('¿Aceptás el $label?', () => _afterAction(() => _engine.respondEnvido(true)),
          () => _afterAction(() => _engine.respondEnvido(false)));
    }

    if (_engine.phase == TrucoPhase.awaitingTrucoResponse) {
      final label = switch (_engine.pendingTrucoLevel) {
        TrucoLevel.truco => 'Truco',
        TrucoLevel.retruco => 'Retruco',
        TrucoLevel.valeCuatro => 'Vale Cuatro',
        TrucoLevel.none => '',
      };
      return _responseBar('¿Aceptás el $label?', () => _afterAction(() => _engine.respondTruco(true)),
          () => _afterAction(() => _engine.respondTruco(false)));
    }

    final current = _engine.currentPlayer;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        if (_engine.canCallEnvido) ...[
          _cantoChip('Envido', () => _afterAction(() => _engine.callEnvido(current, EnvidoCall.envido))),
          _cantoChip('Real Envido', () => _afterAction(() => _engine.callEnvido(current, EnvidoCall.realEnvido))),
          _cantoChip('Falta Envido', () => _afterAction(() => _engine.callEnvido(current, EnvidoCall.faltaEnvido))),
        ],
        if (_engine.canCallTruco) _cantoChip('Truco', () => _afterAction(() => _engine.callTruco(current))),
        if (_engine.canRaiseTruco(current))
          _cantoChip(
            _engine.acceptedTrucoLevel == TrucoLevel.truco ? 'Retruco' : 'Vale Cuatro',
            () => _afterAction(() => _engine.raiseTruco(current)),
          ),
        _cantoChip('Me voy al mazo', () => _afterAction(() => _engine.foldMano(current)), danger: true),
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
