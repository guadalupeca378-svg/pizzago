import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/cart_item.dart';
import '../../menu/widgets/product_cards.dart';

/// Renglón de un producto dentro de un resumen (pago y detalle del pedido):
/// foto, "2× Pepperoni", tamaño y extras, y el importe.
class OrderLine extends StatelessWidget {
  const OrderLine({super.key, required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          ProductThumb(pizza: item.pizza, size: 40, radius: 10),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${item.quantity}× ${item.pizza.name}', style: theme.textTheme.titleSmall),
                if (item.details.isNotEmpty)
                  Text(
                    item.details,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          Text(Fmt.money(item.total), style: theme.textTheme.titleSmall),
        ],
      ),
    );
  }
}
