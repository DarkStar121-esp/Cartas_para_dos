import 'dart:math';

enum UnoColor { red, yellow, green, blue, wild }

enum UnoValue {
  zero, one, two, three, four, five, six, seven, eight, nine,
  skip, reverse, drawTwo, wild, wildDrawFour,
}

class UnoCard {
  final UnoColor color;
  final UnoValue value;
  const UnoCard(this.color, this.value);

  bool matches(UnoCard other) =>
      color == UnoColor.wild ||
      other.color == UnoColor.wild ||
      color == other.color ||
      value == other.value;

  @override
  String toString() => '${color.name}-${value.name}';
}

/// Motor de reglas de UNO, sin ninguna dependencia de Flutter.
/// Se puede testear con `dart test` de forma aislada de la UI.
///
/// NOTA: implementa las reglas base (skip, reverse, +2, comodín,
/// +4). No implementa reglas de torneo (acumulación de +2/+4,
/// desafío de +4, UNO callout). Son el siguiente paso natural.
class UnoEngine {
  final int playerCount;
  final List<UnoCard> drawPile = [];
  final List<UnoCard> discardPile = [];
  late final List<List<UnoCard>> hands;
  int currentPlayer = 0;
  int direction = 1;
  int? winner;

  UnoEngine(this.playerCount, {Random? random}) {
    hands = List.generate(playerCount, (_) => <UnoCard>[]);
    _buildDeck();
    drawPile.shuffle(random ?? Random());
    _dealInitialHands();
    // La primera carta del descarte no debería ser un comodín +4.
    discardPile.add(drawPile.removeLast());
  }

  UnoCard get topCard => discardPile.last;

  bool canPlay(UnoCard card) => card.matches(topCard);

  List<UnoCard> playableCards(int player) =>
      hands[player].where(canPlay).toList();

  void playCard(int player, UnoCard card, {UnoColor? chosenColor}) {
    assert(canPlay(card), 'Carta inválida para el pozo actual');
    hands[player].remove(card);

    // Si es comodín, se reemplaza el color por el elegido para
    // que las próximas comparaciones (matches) funcionen bien.
    final placed = (card.color == UnoColor.wild && chosenColor != null)
        ? UnoCard(chosenColor, card.value)
        : card;
    discardPile.add(placed);

    if (hands[player].isEmpty) {
      winner = player;
      return;
    }
    _applyEffect(placed);
  }

  void drawCard(int player) {
    if (drawPile.isEmpty) _reshuffleFromDiscard();
    if (drawPile.isEmpty) return; // no quedan cartas en ningún lado
    hands[player].add(drawPile.removeLast());
  }

  void _buildDeck() {
    for (final color in [
      UnoColor.red,
      UnoColor.yellow,
      UnoColor.green,
      UnoColor.blue,
    ]) {
      drawPile.add(UnoCard(color, UnoValue.zero));
      for (final value in [
        UnoValue.one, UnoValue.two, UnoValue.three, UnoValue.four,
        UnoValue.five, UnoValue.six, UnoValue.seven, UnoValue.eight,
        UnoValue.nine, UnoValue.skip, UnoValue.reverse, UnoValue.drawTwo,
      ]) {
        drawPile.add(UnoCard(color, value));
        drawPile.add(UnoCard(color, value));
      }
    }
    for (var i = 0; i < 4; i++) {
      drawPile.add(const UnoCard(UnoColor.wild, UnoValue.wild));
      drawPile.add(const UnoCard(UnoColor.wild, UnoValue.wildDrawFour));
    }
  }

  void _dealInitialHands() {
    for (var i = 0; i < 7; i++) {
      for (var p = 0; p < playerCount; p++) {
        hands[p].add(drawPile.removeLast());
      }
    }
  }

  void _applyEffect(UnoCard card) {
    switch (card.value) {
      case UnoValue.skip:
        _advanceTurn();
        _advanceTurn();
        break;
      case UnoValue.reverse:
        direction *= -1;
        _advanceTurn();
        break;
      case UnoValue.drawTwo:
        _advanceTurn();
        drawCard(currentPlayer);
        drawCard(currentPlayer);
        _advanceTurn();
        break;
      case UnoValue.wildDrawFour:
        _advanceTurn();
        for (var i = 0; i < 4; i++) {
          drawCard(currentPlayer);
        }
        _advanceTurn();
        break;
      default:
        _advanceTurn();
        break;
    }
  }

  void _advanceTurn() {
    currentPlayer = (currentPlayer + direction) % playerCount;
    if (currentPlayer < 0) currentPlayer += playerCount;
  }

  void _reshuffleFromDiscard() {
    if (discardPile.length <= 1) return;
    final top = discardPile.removeLast();
    drawPile.addAll(discardPile);
    discardPile
      ..clear()
      ..add(top);
    drawPile.shuffle(Random());
  }
}
