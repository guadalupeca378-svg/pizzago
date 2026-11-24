import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/product_image.dart';
import '../../../data/models/pizza.dart';

class OptionHeading extends StatelessWidget {
  const OptionHeading(this.title, {super.key, this.hint});

  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) =>
      SectionHeader(title, trailing: hint, padding: const EdgeInsets.only(top: 28, bottom: 12));
}

class SizeOption extends StatelessWidget {
  const SizeOption({super.key, required this.size, required this.price, required this.selected, required this.onTap});

  final PizzaSize size;
  final double price;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // Círculo proporcional al diámetro real de la pizza.
    final diameter = const [18.0, 24.0, 30.0][size.index];

    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? scheme.primaryContainer.withValues(alpha: .5) : AppTheme.cardColor(scheme),
            borderRadius: BorderRadius.circular(AppTheme.radius),
            border: Border.all(color: selected ? scheme.primary : scheme.outlineVariant, width: selected ? 2 : 1),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 32,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: diameter,
                    height: diameter,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: selected ? scheme.primary : scheme.outline, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(size.label, style: theme.textTheme.titleSmall),
              Text(size.diameter, style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text(
                Fmt.money(price),
                style: theme.textTheme.labelLarge?.copyWith(color: selected ? scheme.primary : scheme.onSurface),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExtraRow extends StatelessWidget {
  const ExtraRow({super.key, required this.extra, required this.selected, required this.onTap});

  final Extra extra;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: ToppingImage(topping: extra.topping, size: 40),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(extra.name, style: theme.textTheme.bodyLarge)),
            Text(
              '+${Fmt.money(extra.price)}',
              style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            Checkbox(value: selected, onChanged: (_) => onTap()),
          ],
        ),
      ),
    );
  }
}
