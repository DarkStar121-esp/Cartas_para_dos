import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../games/shared/spanish_deck.dart';

/// Ilustración de cartas 100% propia, dibujada a mano con CustomPainter
/// (nada de imágenes bajadas de internet — evita cualquier lío de
/// copyright con mazos españoles existentes tipo Fournier). Pinta los
/// cuatro palos (oro/copa/espada/basto) como íconos vectoriales simples
/// con color propio por palo, y una silueta básica para las figuras
/// (Sota/Caballo/Rey).
class SpanishCardFace extends StatelessWidget {
  final SpanishCard card;
  final double width;

  const SpanishCardFace({super.key, required this.card, this.width = 64});

  @override
  Widget build(BuildContext context) {
    final height = width * 1.45;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(width * 0.12),
        border: Border.all(color: Colors.black87, width: 1.2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: CustomPaint(
        size: Size(width, height),
        painter: _SpanishCardPainter(card: card),
      ),
    );
  }
}

/// Dorso de la carta — diseño propio (gradiente + corazón), consistente
/// con la identidad visual de la app.
class SpanishCardBack extends StatelessWidget {
  final double width;
  const SpanishCardBack({super.key, this.width = 64});

  @override
  Widget build(BuildContext context) {
    final height = width * 1.45;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width * 0.12),
        border: Border.all(color: Colors.white, width: 1.2),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6A3DE8), Color(0xFF9C6BFF)],
        ),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Center(
        child: Icon(Icons.favorite, color: Colors.white.withOpacity(0.85), size: width * 0.4),
      ),
    );
  }
}

class _SpanishCardPainter extends CustomPainter {
  final SpanishCard card;
  _SpanishCardPainter({required this.card});

  static const Map<Suit, Color> _suitColors = {
    Suit.oro: Color(0xFFC8952A),
    Suit.copa: Color(0xFFC1272D),
    Suit.espada: Color(0xFF2E4A7A),
    Suit.basto: Color(0xFF4C7A3A),
  };

  @override
  void paint(Canvas canvas, Size size) {
    final color = _suitColors[card.suit]!;
    _paintCorner(canvas, size, color, topLeft: true);
    _paintCorner(canvas, size, color, topLeft: false);

    if (card.rank.isFace) {
      _paintFaceCard(canvas, size, color);
    } else {
      for (final p in _pipLayout(card.rank.value)) {
        canvas.save();
        canvas.translate(p.dx * size.width, p.dy * size.height);
        _paintSuitIcon(canvas, color, size.width * 0.13);
        canvas.restore();
      }
    }
  }

  void _paintCorner(Canvas canvas, Size size, Color color, {required bool topLeft}) {
    final tp = TextPainter(
      text: TextSpan(
        text: card.rank.shortLabel,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: size.width * 0.17),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    if (!topLeft) {
      canvas.translate(size.width, size.height);
      canvas.rotate(math.pi);
    }
    tp.paint(canvas, Offset(size.width * 0.06, size.height * 0.025));
    canvas.translate(size.width * 0.06 + tp.width / 2, size.height * 0.03 + tp.height + size.width * 0.1);
    _paintSuitIcon(canvas, color, size.width * 0.1);
    canvas.restore();
  }

  void _paintFaceCard(Canvas canvas, Size size, Color color) {
    final center = Offset(size.width / 2, size.height / 2);
    final frameRect = Rect.fromCenter(center: center, width: size.width * 0.62, height: size.height * 0.5);

    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, Radius.circular(8)),
      Paint()..color = color.withOpacity(0.13),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, Radius.circular(8)),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    canvas.save();
    canvas.translate(center.dx, center.dy - size.height * 0.06);
    switch (card.rank) {
      case Rank.rey:
        _paintCrown(canvas, color, size.width * 0.22);
        break;
      case Rank.caballo:
        _paintHorseHead(canvas, color, size.width * 0.22);
        break;
      case Rank.sota:
        _paintPage(canvas, color, size.width * 0.22);
        break;
      default:
        break;
    }
    canvas.restore();

