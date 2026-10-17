import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/surface_card.dart';
import '../../../data/models/pizza_order.dart';

/// Estado actual con hora estimada y barra de progreso del reparto.
class TrackingCard extends StatelessWidget {
  const TrackingCard({super.key, required this.order, required this.status, required this.now});

  final PizzaOrder order;
  final OrderStatus status;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final progress = order.progressAt(now);
    final delivered = status == OrderStatus.entregado;

    return SurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: delivered ? scheme.secondaryContainer : scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(status.icon, fill: 1, color: delivered ? scheme.secondary : scheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(status.message, style: theme.textTheme.titleMedium),
                    Text(
                      delivered
                          ? 'Entregado a las ${Fmt.time(order.estimatedDelivery)}'
                          : 'Llegada estimada: ${Fmt.time(order.estimatedDelivery)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, value, _) => LinearProgressIndicator(
              value: value,
              borderRadius: BorderRadius.circular(99),
              color: delivered ? scheme.secondary : scheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Pizzería', style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
              const Spacer(),
              Text('Tu domicilio', style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Línea de tiempo vertical con las etapas del pedido.
class OrderTimeline extends StatelessWidget {
  const OrderTimeline({super.key, required this.order, required this.current});

  final PizzaOrder order;
  final OrderStatus current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const steps = OrderStatus.values;

    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 24,
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: steps[i].index <= current.index ? scheme.primary : Colors.transparent,
                          border: Border.all(
                            color: steps[i].index <= current.index ? scheme.primary : scheme.outlineVariant,
                            width: 2,
                          ),
                        ),
                        child: steps[i].index < current.index
                            ? Icon(Symbols.check_rounded, size: 14, weight: 700, color: scheme.onPrimary)
                            : null,
                      ),
                      if (i < steps.length - 1)
                        Expanded(
                          child: Container(
                            width: 2,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: steps[i].index < current.index ? scheme.primary : scheme.outlineVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: i < steps.length - 1 ? 20 : 0, top: 1),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            steps[i].label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: steps[i] == current ? FontWeight.w700 : FontWeight.w400,
                              color: steps[i].index <= current.index ? scheme.onSurface : scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Text(
                          Fmt.time(order.timeFor(steps[i])),
                          style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
