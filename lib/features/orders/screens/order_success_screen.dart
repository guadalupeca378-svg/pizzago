import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/product_image.dart';
import '../../../core/widgets/surface_card.dart';
import '../../../data/models/pizza_order.dart';
import '../order_controller.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    final order = context.select<OrderController, PizzaOrder?>((c) => c.byId(orderId));
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(AppRoutes.home);
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    // La foto del pedido aparece con suavidad y después se
                    // dibuja la palomita de confirmación.
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                      builder: (_, t, child) => Opacity(
                        opacity: t,
                        child: Transform.scale(scale: .92 + .08 * t, child: child),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          order == null || order.items.isEmpty
                              ? const AppLogo(size: 160)
                              : ClipOval(
                                  child: SizedBox.square(
                                    dimension: 160,
                                    child: ProductImage(pizza: order.items.first.pizza),
                                  ),
                                ),
                          Positioned(
                            right: -6,
                            bottom: 2,
                            child: DecoratedBox(
                              // Aro del color del fondo para separarla de la foto.
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: scheme.surface, width: 4),
                              ),
                              child: AnimatedCheck(size: 52, color: scheme.secondary, checkColor: scheme.onSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text('¡Ya está en el horno!', textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 10),
                    Text(
                      order == null
                          ? 'Tu pedido #$orderId ya está en la cocina.'
                          : 'Tu pedido #${order.id} llegará aproximadamente a las '
                                '${Fmt.time(order.estimatedDelivery)}.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    if (order != null) ...[
                      const SizedBox(height: 20),
                      SurfaceCard(
                        child: Row(
                          children: [
                            Icon(order.paymentMethod.icon, color: scheme.onSurfaceVariant),
                            const SizedBox(width: 12),
                            Expanded(child: Text(order.paymentMethod.label, style: theme.textTheme.bodyMedium)),
                            Text(Fmt.money(order.total), style: theme.textTheme.titleMedium),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => context.go(AppRoutes.order(orderId)),
                        icon: const Icon(Symbols.delivery_dining_rounded),
                        label: const Text('Seguir mi pedido'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => context.go(AppRoutes.home),
                        child: const Text('Volver al menú'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
