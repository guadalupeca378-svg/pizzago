import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/summary_card.dart';
import '../../../core/widgets/surface_card.dart';
import '../../../data/models/cart_item.dart';
import '../../../data/models/pizza_order.dart';
import '../../cart/cart_controller.dart';
import '../../cart/widgets/order_line.dart';
import '../../menu/catalog_controller.dart';
import '../order_controller.dart';
import '../widgets/order_tracking.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  /// Vuelve a agregar los productos del pedido con los precios y extras del
  /// menú actual (el pedido guarda una copia de cómo eran ese día). Lo que
  /// ya no está en el menú se omite y se avisa.
  void _reorder(BuildContext context, PizzaOrder order) {
    final catalog = context.read<CatalogController>();
    final cart = context.read<CartController>();
    final messenger = ScaffoldMessenger.of(context);
    var missing = 0;
    for (final item in order.items) {
      final pizza = catalog.byId(item.pizza.id);
      if (pizza == null) {
        missing++;
        continue;
      }
      final extraIds = {for (final e in item.extras) e.id};
      cart.add(
        CartItem(
          pizza: pizza,
          size: item.size,
          extras: [
            for (final e in catalog.extras)
              if (extraIds.contains(e.id)) e,
          ],
          quantity: item.quantity,
          note: item.note,
        ),
      );
    }
    context.go(AppRoutes.cart);
    if (missing > 0) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            missing == 1
                ? 'Un producto de ese pedido ya no está en el menú.'
                : '$missing productos de ese pedido ya no están en el menú.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<OrderController>();
    final order = controller.byId(orderId);

    if (order == null) {
      return Scaffold(
        appBar: AppBar(),
        body: controller.isLoading
            ? const Center(child: CircularProgressIndicator())
            : EmptyState(
                icon: Symbols.search_off_rounded,
                title: 'No encontramos el pedido #$orderId',
                action: FilledButton.tonal(
                  onPressed: () => context.go(AppRoutes.orders),
                  child: const Text('Ver mis pedidos'),
                ),
              ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Pedido #${order.id}')),
      body: ClockBuilder(
        builder: (context, now) {
          final status = order.statusAt(now);
          return ResponsiveCenter(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                TrackingCard(order: order, status: status, now: now),
                const SizedBox(height: 12),
                SurfaceCard(
                  padding: const EdgeInsets.all(20),
                  child: OrderTimeline(order: order, current: status),
                ),
                const SectionHeader('Entrega', padding: EdgeInsets.only(top: 24, bottom: 12)),
                SurfaceCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Symbols.location_on_rounded),
                        title: Text(order.address),
                        subtitle: const Text('Dirección'),
                      ),
                      const Divider(indent: 56),
                      ListTile(
                        leading: const Icon(Symbols.phone_rounded),
                        title: Text(order.phone),
                        subtitle: const Text('Teléfono'),
                      ),
                      const Divider(indent: 56),
                      ListTile(
                        leading: Icon(order.paymentMethod.icon),
                        title: Text(order.paymentMethod.label),
                        subtitle: const Text('Método de pago'),
                      ),
                      if (order.notes.isNotEmpty) ...[
                        const Divider(indent: 56),
                        ListTile(
                          leading: const Icon(Symbols.sticky_note_2_rounded),
                          title: Text(order.notes),
                          subtitle: const Text('Notas'),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SummaryCard(
                  subtotal: order.subtotal,
                  discount: order.discount,
                  delivery: order.deliveryFee,
                  total: order.total,
                  couponCode: order.couponCode,
                  header: Column(children: [for (final item in order.items) OrderLine(item: item)]),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomActionBar(
        child: OutlinedButton.icon(
          onPressed: () => _reorder(context, order),
          icon: const Icon(Symbols.replay_rounded),
          label: const Text('Pedir lo mismo otra vez'),
        ),
      ),
    );
  }
}
