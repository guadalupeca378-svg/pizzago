import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../theme/app_theme.dart';

/// Centra el contenido y limita su ancho en pantallas grandes (web/escritorio).
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({super.key, required this.child, this.maxWidth = 720});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    // Sin esto, Align ocupa todo el alto disponible; en un
    // bottomNavigationBar eso es la pantalla completa.
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      // Ocupa todo el ancho permitido (los botones no se encogen).
      child: SizedBox(width: double.infinity, child: child),
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action});

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(color: scheme.primaryContainer.withValues(alpha: .6), shape: BoxShape.circle),
                child: Icon(icon, size: 40, color: scheme.primary),
              ),
              const SizedBox(height: 24),
              Text(title, textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
              if (action != null) ...[const SizedBox(height: 24), action!],
            ],
          ),
        ),
      ),
    );
  }
}

/// Título de sección: "Clásicas" a la izquierda y un dato secundario a la
/// derecha ("5 productos").
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing, this.padding = const EdgeInsets.fromLTRB(20, 28, 20, 12)});

  final String title;
  final String? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleLarge),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}

/// Etiqueta pequeña con ícono, p. ej. calificación o tiempo de preparación.
class InfoPill extends StatelessWidget {
  const InfoPill({super.key, required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = color ?? scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: scheme.surfaceContainerLow, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, fill: 1, size: 16, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: scheme.onSurface, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Selector − cantidad + en forma de píldora. Con [removeAtMin], el botón
/// izquierdo se vuelve un bote de basura cuando la cantidad es 1.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 20,
    this.removeAtMin = false,
    this.compact = false,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final bool removeAtMin;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final showTrash = removeAtMin && value <= 1;
    final size = compact ? 34.0 : 44.0;

    Widget button(IconData icon, String tooltip, VoidCallback? onPressed) => SizedBox.square(
      dimension: size,
      child: IconButton(
        padding: EdgeInsets.zero,
        tooltip: tooltip,
        iconSize: compact ? 18 : 20,
        color: scheme.onSurface,
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor(scheme),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(
            showTrash ? Symbols.delete_rounded : Symbols.remove_rounded,
            showTrash ? 'Quitar' : 'Menos',
            showTrash
                ? () => onChanged(0)
                : value > min
                ? () => onChanged(value - 1)
                : null,
          ),
          SizedBox(
            width: compact ? 22 : 30,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) => SlideTransition(
                position: Tween(begin: const Offset(0, .5), end: Offset.zero).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: Text(
                '$value',
                key: ValueKey(value),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          button(Symbols.add_rounded, 'Más', value < max ? () => onChanged(value + 1) : null),
        ],
      ),
    );
  }
}

/// Barra inferior para la acción principal de una pantalla.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.cardColor(scheme),
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: ResponsiveCenter(
          child: Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 12), child: child),
        ),
      ),
    );
  }
}

/// Reconstruye a [builder] cada [interval] con la hora actual (para
/// el seguimiento de pedidos).
class ClockBuilder extends StatefulWidget {
  const ClockBuilder({super.key, required this.builder, this.interval = const Duration(seconds: 30)});

  final Widget Function(BuildContext context, DateTime now) builder;
  final Duration interval;

  @override
  State<ClockBuilder> createState() => _ClockBuilderState();
}

class _ClockBuilderState extends State<ClockBuilder> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.interval, (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, DateTime.now());
}

/// Diálogo de confirmación para acciones que no se pueden deshacer (vaciar
/// el carrito, cerrar sesión). Devuelve `true` solo si el usuario confirma.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
  required String confirmLabel,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: Icon(icon),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(confirmLabel)),
      ],
    ),
  );
  return ok ?? false;
}
