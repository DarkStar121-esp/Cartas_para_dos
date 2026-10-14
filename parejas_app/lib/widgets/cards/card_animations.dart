import 'package:flutter/material.dart';

/// Flip 3D suave entre el dorso y el frente de una carta (por ejemplo, al
/// robar del mazo). Técnica estándar de Flutter: rota en el eje Y con
/// perspectiva y cambia qué cara se muestra a mitad de la animación.
class FlippableCard extends StatefulWidget {
  final Widget front;
  final Widget back;
  final bool showFront;
  final Duration duration;

  const FlippableCard({
    super.key,
    required this.front,
    required this.back,
    required this.showFront,
    this.duration = const Duration(milliseconds: 400),
  });

  @override
  State<FlippableCard> createState() => _FlippableCardState();
}

class _FlippableCardState extends State<FlippableCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration, value: widget.showFront ? 1 : 0);

  @override
  void didUpdateWidget(covariant FlippableCard old) {
    super.didUpdateWidget(old);
    if (widget.showFront != old.showFront) {
      widget.showFront ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final angle = _controller.value * 3.14159265;
        final isBackHalf = angle > 3.14159265 / 2;
        final displayAngle = isBackHalf ? angle - 3.14159265 : angle;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0015)
            ..rotateY(displayAngle),
          child: isBackHalf ? widget.front : widget.back,
        );
      },
    );
  }
}

/// Entrada escalonada (fade + slide) para cuando se reparte una mano —
/// cada carta aparece un poco después que la anterior según [index].
class StaggeredEntrance extends StatelessWidget {
  final int index;
  final Widget child;

  const StaggeredEntrance({super.key, required this.index, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + index * 60),
      curve: Curves.easeOutBack,
      builder: (context, t, child) {
        final clamped = t.clamp(0.0, 1.0);
        return Opacity(
          opacity: clamped,
          child: Transform.translate(offset: Offset(0, (1 - clamped) * 40), child: child),
        );
      },
      child: child,
    );
  }
}

/// "Pop" de escala + fade para una carta que acaba de jugarse a la mesa.
class PopInCard extends StatelessWidget {
  final Widget child;
  const PopInCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutBack,
      builder: (context, t, child) {
        final clamped = t.clamp(0.0, 1.05);
        return Transform.scale(
          scale: clamped,
          child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
        );
      },
      child: child,
    );
  }
}