    canvas.save();
    canvas.translate(center.dx, center.dy + size.height * 0.15);
    _paintSuitIcon(canvas, color, size.width * 0.14);
    canvas.restore();
  }

  void _paintSuitIcon(Canvas canvas, Color color, double r) {
    switch (card.suit) {
      case Suit.oro:
        canvas.drawCircle(Offset.zero, r, Paint()..color = color);
        canvas.drawCircle(
          Offset.zero,
          r * 0.55,
          Paint()
            ..color = Colors.white.withOpacity(0.85)
            ..style = PaintingStyle.stroke
            ..strokeWidth = r * 0.16,
        );
        break;
      case Suit.copa:
        _paintCup(canvas, color, r);
        break;
      case Suit.espada:
        _paintSword(canvas, color, r);
        break;
      case Suit.basto:
        _paintClub(canvas, color, r);
        break;
    }
  }

  void _paintCup(Canvas canvas, Color color, double r) {
    final paint = Paint()..color = color;
    final bowl = Path()
      ..moveTo(-r * 0.7, -r)
      ..lineTo(r * 0.7, -r)
      ..lineTo(r * 0.32, r * 0.3)
      ..lineTo(-r * 0.32, r * 0.3)
      ..close();
    canvas.drawPath(bowl, paint);
    canvas.drawRect(Rect.fromCenter(center: Offset(0, r * 0.55), width: r * 0.18, height: r * 0.5), paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, r * 0.95), width: r * 0.9, height: r * 0.18),
        Radius.circular(r * 0.1),
      ),
      paint,
    );
  }

  void _paintSword(Canvas canvas, Color color, double r) {
    final paint = Paint()..color = color;
    canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: r * 0.2, height: r * 1.7), paint);
    canvas.drawRect(Rect.fromCenter(center: Offset(0, -r * 0.35), width: r * 0.9, height: r * 0.15), paint);
    canvas.drawCircle(Offset(0, -r * 0.95), r * 0.16, paint);
    final tip = Path()
      ..moveTo(-r * 0.1, r * 0.75)
      ..lineTo(r * 0.1, r * 0.75)
      ..lineTo(0, r * 1.05)
      ..close();
    canvas.drawPath(tip, paint);
  }

  void _paintClub(Canvas canvas, Color color, double r) {
    final paint = Paint()..color = color;
    canvas.save();
    canvas.rotate(math.pi / 5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: r * 0.48, height: r * 1.7),
        Radius.circular(r * 0.25),
      ),
      paint,
    );
    canvas.drawCircle(Offset(0, -r * 0.55), r * 0.16, paint);
    canvas.drawCircle(Offset(0, r * 0.3), r * 0.16, paint);
    canvas.restore();
  }

  void _paintCrown(Canvas canvas, Color color, double r) {
    final path = Path()
      ..moveTo(-r, r * 0.5)
      ..lineTo(-r, -r * 0.1)
      ..lineTo(-r * 0.5, r * 0.35)
      ..lineTo(0, -r * 0.5)
      ..lineTo(r * 0.5, r * 0.35)
      ..lineTo(r, -r * 0.1)
      ..lineTo(r, r * 0.5)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _paintHorseHead(Canvas canvas, Color color, double r) {
    final path = Path()
      ..moveTo(-r * 0.3, r * 0.6)
      ..quadraticBezierTo(-r * 0.9, r * 0.1, -r * 0.5, -r * 0.5)
      ..quadraticBezierTo(-r * 0.1, -r, r * 0.5, -r * 0.7)
      ..quadraticBezierTo(r * 0.3, -r * 0.4, r * 0.6, -r * 0.3)
      ..quadraticBezierTo(r * 0.2, -r * 0.2, r * 0.2, r * 0.1)
      ..quadraticBezierTo(r * 0.4, r * 0.3, r * 0.2, r * 0.6)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _paintPage(Canvas canvas, Color color, double r) {
    final paint = Paint()..color = color;
    canvas.drawCircle(Offset(0, -r * 0.5), r * 0.4, paint);
    final body = Path()
      ..moveTo(-r * 0.5, r * 0.7)
      ..quadraticBezierTo(-r * 0.5, -r * 0.1, 0, -r * 0.05)
      ..quadraticBezierTo(r * 0.5, -r * 0.1, r * 0.5, r * 0.7)
      ..close();
    canvas.drawPath(body, paint);
  }

  List<Offset> _pipLayout(int count) {
    switch (count) {
      case 1:
        return const [Offset(0.5, 0.5)];
      case 2:
        return const [Offset(0.5, 0.28), Offset(0.5, 0.72)];
      case 3:
        return const [Offset(0.5, 0.22), Offset(0.5, 0.5), Offset(0.5, 0.78)];
      case 4:
        return const [
          Offset(0.32, 0.28), Offset(0.68, 0.28),
          Offset(0.32, 0.72), Offset(0.68, 0.72),
        ];
      case 5:
        return const [
          Offset(0.32, 0.26), Offset(0.68, 0.26),
          Offset(0.5, 0.5),
          Offset(0.32, 0.74), Offset(0.68, 0.74),
        ];
      case 6:
        return const [
          Offset(0.32, 0.22), Offset(0.68, 0.22),
          Offset(0.32, 0.5), Offset(0.68, 0.5),
          Offset(0.32, 0.78), Offset(0.68, 0.78),
        ];
      default: // 7
        return const [
          Offset(0.32, 0.16), Offset(0.68, 0.16),
          Offset(0.5, 0.36),
          Offset(0.32, 0.56), Offset(0.68, 0.56),
          Offset(0.32, 0.84), Offset(0.68, 0.84),
        ];
    }
  }

  @override
  bool shouldRepaint(covariant _SpanishCardPainter oldDelegate) => oldDelegate.card != card;
}
