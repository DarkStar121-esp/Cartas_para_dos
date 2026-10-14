import '../../shared/spanish_deck.dart';

/// Jerarquía de poder del Truco Argentino, de más fuerte a más débil:
///  14 — 1 de espada (macho)
///  13 — 1 de basto (hembra)
///  12 — 7 de espada
///  11 — 7 de oro
///  10 — los cuatro 3
///   9 — los cuatro 2
///   8 — 1 de oro y 1 de copa (ases falsos)
///   7 — los cuatro Rey (12)
///   6 — los cuatro Caballo (11)
///   5 — los cuatro Sota (10)
///   4 — 7 de copa y 7 de basto (sietes falsos)
///   3 — los cuatro 6
///   2 — los cuatro 5
///   1 — los cuatro 4
int trucoPower(SpanishCard c) {
  if (c.suit == Suit.espada && c.rank == Rank.uno) return 14;
  if (c.suit == Suit.basto && c.rank == Rank.uno) return 13;
  if (c.suit == Suit.espada && c.rank == Rank.siete) return 12;
  if (c.suit == Suit.oro && c.rank == Rank.siete) return 11;
  if (c.rank == Rank.tres) return 10;
  if (c.rank == Rank.dos) return 9;
  if (c.rank == Rank.uno) return 8; // oro o copa — los de espada/basto ya volvieron arriba
  if (c.rank == Rank.rey) return 7;
  if (c.rank == Rank.caballo) return 6;
  if (c.rank == Rank.sota) return 5;
  if (c.rank == Rank.siete) return 4; // copa o basto — los otros dos ya volvieron arriba
  if (c.rank == Rank.seis) return 3;
  if (c.rank == Rank.cinco) return 2;
  return 1; // los cuatro 4
}

/// Valor de una carta para el cálculo de envido: las numéricas (1 a 7)
/// valen su número, las figuras (Sota/Caballo/Rey) valen 0.
int envidoCardValue(SpanishCard c) => c.rank.value > 7 ? 0 : c.rank.value;

/// Envido de una mano de 3 cartas: se suman las dos cartas más altas del
/// MISMO palo + 20. Si no hay dos cartas del mismo palo, el envido es el
/// valor de la carta más alta sola (sin el +20).
int calculateEnvido(List<SpanishCard> hand) {
  final bySuit = <Suit, List<SpanishCard>>{};
  for (final c in hand) {
    bySuit.putIfAbsent(c.suit, () => []).add(c);
  }

  var best = 0;
  for (final cards in bySuit.values) {
    if (cards.length >= 2) {
      final values = cards.map(envidoCardValue).toList()..sort((a, b) => b.compareTo(a));
      final pairSum = values[0] + values[1] + 20;
      if (pairSum > best) best = pairSum;
    }
  }

  if (best == 0) {
    best = hand.map(envidoCardValue).reduce((a, b) => a > b ? a : b);
  }
  return best;
}
