import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/motion.dart';
import '../../../data/models/pizza_order.dart';
import '../order_controller.dart';
import '../widgets/order_card.dart';

/// Historial de pedidos dividido en "En curso" y "Anteriores".
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  static const _headerPadding = EdgeInsets.only(top: 12, bottom: 12);

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OrderController>();
    final orders = controller.orders;

    final Widget body;
    if (controller.isLoading && orders.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (orders.isEmpty) {
      body = EmptyState(
        icon: Symbols.receipt_long_rounded,
        title: 'Todavía no tienes pedidos',
        message: controller.error ?? 'Cuando hagas uno, aquí podrás seguirlo en tiempo real.',
        action: FilledButton.icon(
          onPressed: () => context.go(AppRoutes.home),
          icon: const Icon(Symbols.restaurant_menu_rounded),
          label: const Text('Ver el menú'),
        ),
      );
    } else {
      body = ClockBuilder(
        builder: (context, now) {
          // Arriba lo que sigue en camino; abajo el historial.
          final active = orders.where((o) => o.isActiveAt(now)).toList();
          final past = orders.where((o) => !o.isActiveAt(now)).toList();
          var index = 0;
          Widget card(PizzaOrder order) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: EntranceAnimation(
              index: index++,
              child: PressableScale(
                child: OrderCard(order: order, now: now),
              ),
            ),
          );
          return RefreshIndicator(
            onRefresh: controller.load,
            child: ResponsiveCenter(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                children: [
                  if (active.isNotEmpty) ...[
                    SectionHeader('En curso', trailing: Fmt.count(active.length, 'pedido'), padding: _headerPadding),
                    for (final order in active) card(order),
                  ],
                  if (past.isNotEmpty) ...[
                    SectionHeader('Anteriores', trailing: Fmt.count(past.length, 'pedido'), padding: _headerPadding),
                    for (final order in past) card(order),
                  ],
                ],
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mis pedidos')),
      body: body,
    );
  }
}
