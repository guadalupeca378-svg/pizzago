import 'package:flutter/material.dart';

import '../../../core/widgets/surface_card.dart';

class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, fill: 1, size: 20, color: scheme.primary),
          const SizedBox(height: 10),
          FittedBox(child: Text(value, style: theme.textTheme.titleLarge)),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
