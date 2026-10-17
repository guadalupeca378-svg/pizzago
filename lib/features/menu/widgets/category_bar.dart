import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/models/pizza.dart';

/// Barra fija de categorías del inicio. No filtra: cada chip lleva a su
/// sección del menú, y al desplazarse se marca la sección que está a la
/// vista (como en las apps de comida a domicilio).
class PinnedCategoryBar extends SliverPersistentHeaderDelegate {
  const PinnedCategoryBar({
    required this.topInset,
    required this.categories,
    required this.active,
    required this.onSelected,
  });

  /// Alto de la barra de estado: al quedar fija, no se mete debajo.
  final double topInset;
  final List<PizzaCategory> categories;
  final ValueListenable<PizzaCategory?> active;
  final ValueChanged<PizzaCategory> onSelected;

  static const height = 64.0;

  @override
  double get minExtent => height + topInset;

  @override
  double get maxExtent => height + topInset;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: overlapsContent ? scheme.outlineVariant : Colors.transparent)),
      ),
      alignment: Alignment.bottomLeft,
      padding: const EdgeInsets.only(bottom: 10),
      child: ValueListenableBuilder(
        valueListenable: active,
        builder: (_, current, _) => _CategoryChips(categories: categories, active: current, onSelected: onSelected),
      ),
    );
  }

  @override
  bool shouldRebuild(PinnedCategoryBar old) =>
      old.topInset != topInset || old.active != active || !listEquals(old.categories, categories);
}

class _CategoryChips extends StatefulWidget {
  const _CategoryChips({required this.categories, required this.active, required this.onSelected});

  final List<PizzaCategory> categories;
  final PizzaCategory? active;
  final ValueChanged<PizzaCategory> onSelected;

  @override
  State<_CategoryChips> createState() => _CategoryChipsState();
}

class _CategoryChipsState extends State<_CategoryChips> {
  final _keys = <PizzaCategory, GlobalKey>{};

  @override
  void didUpdateWidget(_CategoryChips old) {
    super.didUpdateWidget(old);
    // La barra se desplaza sola para que el chip activo siempre se vea.
    final active = widget.active;
    if (active != null && active != old.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final chip = _keys[active]?.currentContext;
        if (chip != null && chip.mounted) {
          Scrollable.ensureVisible(
            chip,
            alignment: .5,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (final (i, category) in widget.categories.indexed) ...[
            if (i > 0) const SizedBox(width: 8),
            ChoiceChip(
              key: _keys.putIfAbsent(category, GlobalKey.new),
              selected: category == widget.active,
              showCheckmark: false,
              label: Text(category.label),
              labelStyle: theme.textTheme.labelLarge?.copyWith(
                color: category == widget.active ? scheme.surface : scheme.onSurface,
              ),
              side: BorderSide(color: category == widget.active ? scheme.onSurface : scheme.outlineVariant),
              onSelected: (_) {
                HapticFeedback.selectionClick();
                widget.onSelected(category);
              },
            ),
          ],
        ],
      ),
    );
  }
}
