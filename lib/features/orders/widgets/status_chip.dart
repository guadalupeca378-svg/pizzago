import 'package:flutter/material.dart';

import '../../../data/models/pizza_order.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (status) {
      OrderStatus.recibido => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      OrderStatus.preparando => (scheme.primaryContainer, scheme.onPrimaryContainer),
      OrderStatus.enCamino => (scheme.primaryContainer, scheme.onPrimaryContainer),
      OrderStatus.entregado => (scheme.secondaryContainer, scheme.onSecondaryContainer),
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, fill: 1, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
