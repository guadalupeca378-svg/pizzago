import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Brillo que recorre a sus hijos de izquierda a derecha mientras algo carga.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHigh;
    final highlight = AppTheme.cardColor(scheme);
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          colors: [base, highlight, base],
          stops: const [.35, .5, .65],
          begin: const Alignment(-1, -.3),
          end: const Alignment(1, .3),
          transform: _SlideGradient(_controller.value),
        ).createShader(bounds),
        child: child,
      ),
    );
  }
}

/// Desplaza el degradado de -100 % a +100 % del ancho.
class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.percent);

  final double percent;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * (percent * 2 - 1), 0, 0);
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, required this.height, this.radius = 8});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

/// Silueta de una tarjeta del menú (misma geometría que MenuItemCard).
class MenuCardSkeleton extends StatelessWidget {
  const MenuCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(scheme),
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: const Row(
        children: [
          SkeletonBox(width: 104, height: 104, radius: AppTheme.radiusSm),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                SkeletonBox(width: 120, height: 14),
                SizedBox(height: 10),
                SkeletonBox(height: 10),
                SizedBox(height: 6),
                SkeletonBox(width: 150, height: 10),
                Spacer(),
                Row(
                  children: [
                    SkeletonBox(width: 64, height: 18),
                    Spacer(),
                    SkeletonBox(width: 36, height: 36, radius: 18),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
