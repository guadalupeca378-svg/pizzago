import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/surface_card.dart';
import '../../../data/models/pizza_order.dart';
import '../order_controller.dart';

/// Aviso del pedido en curso en el inicio: estado, hora de llegada y
/// avance. Al tocarlo abre el seguimiento. Desaparece cuando se entrega.
class ActiveOrderBanner extends StatelessWidget {
  const ActiveOrderBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final orders = context.select<OrderController, List<PizzaOrder>>((c) => c.orders);
    if (orders.isEmpty) return const SizedBox.shrink();

    return ClockBuilder(
      builder: (context, now) {
        // Los pedidos vienen del más reciente al más antiguo.
        final order = orders.where((o) => o.isActiveAt(now)).firstOrNull;
        return AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: order == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: _Banner(order: order, now: now),
                ),
        );
      },
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.order, required this.now});

  final PizzaOrder order;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = order.statusAt(now);

    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      onTap: () => context.push(AppRoutes.order(order.id)),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: scheme.primaryContainer, shape: BoxShape.circle),
                child: Icon(status.icon, fill: 1, size: 22, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(status.message, style: theme.textTheme.titleSmall),
                    Text(
                      'Pedido #${order.id} · llega a las ${Fmt.time(order.estimatedDelivery)}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text('Seguir', style: theme.textTheme.labelLarge?.copyWith(color: scheme.primary)),
              Icon(Symbols.chevron_right_rounded, color: scheme.primary),
            ],
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween(end: order.progressAt(now)),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (_, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 4,
              borderRadius: BorderRadius.circular(AppTheme.radius),
            ),
          ),
        ],
      ),
    );
  }
}
