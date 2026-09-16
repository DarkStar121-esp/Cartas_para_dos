import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_session.dart';
import '../../../core/multiplayer/game_session.dart';
import '../../../core/multiplayer/game_sync_controller.dart';
import '../../../widgets/cards/card_animations.dart';
import '../../../widgets/cards/spanish_card_face.dart' show SpanishCardBack;
import 'uno_engine.dart';

const Map<UnoColor, Color> _colorMap = {
  UnoColor.red: Colors.red,
  UnoColor.yellow: Colors.amber,
  UnoColor.green: Colors.green,
  UnoColor.blue: Colors.blue,
  UnoColor.wild: Colors.black87,
};

/// Versión multijugador: cada celular corre esta pantalla mostrando SOLO
/// la mano de su propio dueño. La mano de la pareja se ve boca abajo
/// (nada más que la cantidad de cartas) — el estado autoritativo vive en
/// GameSyncController, nunca en un motor local "de confianza".
class UnoGameScreen extends StatefulWidget {
  const UnoGameScreen({super.key});

  @override
  State<UnoGameScreen> createState() => _UnoGameScreenState();
}

class _UnoGameScreenState extends State<UnoGameScreen> {
  late final GameSyncController<UnoEngine> _controller;
  UnoEngine? _engine;

  @override
  void initState() {
    super.initState();
    final session = context.read<AppSession>();
    final couple = session.couple!;
    _controller = GameSyncController<UnoEngine>(
      repository: session.gameSessionRepository,
      sessionId: buildGameSessionId(couple.id, 'uno'),
      coupleId: couple.id,
      gameId: 'uno',
      myPlayerIndex: session.myPlayerIndex,
      decode: UnoEngine.fromJson,
      encode: (e) => e.toJson(),
    );
    _controller.connect(buildInitialState: () => UnoEngine(2));
    _controller.stream.listen((engine) => setState(() => _engine = engine));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<UnoColor?> _askColor() {
    return showDialog<UnoColor>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elegí un color'),
        content: Wrap(
          spacing: 12,
          children: [UnoColor.red, UnoColor.yellow, UnoColor.green, UnoColor.blue]
              .map((c) => GestureDetector(
                    onTap: () => Navigator.pop(ctx, c),
                    child: CircleAvatar(backgroundColor: _colorMap[c], radius: 22),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Future<void> _play(int myIndex, UnoCard card) async {
    UnoColor? chosen;
    if (card.color == UnoColor.wild) {
      chosen = await _askColor();
      if (chosen == null) return;
    }
    await _controller.act((e) => e.playCard(myIndex, card, chosenColor: chosen));

    final engine = _engine!;
    if (engine.winner != null && mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(engine.winner == myIndex ? '¡Ganaste! 🎉' : 'Tu pareja ganó esta ronda'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (myIndex == 0) _controller.replaceState(UnoEngine(2));
              },
              child: const Text('Jugar de nuevo'),
            ),
          ],
        ),
      );
    }
  }

  Widget _cardWidget(UnoCard card, {VoidCallback? onTap}) {
    final label = card.value.index <= 9
        ? '${card.value.index}'
        : {
            UnoValue.skip: '⦸',
            UnoValue.reverse: '⟲',
            UnoValue.drawTwo: '+2',
            UnoValue.wild: '★',
            UnoValue.wildDrawFour: '+4',
          }[card.value]!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 80,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: _colorMap[card.color],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white, width: 2),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final engine = _engine;
    final session = context.watch<AppSession>();
    final myIndex = session.myPlayerIndex;

    if (engine == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final myTurn = engine.currentPlayer == myIndex;
    final myHand = engine.hands[myIndex];
    final opponentCount = engine.hands[1 - myIndex].length;

    return Scaffold(
      appBar: AppBar(title: const Text('UNO')),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Text('Tu pareja tiene $opponentCount carta${opponentCount == 1 ? '' : 's'}',
              style: const TextStyle(color: Colors.black54)),
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              children: [
                for (var i = 0; i < opponentCount; i++)
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 2), child: SpanishCardBack(width: 30)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(myTurn ? 'Tu turno' : 'Esperando a tu pareja…', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          PopInCard(key: ValueKey(engine.topCard), child: _cardWidget(engine.topCard)),
          const SizedBox(height: 8),
          Text('Pozo: ${engine.drawPile.length} cartas'),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: myTurn
                ? () => _controller.act((e) {
                      e.drawCard(myIndex);
                      if (e.playableCards(myIndex).isEmpty) {
                        e.currentPlayer = (e.currentPlayer + e.direction) % e.playerCount;
                        if (e.currentPlayer < 0) e.currentPlayer += e.playerCount;
                      }
                    })
                : null,
            icon: const Icon(Icons.download),
            label: const Text('Robar carta'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (var i = 0; i < myHand.length; i++)
                  StaggeredEntrance(
                    index: i,
                    child: _cardWidget(
                      myHand[i],
                      onTap: myTurn && engine.canPlay(myHand[i]) ? () => _play(myIndex, myHand[i]) : null,
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
}
