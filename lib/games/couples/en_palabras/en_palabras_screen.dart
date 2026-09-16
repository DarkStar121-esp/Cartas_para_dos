import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_session.dart';
import '../../../core/multiplayer/game_session.dart';
import '../../../core/multiplayer/game_sync_controller.dart';
import 'en_palabras_deck.dart';
import 'en_palabras_session.dart';

/// Versión multijugador: quien describe ve la palabra y las prohibidas
/// en su celular; quien adivina ve solo el cronómetro y el puntaje en el
/// suyo (si viera la palabra no tendría sentido el juego). Los roles se
/// intercambian entre rondas con el botón "Cambiar quién describe".
class EnPalabrasScreen extends StatefulWidget {
  const EnPalabrasScreen({super.key});

  @override
  State<EnPalabrasScreen> createState() => _EnPalabrasScreenState();
}

class _EnPalabrasScreenState extends State<EnPalabrasScreen> {
  late final GameSyncController<EnPalabrasSession> _controller;
  EnPalabrasSession? _session;
  Timer? _uiTicker;

  @override
  void initState() {
    super.initState();
    final appSession = context.read<AppSession>();
    final couple = appSession.couple!;
    _controller = GameSyncController<EnPalabrasSession>(
      repository: appSession.gameSessionRepository,
      sessionId: buildGameSessionId(couple.id, 'en_palabras'),
      coupleId: couple.id,
      gameId: 'en_palabras',
      myPlayerIndex: appSession.myPlayerIndex,
      decode: EnPalabrasSession.fromJson,
      encode: (s) => s.toJson(),
    );
    _controller.connect(buildInitialState: () async {
      final deck = await WordDeck.load();
      return EnPalabrasSession(deck: deck);
    });
    _controller.stream.listen((s) => setState(() => _session = s));

    // Solo repinta la UI cada segundo para que el cronómetro se vea
    // andar — el tiempo real se calcula siempre a partir de
    // roundStartedAt, este timer no es la fuente de verdad de nada.
    _uiTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
      _maybeFinishRound();
    });
  }

  @override
  void dispose() {
    _uiTicker?.cancel();
    _controller.dispose();
    super.dispose();
  }

  int get _myIndex => context.read<AppSession>().myPlayerIndex;

  int _secondsLeft(EnPalabrasSession s) {
    if (!s.roundActive || s.roundStartedAt == null) return EnPalabrasSession.roundDuration.inSeconds;
    final elapsed = DateTime.now().difference(s.roundStartedAt!);
    final left = EnPalabrasSession.roundDuration.inSeconds - elapsed.inSeconds;
    return left < 0 ? 0 : left;
  }

  /// Solo quien describe finaliza la ronda cuando se acaba el tiempo —
  /// si los dos dispositivos lo hicieran, se pisarían las escrituras.
  void _maybeFinishRound() {
    final s = _session;
    if (s == null || !s.roundActive) return;
    if (s.describerIndex != _myIndex) return;
    if (_secondsLeft(s) <= 0) {
      _controller.act((e) => e.endRound());
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _session;
    if (s == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final myIndex = _myIndex;
    final iDescribe = s.describerIndex == myIndex;
    final secondsLeft = _secondsLeft(s);

    return Scaffold(
      appBar: AppBar(title: const Text('En Palabras')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('⏱ $secondsLeft s', style: Theme.of(context).textTheme.titleLarge),
                Text('Puntos: ${s.score}', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(child: _buildCenter(s, iDescribe, secondsLeft)),
            const SizedBox(height: 20),
            if (iDescribe && s.roundActive) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _controller.act((e) => e.markResult(correct: false)),
                      child: const Text('Pasar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _controller.act((e) => e.markResult(correct: true)),
                      child: const Text('¡Adivinó!'),
                    ),
                  ),
                ],
              ),
            ] else if (!s.roundActive) ...[
              ElevatedButton(
                onPressed: () => _controller.act((e) => e.startRound(DateTime.now())),
                child: Text(iDescribe ? 'Empezar a describir' : 'Avisale a tu pareja que empiece'),
              ),
              TextButton(
                onPressed: () => _controller.act((e) => e.swapDescriberAndReset()),
                child: const Text('Cambiar quién describe'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCenter(EnPalabrasSession s, bool iDescribe, int secondsLeft) {
    if (!s.roundActive) {
      return Center(
        child: Text(
          iDescribe ? 'Cuando estés listo, arrancás vos' : 'Tu pareja arranca esta ronda',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, color: Colors.black54),
        ),
      );
    }

    if (!iDescribe) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.record_voice_over, size: 48, color: Colors.black38),
            const SizedBox(height: 12),
            const Text('Tu pareja está describiendo…', style: TextStyle(fontSize: 18)),
          ],
        ),
      );
    }

    final card = s.currentCard;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(card.word, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          const Text('No podés decir:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...card.forbidden.map((w) => Text(w, style: const TextStyle(fontSize: 16, color: Colors.black54))),
        ],
      ),
    );
  }
}
