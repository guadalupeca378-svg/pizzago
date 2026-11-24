import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Isotipo de la marca: una "P" geométrica cuya panza es una pizza vista
/// desde arriba, con los cortes de las rebanadas. Se dibuja con código.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 40, this.inverted = false, this.showBackground = true});

  final double size;

  /// Versión clara para fondos de color (splash y panel del login).
  final bool inverted;

  /// Sin el cuadro de fondo: solo para el ícono adaptable de Android, donde
  /// el sistema pone el fondo y recorta la forma.
  final bool showBackground;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _LogoPainter(
      background: inverted ? Colors.white : AppTheme.tomato,
      foreground: inverted ? AppTheme.tomato : Colors.white,
      showBackground: showBackground,
    ),
  );
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter({required this.background, required this.foreground, required this.showBackground});

  final Color background;
  final Color foreground;
  final bool showBackground;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final bg = Paint()..color = background;
    final fg = Paint()..color = foreground;

    if (showBackground) {
      canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(s * .28)), bg);
    }

    // Asta de la P.
    canvas.drawRRect(RRect.fromLTRBR(s * .27, s * .22, s * .41, s * .80, Radius.circular(s * .07)), fg);

    // Panza de la P: un disco (la pizza) pegado al asta.
    final center = Offset(s * .52, s * .41);
    final radius = s * .21;
    canvas.drawCircle(center, radius, fg);

    // Cortes de las rebanadas, del centro hacia la orilla.
    final cut = Paint()
      ..color = background
      ..strokeWidth = s * .035
      ..strokeCap = StrokeCap.round;
    for (final degrees in [-60.0, 0.0, 60.0]) {
      final a = degrees * math.pi / 180;
      canvas.drawLine(center, center + Offset(math.cos(a), math.sin(a)) * (radius + 1), cut);
    }
    // Centro de la P (el hueco), que también es el centro de la pizza.
    canvas.drawCircle(center, s * .055, bg);
  }

  @override
  bool shouldRepaint(_LogoPainter old) =>
      old.background != background || old.foreground != foreground || old.showBackground != showBackground;
}

/// Logotipo: monograma + "PizzaGo" en la tipografía de la marca.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.color, this.inverted = false});

  static const size = 40.0;

  final Color? color;
  final bool inverted;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      AppLogo(size: size, inverted: inverted),
      const SizedBox(width: 10),
      Text(
        'PizzaGo',
        style: TextStyle(
          fontFamily: AppTheme.serif,
          fontSize: size * .7,
          height: 1,
          color: color ?? Theme.of(context).colorScheme.onSurface,
        ),
      ),
    ],
  );
}
