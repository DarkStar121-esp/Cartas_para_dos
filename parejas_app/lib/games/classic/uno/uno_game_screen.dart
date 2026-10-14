import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_session.dart';
import '../../../core/multiplayer/game_session.dart';
import '../../../core/multiplayer/game_sync_controller.dart';
import '../../../widgets/cards/card_animations.dart';
import 'uno_card_face.dart';
import 'uno_engine.dart';

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
                    child: CircleAvatar(backgroundColor: UnoCardFace.colorMap[c], radius: 22),
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

  /// Robar SIEMPRE termina el turno — ya sea que la carta robada se
  /// pueda jugar o no. Antes solo pasaba el turno si la carta era
  /// injugable, lo que dejaba robar de nuevo sin límite; ahora el botón
  /// queda deshabilitado apenas cambia `currentPlayer`.
  void _drawAndPassTurn(int myIndex) {
    _controller.act((e) {
      e.drawCard(myIndex);
      e.currentPlayer = (e.currentPlayer + e.direction) % e.playerCount;
      if (e.currentPlayer < 0) e.currentPlayer += e.playerCount;
    });
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
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              children: [
                for (var i = 0; i < opponentCount; i++)
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 2), child: UnoCardBack(width: 28)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              myTurn ? 'Tu turno' : 'Esperando a tu pareja…',
              key: ValueKey(myTurn),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 16),
          PopInCard(key: ValueKey(engine.topCard), child: UnoCardFace(card: engine.topCard, width: 74)),
          const SizedBox(height: 8),
          Text('Mazo: ${engine.drawPile.length} cartas', style: const TextStyle(color: Colors.black54)),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: myTurn ? () => _drawAndPassTurn(myIndex) : null,
            icon: const Icon(Icons.download),
            label: const Text('Robar carta'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (var i = 0; i < myHand.length; i++)
                  StaggeredEntrance(
                    index: i,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      // Leve abanico: las cartas de las puntas se inclinan
                      // y suben un poco menos que las del medio, como una
                      // mano de cartas sostenida en la mano.
                      child: Transform.translate(
                        offset: Offset(0, (i - (myHand.length - 1) / 2).abs() * 3),
                        child: Transform.rotate(
                          angle: (i - (myHand.length - 1) / 2) * 0.05,
                          child: GestureDetector(
                            onTap: myTurn && engine.canPlay(myHand[i]) ? () => _play(myIndex, myHand[i]) : null,
                            child: AnimatedScale(
                              duration: const Duration(milliseconds: 150),
                              scale: myTurn && engine.canPlay(myHand[i]) ? 1.0 : 0.94,
                              child: UnoCardFace(card: myHand[i], width: 62),
                            ),
                          ),
                        ),
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
}
