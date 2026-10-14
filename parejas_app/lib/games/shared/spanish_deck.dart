/// Baraja española de 40 cartas (sin 8 ni 9), la que usan tanto el Truco
/// como el Chinchón. Vive en games/shared/ porque los dos juegos la
/// necesitan igual — ver core/game_registry.dart para cómo se registran
/// los juegos que la consumen.
enum Suit { oro, copa, espada, basto }

extension SuitX on Suit {
  String get label => switch (this) {
        Suit.oro => 'Oro',
        Suit.copa => 'Copa',
        Suit.espada => 'Espada',
        Suit.basto => 'Basto',
      };
}

/// Los diez valores de la baraja española: 1 a 7, y las figuras
/// 10 (Sota), 11 (Caballo), 12 (Rey). No hay 8 ni 9.
enum Rank {
  uno(1),
  dos(2),
  tres(3),
  cuatro(4),
  cinco(5),
  seis(6),
  siete(7),
  sota(10),
  caballo(11),
  rey(12);

  final int value;
  const Rank(this.value);
}

extension RankX on Rank {
  String get shortLabel => switch (this) {
        Rank.sota => 'S',
        Rank.caballo => 'C',
        Rank.rey => 'R',
        _ => '$value',
      };

  bool get isFace => this == Rank.sota || this == Rank.caballo || this == Rank.rey;

  /// Puntaje para Chinchón: las cartas numéricas valen su número, las
  /// figuras (Sota/Caballo/Rey) valen 10 todas por igual.
  int get chinchonPoints => value > 10 ? 10 : value;
}

class SpanishCard {
  final Suit suit;
  final Rank rank;
  const SpanishCard(this.suit, this.rank);

  Map<String, dynamic> toJson() => {'suit': suit.name, 'rank': rank.name};

  factory SpanishCard.fromJson(Map<String, dynamic> json) => SpanishCard(
        Suit.values.byName(json['suit'] as String),
        Rank.values.byName(json['rank'] as String),
      );

  @override
  bool operator ==(Object other) =>
      other is SpanishCard && other.suit == suit && other.rank == rank;

  @override
  int get hashCode => Object.hash(suit, rank);

  @override
  String toString() => '${rank.shortLabel} de ${suit.label.toLowerCase()}';
}

/// Genera las 40 cartas de la baraja, sin barajar.
List<SpanishCard> generateSpanishDeck() {
  final deck = <SpanishCard>[];
  for (final suit in Suit.values) {
    for (final rank in Rank.values) {
      deck.add(SpanishCard(suit, rank));
    }
  }
  return deck;
}
