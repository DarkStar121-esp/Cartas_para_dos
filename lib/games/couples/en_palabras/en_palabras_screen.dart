import 'dart:async';
import 'package:flutter/material.dart';
import 'en_palabras_deck.dart';

/// Uno describe la palabra de arriba sin decir ninguna de las
/// prohibidas, el otro adivina. 60 segundos por turno.
class EnPalabrasScreen extends StatefulWidget {
  const EnPalabrasScreen({super.key});

  @override
  State<EnPalabrasScreen> createState() => _EnPalabrasScreenState();
}

class _EnPalabrasScreenState extends State<EnPalabrasScreen> {
  List<WordCard> _deck = [];
  int _index = 0;
  int _score = 0;
  int _secondsLeft = 60;
  Timer? _timer;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final deck = await WordDeck.load();
    setState(() {
      _deck = deck;
      _loading = false;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
        _showRoundEnd();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _next({required bool correct}) {
    if (correct) _score++;
    setState(() {
      _index = (_index + 1) % _deck.length;
    });
  }

  void _showRoundEnd() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¡Se acabó el tiempo!'),
        content: Text('Adivinaron $_score palabras.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _score = 0);
              _startTimer();
            },
            child: const Text('Jugar otra ronda'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final card = _deck[_index];
    return Scaffold(
      appBar: AppBar(title: const Text('En Palabras')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('⏱ $_secondsLeft s',
                    style: Theme.of(context).textTheme.titleLarge),
                Text('Puntos: $_score',
                    style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(card.word,
                        style: const TextStyle(
                            fontSize: 34, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    const Text('No podés decir:',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ...card.forbidden.map((w) => Text(w,
                        style: const TextStyle(
                            fontSize: 16, color: Colors.black54))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _next(correct: false),
                    child: const Text('Pasar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _next(correct: true),
                    child: const Text('¡Adivinó!'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
