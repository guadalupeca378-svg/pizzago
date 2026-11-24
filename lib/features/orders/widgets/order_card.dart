import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/routes.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/surface_card.dart';
import '../../../data/models/pizza_order.dart';
import '../../menu/widgets/product_cards.dart';
import 'status_chip.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, required this.now});

  final PizzaOrder order;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final products = {for (final i in order.items) i.pizza.id: i.pizza}.values.take(4).toList();

    return SurfaceCard(
      onTap: () => context.push(AppRoutes.order(order.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pedido #${order.id}', style: theme.textTheme.titleSmall),
                    Text(Fmt.dateTime(order.createdAt), style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              StatusChip(status: order.statusAt(now)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final p in products) ...[ProductThumb(pizza: p, size: 44, radius: 10), const SizedBox(width: 8)],
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  order.itemsSummary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                Fmt.count(order.itemCount, 'producto'),
                style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const Spacer(),
              Text(Fmt.money(order.total), style: theme.textTheme.titleMedium),
              const SizedBox(width: 4),
              Icon(Symbols.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ],
      ),
    );
  }
}
