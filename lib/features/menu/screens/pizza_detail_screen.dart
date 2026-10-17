import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/product_image.dart';
import '../../../core/widgets/surface_card.dart';
import '../../../data/models/cart_item.dart';
import '../../../data/models/pizza.dart';
import '../../cart/cart_controller.dart';
import '../catalog_controller.dart';
import '../widgets/detail_options.dart';
import '../widgets/product_cards.dart';

class PizzaDetailScreen extends StatefulWidget {
  const PizzaDetailScreen({super.key, required this.pizzaId});

  final String pizzaId;

  @override
  State<PizzaDetailScreen> createState() => _PizzaDetailScreenState();
}

/// Mismo ancho que el contenido (ResponsiveCenter) para que todo alinee.
const _photoMaxWidth = 720.0;

/// Desde este ancho el detalle se muestra en dos columnas.
const _twoColumnsFrom = 960.0;

class _PizzaDetailScreenState extends State<PizzaDetailScreen> {
  PizzaSize _size = PizzaSize.mediana;
  final Set<String> _extraIds = {};
  int _quantity = 1;
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Si se abre el enlace directo (p. ej. recargando en web) el menú aún no
    // está cargado.
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<CatalogController>().load());
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  /// Lo que se agregaría al carrito con las opciones elegidas. Su precio
  /// (tamaño + extras) se calcula igual que en el carrito.
  CartItem _draft(Pizza pizza, List<Extra> extras) => CartItem(
    pizza: pizza,
    size: pizza.hasSizes ? _size : pizza.defaultSize,
    extras: extras,
    quantity: _quantity,
    note: _note.text.trim(),
  );

  void _addToCart(Pizza pizza, List<Extra> extras) {
    final router = GoRouter.of(context);
    HapticFeedback.lightImpact();
    context.read<CartController>().add(_draft(pizza, extras));
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(AppRoutes.home);
    }
  }

  void _toggleExtra(Extra extra) {
    HapticFeedback.selectionClick();
    setState(() => _extraIds.contains(extra.id) ? _extraIds.remove(extra.id) : _extraIds.add(extra.id));
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogController>();
    final pizza = catalog.byId(widget.pizzaId);

    if (pizza == null) {
      return Scaffold(
        appBar: AppBar(),
        body: catalog.hasLoaded
            ? EmptyState(
                icon: Symbols.no_meals_rounded,
                title: 'Este producto ya no está disponible',
                action: FilledButton.tonal(
                  onPressed: () => context.go(AppRoutes.home),
                  child: const Text('Volver al menú'),
                ),
              )
            : const Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selectedExtras = pizza.acceptsExtras
        ? catalog.extras.where((e) => _extraIds.contains(e.id)).toList()
        : const <Extra>[];
    final draft = _draft(pizza, selectedExtras);
    final unitPrice = draft.unitPrice;
    final total = draft.total;

    // Al subir de tamaño la foto se acerca un poco.
    final photoZoom = pizza.hasSizes ? const [1.0, 1.06, 1.12][_size.index] : 1.0;
    final wide = MediaQuery.sizeOf(context).width >= 720;

    Widget circleButton({required IconData icon, required String tooltip, required VoidCallback onPressed}) =>
        IconButton(tooltip: tooltip, style: AppTheme.overlayIconButton(scheme), onPressed: onPressed, icon: Icon(icon));

    // Foto con los botones de regresar y favorito encima.
    final photo = Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: AnimatedScale(
            scale: photoZoom,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            child: Hero(
              tag: 'product-${pizza.id}',
              child: ProductImage(pizza: pizza),
            ),
          ),
        ),
        // Sombra suave arriba para que los botones se lean sobre la foto.
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment(0, -.3),
                colors: [Color(0x59000000), Color(0x00000000)],
              ),
            ),
          ),
        ),
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                circleButton(
                  icon: Symbols.arrow_back_rounded,
                  tooltip: 'Regresar',
                  onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.home),
                ),
                const Spacer(),
                FavoriteButton(pizzaId: pizza.id, filled: true),
              ],
            ),
          ),
        ),
      ],
    );

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pizza.category.label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.primary,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(pizza.name, style: theme.textTheme.headlineSmall)),
            const SizedBox(width: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, a) => FadeTransition(opacity: a, child: child),
              child: Text(Fmt.money(unitPrice), key: ValueKey(unitPrice), style: theme.textTheme.headlineSmall),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            InfoPill(icon: Symbols.star_rounded, label: '${pizza.rating}', color: const Color(0xFFE8A317)),
            InfoPill(icon: Symbols.schedule_rounded, label: '${pizza.prepMinutes} min'),
            if (pizza.isSpicy)
              InfoPill(icon: Symbols.local_fire_department_rounded, label: 'Picante', color: scheme.error),
            if (pizza.showsVeggieBadge)
              InfoPill(icon: Symbols.eco_rounded, label: 'Vegetariana', color: scheme.secondary),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          pizza.description,
          style: theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant, height: 1.5),
        ),
        if (pizza.ingredients.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Ingredientes: ${pizza.ingredients.join(', ')}.',
            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
        if (pizza.hasSizes) ...[
          const OptionHeading('Tamaño', hint: 'Obligatorio'),
          Row(
            children: [
              for (final size in PizzaSize.values) ...[
                if (size != PizzaSize.chica) const SizedBox(width: 10),
                Expanded(
                  child: SizeOption(
                    size: size,
                    price: pizza.priceFor(size),
                    selected: _size == size,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _size = size);
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
        if (pizza.acceptsExtras && catalog.extras.isNotEmpty) ...[
          OptionHeading('Extras', hint: _extraIds.isEmpty ? 'Opcional' : '${_extraIds.length} elegidos'),
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, extra) in catalog.extras.indexed) ...[
                  if (i > 0) const Divider(indent: 68),
                  ExtraRow(extra: extra, selected: _extraIds.contains(extra.id), onTap: () => _toggleExtra(extra)),
                ],
              ],
            ),
          ),
        ],
        const OptionHeading('Instrucciones especiales', hint: 'Opcional'),
        TextField(
          controller: _note,
          maxLines: 2,
          maxLength: 120,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Ej. sin cebolla, bien dorada…'),
        ),
      ],
    );

    final Widget body;
    if (MediaQuery.sizeOf(context).width >= _twoColumnsFrom) {
      // Escritorio: la foto se queda fija a la izquierda y las opciones se
      // desplazan a la derecha.
      body = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 12, 24),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: ClipRRect(borderRadius: BorderRadius.circular(AppTheme.radius), child: photo),
                  ),
                ),
              ),
              Expanded(
                flex: 6,
                child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(12, 16, 24, 24), child: details),
              ),
            ],
          ),
        ),
      );
    } else {
      body = CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            // En el celular la foto va de orilla a orilla; en tableta se
            // limita y redondea para que no se estire ni pierda nitidez.
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _photoMaxWidth),
                child: Padding(
                  padding: wide ? const EdgeInsets.fromLTRB(24, 16, 24, 0) : EdgeInsets.zero,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(wide ? AppTheme.radius : 0),
                    child: SizedBox(height: (wide ? 360 : 320) + MediaQuery.paddingOf(context).top, child: photo),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ResponsiveCenter(
              child: Padding(padding: const EdgeInsets.fromLTRB(20, 24, 20, 24), child: details),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: BottomActionBar(
        child: Row(
          children: [
            QuantityStepper(
              value: _quantity,
              max: CartController.maxQuantity,
              onChanged: (q) => setState(() => _quantity = q),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _addToCart(pizza, selectedExtras),
                icon: const Icon(Symbols.shopping_bag_rounded),
                label: Text('Agregar · ${Fmt.money(total)}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
