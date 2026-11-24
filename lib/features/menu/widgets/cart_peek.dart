import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/motion.dart';
import '../../cart/cart_controller.dart';

/// Resumen flotante del carrito: aparece al agregar el primer producto.
class CartPeek extends StatelessWidget {
  const CartPeek({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.select<CartController, int>((c) => c.itemCount);
    final total = context.select<CartController, double>((c) => c.total);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final visible = count > 0;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: IgnorePointer(
          ignoring: !visible,
          child: AnimatedSlide(
            offset: visible ? Offset.zero : const Offset(0, 1.8),
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: visible ? 1 : 0,
              duration: const Duration(milliseconds: 250),
              child: Material(
                color: scheme.primary,
                elevation: 6,
                shadowColor: scheme.primary.withValues(alpha: .5),
                borderRadius: BorderRadius.circular(AppTheme.radius),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => context.go(AppRoutes.cart),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: scheme.onPrimary.withValues(alpha: .2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$count',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: scheme.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ver mi pedido',
                                style: theme.textTheme.titleSmall?.copyWith(color: scheme.onPrimary),
                              ),
                              Text(
                                Fmt.count(count, 'producto'),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: scheme.onPrimary.withValues(alpha: .8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedMoney(
                          total,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: scheme.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
