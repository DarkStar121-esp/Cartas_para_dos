import 'package:flutter/material.dart';
import 'uno_engine.dart';

const Map<UnoColor, Color> _colorMap = {
  UnoColor.red: Colors.red,
  UnoColor.yellow: Colors.amber,
  UnoColor.green: Colors.green,
  UnoColor.blue: Colors.blue,
  UnoColor.wild: Colors.black87,
};

/// UI simple "pasar y jugar" para 2 jugadores en el mismo dispositivo.
/// Es intencionalmente básica: el objetivo de este archivo es mostrar
/// cómo una pantalla de juego consume el UnoEngine, no ser la versión
/// final de la interfaz (eso lo definirá el diseño visual de la app).
class UnoGameScreen extends StatefulWidget {
  const UnoGameScreen({super.key});

  @override
  State<UnoGameScreen> createState() => _UnoGameScreenState();
}

class _UnoGameScreenState extends State<UnoGameScreen> {
  late UnoEngine _engine;

  @override
  void initState() {
    super.initState();
    _engine = UnoEngine(2);
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

  Future<void> _play(UnoCard card) async {
    UnoColor? chosen;
    if (card.color == UnoColor.wild) {
      chosen = await _askColor();
      if (chosen == null) return; // canceló
    }
    setState(() => _engine.playCard(_engine.currentPlayer, card, chosenColor: chosen));

    if (_engine.winner != null && mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('¡Jugador ${_engine.winner! + 1} ganó! 🎉'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _engine = UnoEngine(2));
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
        child: Text(
          label,
          style: const TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _engine.currentPlayer;
    final hand = _engine.hands[current];

    return Scaffold(
      appBar: AppBar(title: const Text('UNO')),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Text('Turno: Jugador ${current + 1}',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 24),
          _cardWidget(_engine.topCard),
          const SizedBox(height: 8),
          Text('Pozo: ${_engine.drawPile.length} cartas'),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => setState(() {
              _engine.drawCard(current);
              if (_engine.playableCards(current).isEmpty) {
                // si sigue sin poder jugar, pasa el turno
                _engine.currentPlayer =
                    (_engine.currentPlayer + _engine.direction) % _engine.playerCount;
              }
            }),
            icon: const Icon(Icons.download),
            label: const Text('Robar carta'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: hand
                  .map((c) => _cardWidget(
                        c,
                        onTap: _engine.canPlay(c) ? () => _play(c) : null,
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
