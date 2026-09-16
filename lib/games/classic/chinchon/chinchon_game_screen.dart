import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_session.dart';
import '../../../core/multiplayer/game_session.dart';
import '../../../core/multiplayer/game_sync_controller.dart';
import '../../../widgets/cards/card_animations.dart';
import '../../../widgets/cards/spanish_card_face.dart';
import '../../shared/spanish_deck.dart';
import 'chinchon_engine.dart';
import 'chinchon_melds.dart';

/// Versión multijugador de Chinchón: cada celular ve solo su propia
/// mano; la de la pareja se ve como cantidad de cartas nada más. El
/// estado de "ya robé este turno" no es una bandera local — se deriva
/// de `hand.length == 8`, así que siempre está sincronizado sin
/// necesidad de mandarlo aparte.
class ChinchonGameScreen extends StatefulWidget {
  const ChinchonGameScreen({super.key});

  @override
  State<ChinchonGameScreen> createState() => _ChinchonGameScreenState();
}

class _ChinchonGameScreenState extends State<ChinchonGameScreen> {
  late final GameSyncController<ChinchonEngine> _controller;
  ChinchonEngine? _engine;
  SpanishCard? _selected;
  bool _summaryShown = false;

  @override
  void initState() {
    super.initState();
    final session = context.read<AppSession>();
    final couple = session.couple!;
    _controller = GameSyncController<ChinchonEngine>(
      repository: session.gameSessionRepository,
      sessionId: buildGameSessionId(couple.id, 'chinchon'),
      coupleId: couple.id,
      gameId: 'chinchon',
      myPlayerIndex: session.myPlayerIndex,
      decode: ChinchonEngine.fromJson,
      encode: (e) => e.toJson(),
    );
    _controller.connect(buildInitialState: () => ChinchonEngine(2));
    _controller.stream.listen((engine) {
      setState(() {
        _engine = engine;
        _selected = null;
      });
      if (engine.roundOver && !_summaryShown) {
        _summaryShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _showRoundSummary());
      } else if (!engine.roundOver) {
        _summaryShown = false;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int get _myIndex => context.read<AppSession>().myPlayerIndex;

  void _draw(bool fromDiscard) {
    _controller.act((e) => fromDiscard ? e.drawFromDiscard(_myIndex) : e.drawFromPile(_myIndex));
  }

  void _discardSelected({bool corte = false}) {
    final card = _selected;
    if (card == null) return;
    setState(() => _selected = null);
    _controller.act((e) => e.discard(_myIndex, card, declaringCorte: corte));
  }

  void _showRoundSummary() {
    final engine = _engine!;
    final myIndex = _myIndex;
    final cutter = engine.roundWinner!;
    final chinchon = engine.roundWinnerHadChinchon == true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(chinchon ? '¡Chinchón! 🎉' : 'Ronda terminada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(cutter == myIndex ? 'Vos cortaste la ronda.' : 'Tu pareja cortó la ronda.'),
            const SizedBox(height: 8),
            for (var p = 0; p < engine.playerCount; p++)
              Text(
                '${p == myIndex ? 'Vos' : 'Tu pareja'}: '
                '${ChinchonMelds.bestPartition(engine.hands[p]).deadwoodPoints} pts sueltos '
                '· Total ${engine.totalScores[p]}',
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (engine.isGameOver) {
                _showGameOver();
              } else if (myIndex == 0) {
                _controller.act((e) => e.startNextRound());
              }
            },
            child: Text(engine.isGameOver ? 'Ver resultado final' : 'Siguiente ronda'),
          ),
        ],
      ),
    );
  }

  void _showGameOver() {
    final engine = _engine!;
    final myIndex = _myIndex;
    final winner = engine.gameWinner!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(winner == myIndex ? '¡Ganaste la partida! 🏆' : 'Tu pareja ganó la partida'),
        content: Text('Puntajes finales: ${engine.totalScores.join(' - ')}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (myIndex == 0) _controller.replaceState(ChinchonEngine(2));
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
    final hasDrawn = hand.length == 8;
    final canCut = myTurn && hasDrawn && _selected != null && engine.canCut(myIndex);
    final opponentCount = engine.hands[1 - myIndex].length;

    return Scaffold(
      appBar: AppBar(title: const Text('Chinchón')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Puntos: ${engine.totalScores.join(' - ')}  ·  Tu pareja tiene $opponentCount cartas',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: myTurn && !hasDrawn ? () => _draw(false) : null,
                  child: Opacity(opacity: myTurn && !hasDrawn ? 1 : 0.4, child: const SpanishCardBack(width: 72)),
                ),
                GestureDetector(
                  onTap: myTurn && !hasDrawn ? () => _draw(true) : null,
                  child: Opacity(
                    opacity: myTurn && !hasDrawn ? 1 : 0.4,
                    child: PopInCard(
                      key: ValueKey(engine.topDiscard),
                      child: SpanishCardFace(card: engine.topDiscard, width: 72),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              !myTurn
                  ? 'Esperando a tu pareja…'
                  : hasDrawn
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
                        onTap: myTurn && hasDrawn ? () => setState(() => _selected = hand[i]) : null,
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
                onPressed: myTurn && hasDrawn && _selected != null ? () => _discardSelected() : null,
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
