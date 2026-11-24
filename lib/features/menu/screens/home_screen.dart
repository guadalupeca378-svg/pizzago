import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../data/models/pizza.dart';
import '../../orders/widgets/active_order_banner.dart';
import '../catalog_controller.dart';
import '../widgets/cart_peek.dart';
import '../widgets/category_bar.dart';
import '../widgets/home_header.dart';
import '../widgets/product_cards.dart';
import '../widgets/promo_carousel.dart';

/// Inicio: encabezado con búsqueda, barra fija de categorías, pedido en
/// curso, promociones, populares y el menú completo dividido en secciones.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchFocus = FocusNode(debugLabel: 'búsqueda');
  final _scroll = ScrollController();
  final _sectionKeys = {for (final c in PizzaCategory.values) c: GlobalKey(debugLabel: c.name)};
  final _active = ValueNotifier<PizzaCategory?>(null);

  /// Mientras se anima el salto a una sección no se recalcula la activa,
  /// para que los chips intermedios no parpadeen.
  bool _jumping = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_updateActiveSection);
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    _scroll.dispose();
    _active.dispose();
    super.dispose();
  }

  double get _pinnedHeight => PinnedCategoryBar.height + MediaQuery.paddingOf(context).top;

  /// Desplazamiento en el que el título de la sección queda justo debajo de
  /// la barra fija.
  double? _offsetOf(PizzaCategory category) {
    final box = _sectionKeys[category]?.currentContext?.findRenderObject();
    if (box == null || !box.attached) return null;
    return RenderAbstractViewport.of(box).getOffsetToReveal(box, 0).offset - _pinnedHeight;
  }

  void _updateActiveSection() {
    if (_jumping || !_scroll.hasClients) return;
    PizzaCategory? current;
    for (final category in context.read<CatalogController>().categories) {
      final offset = _offsetOf(category);
      if (offset != null && offset <= _scroll.offset + 8) current = category;
    }
    _active.value = current;
  }

  Future<void> _goToSection(PizzaCategory category) async {
    final catalog = context.read<CatalogController>();
    // Si había una búsqueda, se limpia para volver al menú completo.
    if (catalog.isSearching) {
      catalog.search('');
      await WidgetsBinding.instance.endOfFrame;
    }
    final offset = _offsetOf(category);
    if (offset == null || !mounted) return;
    _active.value = category;
    _jumping = true;
    await _scroll.animateTo(
      offset.clamp(0.0, _scroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
    );
    _jumping = false;
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogController>();

    // Ctrl+K (o Cmd+K) enfoca la búsqueda en web y escritorio.
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): _searchFocus.requestFocus,
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true): _searchFocus.requestFocus,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Stack(
            children: [
              RefreshIndicator(
                onRefresh: () => catalog.load(force: true),
                child: CustomScrollView(
                  controller: _scroll,
                  slivers: [
                    SliverToBoxAdapter(child: HomeHeader(searchFocus: _searchFocus)),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: PinnedCategoryBar(
                        topInset: MediaQuery.paddingOf(context).top,
                        categories: catalog.categories,
                        active: _active,
                        onSelected: _goToSection,
                      ),
                    ),
                    if (catalog.isLoading && catalog.items.isEmpty)
                      ..._skeleton()
                    else if (catalog.error != null && catalog.items.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyState(
                          icon: Symbols.wifi_off_rounded,
                          title: 'No pudimos cargar el menú',
                          message: catalog.error,
                          action: FilledButton.tonalIcon(
                            onPressed: () => catalog.load(force: true),
                            icon: const Icon(Symbols.refresh_rounded),
                            label: const Text('Reintentar'),
                          ),
                        ),
                      )
                    else if (catalog.isSearching)
                      ..._searchResults(catalog)
                    else ...[
                      const SliverToBoxAdapter(child: ActiveOrderBanner()),
                      const SliverToBoxAdapter(child: PromoCarousel()),
                      if (catalog.popular.isNotEmpty) ..._popular(catalog.popular),
                      for (final category in catalog.categories)
                        ..._section(category.label, catalog.inCategory(category), key: _sectionKeys[category]),
                    ],
                    // Espacio para que la barra del carrito no tape la última tarjeta.
                    const SliverToBoxAdapter(child: SizedBox(height: 104)),
                  ],
                ),
              ),
              const Positioned(left: 16, right: 16, bottom: 14, child: CartPeek()),
            ],
          ),
        ),
      ),
    );
  }

  static const _grid = SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 560,
    mainAxisExtent: MenuItemCard.height,
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
  );

  List<Widget> _skeleton() => [
    const SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 28, 20, 14),
        child: Shimmer(child: SkeletonBox(width: 160, height: 22)),
      ),
    ),
    SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid.builder(
        gridDelegate: _grid,
        itemCount: 6,
        itemBuilder: (_, _) => const Shimmer(child: MenuCardSkeleton()),
      ),
    ),
  ];

  List<Widget> _popular(List<Pizza> popular) => [
    const SliverToBoxAdapter(
      child: SectionHeader(
        'Populares',
        trailing: 'Lo más pedido esta semana',
        padding: EdgeInsets.fromLTRB(20, 28, 20, 12),
      ),
    ),
    SliverToBoxAdapter(
      child: SizedBox(
        height: PopularCard.height + 12,
        child: ListView.separated(
          // Espacio inferior para que se vea la sombra.
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          scrollDirection: Axis.horizontal,
          itemCount: popular.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, i) => EntranceAnimation(
            index: i,
            child: PressableScale(
              child: PopularCard(pizza: popular[i], topSeller: i == 0),
            ),
          ),
        ),
      ),
    ),
  ];

  List<Widget> _searchResults(CatalogController catalog) {
    final results = catalog.searchResults;
    if (results.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyState(
            icon: Symbols.search_off_rounded,
            title: 'Sin resultados',
            message: 'Prueba con otro producto o ingrediente.',
          ),
        ),
      ];
    }
    return _section('Resultados', results);
  }

  List<Widget> _section(String title, List<Pizza> items, {Key? key}) {
    if (items.isEmpty) return const [];
    final count = Fmt.count(items.length, 'producto');
    return [
      SliverToBoxAdapter(
        child: SectionHeader(title, key: key, trailing: count),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverGrid.builder(
          gridDelegate: _grid,
          itemCount: items.length,
          itemBuilder: (_, i) => EntranceAnimation(
            index: i,
            child: PressableScale(child: MenuItemCard(pizza: items[i])),
          ),
        ),
      ),
    ];
  }
}
