import '../../shared/spanish_deck.dart';

/// Resultado de partir una mano en combinaciones válidas: qué grupos se
/// formaron y qué cartas quedaron sueltas (deadwood) con su puntaje.
class MeldResult {
  final List<List<SpanishCard>> melds;
  final List<SpanishCard> deadwood;
  final int deadwoodPoints;
  const MeldResult(this.melds, this.deadwood, this.deadwoodPoints);
}

/// Encuentra, para una mano de Chinchón, la partición en escaleras
/// (3+ cartas consecutivas del mismo palo) y tríos/cuartetos (3+ cartas
/// del mismo valor, palos distintos) que **minimiza los puntos de las
/// cartas sueltas**. Es fuerza bruta con memoización por bitmask: la
/// mano nunca tiene más de 8 cartas (7 en reposo, 8 recién robada), así
/// que el espacio de estados es chico (como mucho 2^8 = 256) y esto
/// corre instantáneo.
class ChinchonMelds {
  static MeldResult bestPartition(List<SpanishCard> hand) {
    final n = hand.length;
    final allMelds = _findAllValidMelds(hand);
    final meldMasks = [for (final m in allMelds) _maskFor(hand, m)];
    final memo = <int, MeldResult>{};

    MeldResult solve(int remainingMask) {
      final cached = memo[remainingMask];
      if (cached != null) return cached;

      final deadwoodCards = [
        for (var i = 0; i < n; i++)
          if ((remainingMask & (1 << i)) != 0) hand[i],
      ];
      var best = MeldResult(
        const [],
        deadwoodCards,
        deadwoodCards.fold(0, (sum, c) => sum + c.rank.chinchonPoints),
      );

      for (var mi = 0; mi < meldMasks.length; mi++) {
        final meldMask = meldMasks[mi];
        if ((meldMask & remainingMask) == meldMask) {
          final sub = solve(remainingMask & ~meldMask);
          if (sub.deadwoodPoints < best.deadwoodPoints) {
            best = MeldResult([allMelds[mi], ...sub.melds], sub.deadwood, sub.deadwoodPoints);
          }
        }
      }

      memo[remainingMask] = best;
      return best;
    }

    return solve((1 << n) - 1);
  }

  /// true si las 7 cartas forman UNA sola escalera (chinchón: solo es
  /// posible con una escalera de As a 7 del mismo palo, ya que la
  /// baraja española no tiene 8 ni 9 y las figuras solo suman 3 valores).
  static bool isChinchon(List<SpanishCard> sevenCards) {
    if (sevenCards.length != 7) return false;
    final result = bestPartition(sevenCards);
    return result.deadwoodPoints == 0 && result.melds.length == 1;
  }

  static int _maskFor(List<SpanishCard> hand, List<SpanishCard> meld) {
    var mask = 0;
    for (final c in meld) {
      mask |= 1 << hand.indexOf(c);
    }
    return mask;
  }

  static List<List<SpanishCard>> _findAllValidMelds(List<SpanishCard> hand) {
    final result = <List<SpanishCard>>[];
    for (var size = 3; size <= hand.length; size++) {
      for (final combo in _combinations(hand, size)) {
        if (_isValidSet(combo) || _isValidRun(combo)) result.add(combo);
      }
    }
    return result;
  }

  static bool _isValidSet(List<SpanishCard> cards) {
    final rank = cards.first.rank;
    if (!cards.every((c) => c.rank == rank)) return false;
    return cards.map((c) => c.suit).toSet().length == cards.length;
  }

  static bool _isValidRun(List<SpanishCard> cards) {
    final suit = cards.first.suit;
    if (!cards.every((c) => c.suit == suit)) return false;
    final sorted = [...cards]..sort((a, b) => a.rank.value.compareTo(b.rank.value));
    for (var i = 1; i < sorted.length; i++) {
      if (_nextRankValue(sorted[i - 1].rank) != sorted[i].rank.value) return false;
    }
    return true;
  }

  /// Orden de "consecutividad" en la baraja española: 1,2,3,4,5,6,7,
  /// salta directo a 10 (Sota), 11 (Caballo), 12 (Rey) — es decir, 7 y
  /// Sota SÍ son consecutivos para armar una escalera.
  static int _nextRankValue(Rank r) {
    const order = [1, 2, 3, 4, 5, 6, 7, 10, 11, 12];
    final idx = order.indexOf(r.value);
    return (idx == -1 || idx == order.length - 1) ? -1 : order[idx + 1];
  }

  static Iterable<List<SpanishCard>> _combinations(List<SpanishCard> list, int size) sync* {
    final n = list.length;
    if (size > n) return;
    final indices = List.generate(size, (i) => i);
    while (true) {
      yield [for (final i in indices) list[i]];
      var i = size - 1;
      while (i >= 0 && indices[i] == i + n - size) {
        i--;
      }
      if (i < 0) return;
      indices[i]++;
      for (var j = i + 1; j < size; j++) {
        indices[j] = indices[j - 1] + 1;
      }
    }
  }
}
