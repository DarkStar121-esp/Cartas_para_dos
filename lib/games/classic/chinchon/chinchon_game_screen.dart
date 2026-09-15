import 'package:flutter/material.dart';
import '../../shared/spanish_deck.dart';
import '../../../widgets/cards/spanish_card_face.dart';
import '../../../widgets/cards/card_animations.dart';
import 'chinchon_engine.dart';

class ChinchonGameScreen extends StatefulWidget {
  const ChinchonGameScreen({super.key});

  @override
  State<ChinchonGameScreen> createState() => _ChinchonGameScreenState();
}

class _ChinchonGameScreenState extends State<ChinchonGameScreen> {
  late ChinchonEngine _engine;
  SpanishCard? _selected;
  bool _hasDrawnThisTurn = false;

  @override
  void initState() {
    super.initState();
    _engine = ChinchonEngine(2);
  }

  void _draw(bool fromDiscard) {
    setState(() {
      fromDiscard ? _engine.drawFromDiscard(_engine.currentPlayer) : _engine.drawFromPile(_engine.currentPlayer);
      _hasDrawnThisTurn = true;
      _selected = null;
    });
  }

  void _discardSelected({bool corte = false}) {
    if (_selected == null) return;
    setState(() {
      _engine.discard(_engine.currentPlayer, _selected!, declaringCorte: corte);
      _selected = null;
      _hasDrawnThisTurn = false;
    });
    if (_engine.roundOver) _showRoundSummary();
  }

  void _showRoundSummary() {
    final breakdown = _engine.lastRoundBreakdown!;
    final cutter = _engine.roundWinner!;
    final chinchon = _engine.roundWinnerHadChinchon == true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(chinchon ? '¡Chinchón! 🎉' : 'Ronda terminada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jugador ${cutter + 1} cortó la ronda.'),
            const SizedBox(height: 8),
            for (var p = 0; p < _engine.playerCount; p++)
              Text('Jugador ${p + 1}: ${breakdown[p]!.deadwoodPoints} pts sueltos '
                  '· Total ${_engine.totalScores[p]}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (_engine.isGameOver) {
                _showGameOver();
              } else {
                setState(() {
                  _engine.startNextRound();
                  _hasDrawnThisTurn = false;
                });
              }
            },
            child: Text(_engine.isGameOver ? 'Ver resultado final' : 'Siguiente ronda'),
          ),
        ],
      ),
    );
  }

  void _showGameOver() {
    final winner = _engine.gameWinner!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('¡Jugador ${winner + 1} ganó la partida! 🏆'),
        content: Text('Puntajes finales: ${_engine.totalScores.join(' - ')}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _engine = ChinchonEngine(2);
                _hasDrawnThisTurn = false;
              });
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
    final canCut = _hasDrawnThisTurn && _selected != null && _engine.canCut(current);

    return Scaffold(
      appBar: AppBar(title: const Text('Chinchón')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Turno: Jugador ${current + 1}  ·  Puntos: ${_engine.totalScores.join(' - ')}',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Mazo (boca abajo)
                GestureDetector(
                  onTap: _hasDrawnThisTurn ? null : () => _draw(false),
                  child: Opacity(
                    opacity: _hasDrawnThisTurn ? 0.4 : 1,
                    child: const SpanishCardBack(width: 72),
                  ),
                ),
                // Pozo de descarte (boca arriba)
                GestureDetector(
                  onTap: _hasDrawnThisTurn ? null : () => _draw(true),
                  child: Opacity(
                    opacity: _hasDrawnThisTurn ? 0.4 : 1,
                    child: PopInCard(
                      key: ValueKey(_engine.topDiscard),
                      child: SpanishCardFace(card: _engine.topDiscard, width: 72),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _hasDrawnThisTurn
                  ? 'Elegí una carta para descartar'
                  : 'Robá del mazo o del pozo',
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (var i = 0; i < hand.length; i++)
                  StaggeredEntrance(
                    index: i,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => setState(() => _selected = hand[i]),
                        child: AnimatedSlide(
                          duration: const Duration(milliseconds: 200),
                          offset: _selected == hand[i] ? const Offset(0, -0.15) : Offset.zero,
                          child: SpanishCardFace(card: hand[i], width: 68),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _hasDrawnThisTurn && _selected != null ? () => _discardSelected() : null,
                icon: const Icon(Icons.file_upload_outlined),
                label: const Text('Descartar'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: canCut ? () => _discardSelected(corte: true) : null,
                icon: const Icon(Icons.flag),
                label: const Text('Cortar'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
