import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../../data/models/cart_item.dart';
import '../../menu/widgets/product_cards.dart';
import '../cart_controller.dart';

class CartItemRow extends StatelessWidget {
  const CartItemRow({super.key, required this.item});

  final CartItem item;

  void _remove(BuildContext context) {
    final cart = context.read<CartController>();
    final removed = cart.remove(item.key);
    if (removed == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Quitaste ${item.pizza.name}'),
          persist: false,
          action: SnackBarAction(label: 'Deshacer', onPressed: () => cart.undoRemove(removed.item, removed.index)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Dismissible(
      key: ValueKey('dismiss-${item.key}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _remove(context),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: scheme.errorContainer,
        child: Icon(Symbols.delete_rounded, color: scheme.onErrorContainer),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ProductThumb(pizza: item.pizza, size: 64),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.pizza.name, style: theme.textTheme.titleSmall),
                  if (item.details.isNotEmpty)
                    Text(item.details, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(Fmt.money(item.total), style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            QuantityStepper(
              max: CartController.maxQuantity,
              compact: true,
              removeAtMin: true,
              value: item.quantity,
              onChanged: (q) => q == 0 ? _remove(context) : context.read<CartController>().setQuantity(item.key, q),
            ),
          ],
        ),
      ),
    );
  }
}
