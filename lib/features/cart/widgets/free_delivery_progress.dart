import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/surface_card.dart';
import '../cart_controller.dart';

class FreeDeliveryProgress extends StatelessWidget {
  const FreeDeliveryProgress({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartController>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final missing = cart.missingForFreeDelivery;
    final done = missing == 0;

    return SurfaceCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (done ? scheme.secondaryContainer : scheme.surfaceContainerLow),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Symbols.delivery_dining_rounded,
              fill: done ? 1 : 0,
              color: done ? scheme.secondary : scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  done ? 'Tu envío es gratis' : 'Agrega ${Fmt.money(missing)} para envío gratis',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                TweenAnimationBuilder<double>(
                  tween: Tween(end: cart.freeDeliveryProgress),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeOutCubic,
                  builder: (_, value, _) => LinearProgressIndicator(
                    value: value,
                    borderRadius: BorderRadius.circular(99),
                    color: done ? scheme.secondary : scheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
