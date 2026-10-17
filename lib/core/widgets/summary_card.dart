import 'package:flutter/material.dart';

import '../utils/formatters.dart';
import 'motion.dart';
import 'surface_card.dart';

/// Desglose del pedido: subtotal, descuento, envío y total
/// (carrito, pago y detalle del pedido).
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.subtotal,
    required this.discount,
    required this.delivery,
    required this.total,
    this.couponCode,
    this.header,
  });

  final double subtotal;
  final double discount;
  final double delivery;
  final double total;
  final String? couponCode;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Widget row(String label, String value, {Color? color}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(color: color ?? scheme.onSurface, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );

    return SurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Resumen', style: theme.textTheme.titleMedium),
          if (header != null) ...[const SizedBox(height: 12), header!],
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 10),
          row('Subtotal', Fmt.money(subtotal)),
          if (discount > 0)
            row(
              couponCode == null ? 'Descuento' : 'Cupón $couponCode',
              '−${Fmt.money(discount)}',
              color: scheme.secondary,
            ),
          row('Envío', delivery == 0 ? 'Gratis' : Fmt.money(delivery), color: delivery == 0 ? scheme.secondary : null),
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text('Total', style: theme.textTheme.titleMedium)),
              AnimatedMoney(total, style: theme.textTheme.titleLarge),
            ],
          ),
        ],
      ),
    );
  }
}
