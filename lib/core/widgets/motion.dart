import 'dart:async';

import 'package:flutter/material.dart';

import '../utils/formatters.dart';

/// Entrada escalonada: aparece con fundido y un pequeño desplazamiento hacia
/// arriba. [index] retrasa cada elemento para que entren en cascada; el
/// retraso se reinicia cada 6 para que al hacer scroll no se acumule.
class EntranceAnimation extends StatefulWidget {
  const EntranceAnimation({super.key, required this.child, this.index = 0, this.offset = 24});

  final Widget child;
  final int index;
  final double offset;

  @override
  State<EntranceAnimation> createState() => _EntranceAnimationState();
}

class _EntranceAnimationState extends State<EntranceAnimation> with SingleTickerProviderStateMixin {
  static const _base = Duration(milliseconds: 420);
  static const _step = 55;

  late final AnimationController _controller;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    final delay = (widget.index % 6) * _step;
    final total = _base.inMilliseconds + delay;
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: total),
    )..forward();
    // El retraso se modela como un Interval: sin timers que limpiar.
    _t = CurvedAnimation(
      parent: _controller,
      curve: Interval(delay / total, 1, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _t,
    child: widget.child,
    builder: (context, child) => Opacity(
      opacity: _t.value,
      child: Transform.translate(offset: Offset(0, widget.offset * (1 - _t.value)), child: child),
    ),
  );
}

/// Se "hunde" un poco mientras se mantiene presionado (retroalimentación
/// táctil sin bloquear los InkWell de adentro).
class PressableScale extends StatefulWidget {
  const PressableScale({super.key, required this.child, this.scale = .97});

  final Widget child;
  final double scale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _set(true),
    onPointerUp: (_) => _set(false),
    onPointerCancel: (_) => _set(false),
    child: AnimatedScale(
      scale: _down ? widget.scale : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      child: widget.child,
    ),
  );
}

/// Cantidad en pesos que "cuenta" hasta el nuevo valor.
class AnimatedMoney extends StatelessWidget {
  const AnimatedMoney(this.value, {super.key, this.style});

  final double value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: value),
    duration: const Duration(milliseconds: 550),
    curve: Curves.easeOutCubic,
    // Durante el conteo se muestran pesos cerrados para que no parpadeen
    // los centavos.
    builder: (_, v, _) => Text(Fmt.money(v == value ? value : v.roundToDouble()), style: style),
  );
}

/// Palomita que se dibuja trazo a trazo dentro de un círculo (confirmación
/// del pedido). Empieza tras [delay] para que primero aparezca la foto.
class AnimatedCheck extends StatefulWidget {
  const AnimatedCheck({
    super.key,
    required this.size,
    required this.color,
    required this.checkColor,
    this.delay = const Duration(milliseconds: 350),
  });

  final double size;
  final Color color;
  final Color checkColor;
  final Duration delay;

  @override
  State<AnimatedCheck> createState() => _AnimatedCheckState();
}

class _AnimatedCheckState extends State<AnimatedCheck> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  Timer? _start;

  @override
  void initState() {
    super.initState();
    _start = Timer(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _start?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      size: Size.square(widget.size),
      painter: _CheckPainter(
        progress: CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
        color: widget.color,
        checkColor: widget.checkColor,
      ),
    ),
  );
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.progress, required this.color, required this.checkColor}) : super(repaint: progress);

  final Animation<double> progress;
  final Color color;
  final Color checkColor;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    if (t == 0) return;
    final center = size.center(Offset.zero);
    // El círculo crece en el primer tercio; la palomita se traza después.
    final grow = (t / .35).clamp(0.0, 1.0);
    canvas.drawCircle(center, size.width / 2 * grow, Paint()..color = color);

    final draw = ((t - .35) / .65).clamp(0.0, 1.0);
    if (draw == 0) return;
    final w = size.width;
    final check = Path()
      ..moveTo(w * .28, w * .52)
      ..lineTo(w * .44, w * .67)
      ..lineTo(w * .73, w * .37);
    final metric = check.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * draw),
      Paint()
        ..color = checkColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .09
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.color != color || old.checkColor != checkColor;
}

/// Contenedor de las pestañas principales con la transición "fade through"
/// de Material 3: la saliente se desvanece rápido y la entrante aparece con
/// un ligero zoom. Las pestañas inactivas no reciben toques ni animan.
class FadeThroughBranches extends StatelessWidget {
  const FadeThroughBranches({super.key, required this.currentIndex, required this.children});

  final int currentIndex;
  final List<Widget> children;

  static const _duration = Duration(milliseconds: 320);

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [for (final (i, child) in children.indexed) _Branch(active: i == currentIndex, child: child)],
  );
}

class _Branch extends StatelessWidget {
  const _Branch({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    ignoring: !active,
    child: ExcludeFocus(
      excluding: !active,
      child: ExcludeSemantics(
        excluding: !active,
        // La animación de opacidad queda fuera del TickerMode para que la
        // pestaña saliente sí pueda desvanecerse.
        child: AnimatedOpacity(
          opacity: active ? 1 : 0,
          duration: FadeThroughBranches._duration,
          curve: active ? const Interval(.3, 1, curve: Curves.easeOut) : const Interval(0, .3, curve: Curves.easeIn),
          child: AnimatedScale(
            scale: active ? 1 : .94,
            duration: FadeThroughBranches._duration,
            curve: active ? const Interval(.3, 1, curve: Curves.easeOutCubic) : Curves.linear,
            child: TickerMode(enabled: active, child: child),
          ),
        ),
      ),
    ),
  );
}
