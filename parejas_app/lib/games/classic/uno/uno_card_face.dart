import 'package:flutter/material.dart';
import 'uno_engine.dart';

/// Carta de UNO con el look clásico: óvalo blanco inclinado con el
/// número/símbolo adentro, más los números chicos en las esquinas. Es
/// arte vectorial propio (CustomPaint/widgets, nada de imágenes ni del
/// logo de la marca) — mismo criterio que las cartas españolas: se
/// inspira en la convención visual general de este tipo de juego de
/// cartas de colores, no reproduce el isologo registrado de Mattel.
class UnoCardFace extends StatelessWidget {
  final UnoCard card;
  final double width;

  const UnoCardFace({super.key, required this.card, this.width = 60});

  static const Map<UnoColor, Color> colorMap = {
    UnoColor.red: Color(0xFFE8433D),
    UnoColor.yellow: Color(0xFFF2B705),
    UnoColor.green: Color(0xFF3CA55C),
    UnoColor.blue: Color(0xFF2E6FDB),
    UnoColor.wild: Color(0xFF1C1C1C),
  };

  String? get _text {
    if (card.value.index <= 9) return '${card.value.index}';
    if (card.value == UnoValue.drawTwo) return '+2';
    if (card.value == UnoValue.wildDrawFour) return '+4';
    return null;
  }

  IconData? get _icon => switch (card.value) {
        UnoValue.skip => Icons.block,
        UnoValue.reverse => Icons.compare_arrows_rounded,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final height = width * 1.5;
    final bg = colorMap[card.color]!;
    final isPureWild = card.value == UnoValue.wild;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(width * 0.16),
        border: Border.all(color: Colors.white, width: width * 0.05),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Center(
            child: Transform.rotate(
              angle: -0.35,
              child: Container(
                width: width * 0.85,
                height: height * 0.48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.96),
                  borderRadius: BorderRadius.circular(width),
                ),
                alignment: Alignment.center,
                child: Transform.rotate(
                  angle: 0.35,
                  child: isPureWild
                      ? SizedBox(width: width * 0.42, height: width * 0.42, child: const CustomPaint(painter: _PinwheelPainter()))
                      : _text != null
                          ? Text(_text!,
                              style: TextStyle(color: bg, fontSize: width * 0.42, fontWeight: FontWeight.w900, height: 1))
                          : Icon(_icon, color: bg, size: width * 0.36),
                ),
              ),
            ),
          ),
          _corner(alignment: Alignment.topLeft),
          _corner(alignment: Alignment.bottomRight, flip: true),
        ],
      ),
    );
  }

  Widget _corner({required Alignment alignment, bool flip = false}) {
    final content = _text != null
        ? Text(_text!, style: TextStyle(color: Colors.white, fontSize: width * 0.19, fontWeight: FontWeight.bold))
        : (_icon != null ? Icon(_icon, color: Colors.white, size: width * 0.17) : const SizedBox.shrink());
    return Align(
      alignment: alignment,
      child: Padding(
        padding: EdgeInsets.all(width * 0.09),
        child: flip ? Transform.rotate(angle: 3.14159265, child: content) : content,
      ),
    );
  }
}

/// Dorso de la carta de UNO — mismo lenguaje visual que el frente (óvalo
/// inclinado) pero oscuro, para distinguirlo claramente del mazo español.
class UnoCardBack extends StatelessWidget {
  final double width;
  const UnoCardBack({super.key, this.width = 60});

  @override
  Widget build(BuildContext context) {
    final height = width * 1.5;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(width * 0.16),
        border: Border.all(color: Colors.white, width: width * 0.05),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Center(
        child: Transform.rotate(
          angle: -0.35,
          child: Container(
            width: width * 0.85,
            height: height * 0.48,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(width)),
            alignment: Alignment.center,
            child: Transform.rotate(
              angle: 0.35,
              child: SizedBox(
                width: width * 0.4,
                height: width * 0.4,
                child: const CustomPaint(painter: _PinwheelPainter()),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PinwheelPainter extends CustomPainter {
  const _PinwheelPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final colors = [
      UnoCardFace.colorMap[UnoColor.red]!,
      UnoCardFace.colorMap[UnoColor.blue]!,
      UnoCardFace.colorMap[UnoColor.green]!,
      UnoCardFace.colorMap[UnoColor.yellow]!,
    ];
    for (var i = 0; i < 4; i++) {
      final paint = Paint()..color = colors[i];
      final start = -3.14159265 / 2 + i * (3.14159265 / 2);
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), start, 3.14159265 / 2, true, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
