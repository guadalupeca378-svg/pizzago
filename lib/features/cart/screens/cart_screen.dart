import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/summary_card.dart';
import '../../../core/widgets/surface_card.dart';
import '../cart_controller.dart';
import '../widgets/cart_item_row.dart';
import '../widgets/coupon_field.dart';
import '../widgets/free_delivery_progress.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  Future<void> _confirmClear(BuildContext context) async {
    final cart = context.read<CartController>();
    final ok = await showConfirmDialog(
      context,
      icon: Symbols.delete_sweep_rounded,
      title: '¿Vaciar el carrito?',
      message: 'Se quitarán todos los productos de tu pedido.',
      confirmLabel: 'Vaciar',
    );
    if (ok) cart.clear();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    // Escritorio: productos a la izquierda; resumen y botón a la derecha.
    final wide = MediaQuery.sizeOf(context).width >= 960;

    final items = SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (i, item) in cart.items.indexed) ...[
            if (i > 0) const Divider(indent: 16, endIndent: 16),
            EntranceAnimation(
              key: ValueKey('in-${item.key}'),
              index: i,
              child: CartItemRow(key: ValueKey(item.key), item: item),
            ),
          ],
        ],
      ),
    );
    final summary = [
      const FreeDeliveryProgress(),
      const SizedBox(height: 12),
      const CouponField(),
      const SizedBox(height: 12),
      SummaryCard(
        subtotal: cart.subtotal,
        discount: cart.discount,
        delivery: cart.delivery,
        total: cart.total,
        couponCode: cart.coupon?.code,
      ),
    ];
    final continueButton = FilledButton(
      onPressed: () => context.push(AppRoutes.checkout),
      child: Text('Continuar · ${Fmt.money(cart.total)}'),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tu pedido'),
        actions: [
          if (!cart.isEmpty) TextButton(onPressed: () => _confirmClear(context), child: const Text('Vaciar')),
          const SizedBox(width: 8),
        ],
      ),
      body: cart.isEmpty
          ? EmptyState(
              icon: Symbols.shopping_bag_rounded,
              title: 'Tu carrito está vacío',
              message: 'Agrega productos del menú y aparecerán aquí.',
              action: FilledButton.icon(
                onPressed: () => context.go(AppRoutes.home),
                icon: const Icon(Symbols.restaurant_menu_rounded),
                label: const Text('Ver el menú'),
              ),
            )
          : wide
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ListView(padding: const EdgeInsets.fromLTRB(24, 8, 12, 28), children: [items]),
                    ),
                    SizedBox(
                      width: 400,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(12, 8, 24, 28),
                        children: [...summary, const SizedBox(height: 16), continueButton],
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ResponsiveCenter(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [items, const SizedBox(height: 12), ...summary],
              ),
            ),
      // En pantallas anchas el botón ya está en la columna derecha.
      bottomNavigationBar: cart.isEmpty || wide ? null : BottomActionBar(child: continueButton),
    );
  }
}
