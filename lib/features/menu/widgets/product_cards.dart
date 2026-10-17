import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/product_image.dart';
import '../../../core/widgets/surface_card.dart';
import '../../../data/models/cart_item.dart';
import '../../../data/models/pizza.dart';
import '../../cart/cart_controller.dart';
import '../catalog_controller.dart';

/// Foto del producto recortada con esquinas redondeadas.
/// El Hero conecta esta imagen con la del detalle.
class ProductThumb extends StatelessWidget {
  const ProductThumb({
    super.key,
    required this.pizza,
    required this.size,
    this.radius = AppTheme.radiusSm,
    this.hero = false,
  });

  final Pizza pizza;
  final double size;
  final double radius;
  final bool hero;

  @override
  Widget build(BuildContext context) {
    final image = ProductImage(pizza: pizza);
    return SizedBox.square(
      dimension: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          child: hero ? Hero(tag: 'product-${pizza.id}', child: image) : image,
        ),
      ),
    );
  }
}

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key, required this.pizzaId, this.filled = false});

  final String pizzaId;

  /// Versión con fondo circular, para ir sobre imágenes.
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final isFav = context.select<CatalogController, bool>((c) => c.isFavorite(pizzaId));
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: isFav ? 'Quitar de favoritos' : 'Agregar a favoritos',
      visualDensity: VisualDensity.compact,
      style: filled ? AppTheme.overlayIconButton(scheme) : null,
      onPressed: () {
        HapticFeedback.selectionClick();
        context.read<CatalogController>().toggleFavorite(pizzaId);
      },
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, a) => ScaleTransition(
          scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack),
          child: child,
        ),
        child: Icon(
          Symbols.favorite_rounded,
          key: ValueKey(isFav),
          fill: isFav ? 1 : 0,
          size: 20,
          color: isFav ? AppTheme.tomato : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Botón "+" de las tarjetas. Bebidas y postres (precio único) se agregan
/// directo; las pizzas abren el detalle para elegir tamaño, porque la tarjeta
/// muestra el precio "desde" de la chica.
void quickAdd(BuildContext context, Pizza pizza) {
  if (pizza.hasSizes) {
    context.push(AppRoutes.pizza(pizza.id));
    return;
  }
  HapticFeedback.lightImpact();
  context.read<CartController>().add(CartItem(pizza: pizza, size: pizza.defaultSize));
}

/// Precio de lista: "desde $159" en pizzas (precio de la chica) y el precio
/// único en bebidas y postres. Es el mismo en todas las tarjetas.
class PriceLabel extends StatelessWidget {
  const PriceLabel(this.pizza, {super.key, this.style});

  final Pizza pizza;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text.rich(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      TextSpan(
        children: [
          if (pizza.hasSizes)
            TextSpan(
              text: 'desde ',
              style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          TextSpan(
            text: Fmt.money(pizza.startingPrice),
            style: style?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.pizza});

  final Pizza pizza;

  @override
  Widget build(BuildContext context) => IconButton.filled(
    tooltip: pizza.hasSizes ? 'Elegir tamaño' : 'Agregar al carrito',
    visualDensity: VisualDensity.compact,
    onPressed: () => quickAdd(context, pizza),
    icon: const Icon(Symbols.add_rounded, weight: 600),
  );
}

/// Ícono de dieta (picante / vegetariana) junto al nombre del producto.
/// El nombre completo aparece al mantener el puntero o en lectores de pantalla.
class DietIcon extends StatelessWidget {
  const DietIcon(this.pizza, {super.key});

  final Pizza pizza;

  @override
  Widget build(BuildContext context) {
    if (!pizza.isSpicy && !pizza.showsVeggieBadge) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final spicy = pizza.isSpicy;
    return Tooltip(
      message: spicy ? 'Picante' : 'Vegetariana',
      child: Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Icon(
          spicy ? Symbols.local_fire_department_rounded : Symbols.eco_rounded,
          fill: 1,
          size: 16,
          color: spicy ? scheme.error : scheme.secondary,
        ),
      ),
    );
  }
}

/// Renglón del menú: foto a la izquierda; nombre, descripción y precio.
class MenuItemCard extends StatelessWidget {
  const MenuItemCard({super.key, required this.pizza});

  static const height = 128.0;

  final Pizza pizza;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SurfaceCard(
      padding: const EdgeInsets.all(12),
      onTap: () => context.push(AppRoutes.pizza(pizza.id)),
      child: Row(
        children: [
          ProductThumb(pizza: pizza, size: 104, hero: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Picante / vegetariana como ícono junto al nombre, para que
                    // el precio quede siempre a la misma altura en todas las tarjetas.
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              pizza.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          DietIcon(pizza),
                        ],
                      ),
                    ),
                    FavoriteButton(pizzaId: pizza.id),
                  ],
                ),
                Text(pizza.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
                const Spacer(),
                Row(
                  children: [
                    Expanded(child: PriceLabel(pizza, style: theme.textTheme.titleMedium)),
                    _AddButton(pizza: pizza),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta vertical de la sección "Populares". La primera lleva la etiqueta
/// "Más pedida".
class PopularCard extends StatelessWidget {
  const PopularCard({super.key, required this.pizza, this.topSeller = false});

  static const width = 176.0;
  static const height = 232.0;

  final Pizza pizza;
  final bool topSeller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: SurfaceCard(
        padding: const EdgeInsets.all(10),
        onTap: () => context.push(AppRoutes.pizza(pizza.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ProductThumb(pizza: pizza, size: width - 20),
                if (topSeller)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppTheme.tomato, borderRadius: BorderRadius.circular(999)),
                      child: Text(
                        'Más pedida',
                        style: theme.textTheme.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(pizza.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(child: PriceLabel(pizza, style: theme.textTheme.titleSmall)),
                const Icon(Symbols.star_rounded, fill: 1, size: 16, color: Color(0xFFE8A317)),
                const SizedBox(width: 2),
                Text('${pizza.rating}', style: theme.textTheme.labelMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta horizontal compacta (favoritos en el perfil).
class PizzaTile extends StatelessWidget {
  const PizzaTile({super.key, required this.pizza, this.width = 250});

  final Pizza pizza;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: SurfaceCard(
        padding: const EdgeInsets.all(10),
        onTap: () => context.push(AppRoutes.pizza(pizza.id)),
        child: Row(
          children: [
            ProductThumb(pizza: pizza, size: 64),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pizza.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
                  PriceLabel(pizza, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
