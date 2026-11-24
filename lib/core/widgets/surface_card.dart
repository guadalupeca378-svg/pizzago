import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tarjeta base del sistema: fondo de tarjeta, radio 16 y sombra suave
/// (borde en modo oscuro). Con [onTap] responde con efecto de tinta.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.radius = AppTheme.radius,
    this.color,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shape = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: shape, boxShadow: AppTheme.cardShadow(scheme)),
      child: Material(
        color: color ?? AppTheme.cardColor(scheme),
        shape: RoundedRectangleBorder(
          borderRadius: shape,
          side: scheme.brightness == Brightness.dark ? BorderSide(color: scheme.outlineVariant) : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
