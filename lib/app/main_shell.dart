import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/brand.dart';
import '../features/cart/cart_controller.dart';

typedef _Destination = ({IconData icon, String label});

const _destinations = <_Destination>[
  (icon: Symbols.home_rounded, label: 'Inicio'),
  (icon: Symbols.shopping_bag_rounded, label: 'Carrito'),
  (icon: Symbols.receipt_long_rounded, label: 'Pedidos'),
  (icon: Symbols.person_rounded, label: 'Perfil'),
];

/// Navegación principal adaptable (Material 3): NavigationBar en teléfono y
/// NavigationRail a partir de 840 px (tablet, web, escritorio).
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _wideBreakpoint = 840.0;

  void _onSelect(int index) {
    HapticFeedback.selectionClick();
    navigationShell.goBranch(
      index,
      // Tocar de nuevo la pestaña activa regresa a su pantalla inicial.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.select<CartController, int>((c) => c.itemCount);
    final current = navigationShell.currentIndex;
    final scheme = Theme.of(context).colorScheme;
    final wide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: current,
              onDestinationSelected: _onSelect,
              labelType: NavigationRailLabelType.all,
              groupAlignment: -.8,
              leading: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 24),
                child: Column(
                  children: [
                    const AppLogo(size: 40),
                    const SizedBox(height: 6),
                    Text(
                      'PizzaGo',
                      style: TextStyle(fontFamily: AppTheme.serif, fontSize: 18, color: scheme.onSurface),
                    ),
                  ],
                ),
              ),
              destinations: [
                for (final (i, d) in _destinations.indexed)
                  NavigationRailDestination(
                    icon: _NavIcon(d: d, index: i, selected: false, cartCount: cartCount),
                    selectedIcon: _NavIcon(d: d, index: i, selected: true, cartCount: cartCount),
                    label: Text(d.label),
                  ),
              ],
            ),
            VerticalDivider(width: 1, color: scheme.outlineVariant),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: NavigationBar(
          selectedIndex: current,
          onDestinationSelected: _onSelect,
          destinations: [
            for (final (i, d) in _destinations.indexed)
              NavigationDestination(
                icon: _NavIcon(d: d, index: i, selected: false, cartCount: cartCount),
                selectedIcon: _NavIcon(d: d, index: i, selected: true, cartCount: cartCount),
                label: d.label,
              ),
          ],
        ),
      ),
    );
  }
}

/// Ícono de destino: al activarse se "rellena" animando el eje FILL de
/// Material Symbols; el del carrito lleva un badge que salta al cambiar.
class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.d, required this.index, required this.selected, required this.cartCount});

  final _Destination d;
  final int index;
  final bool selected;
  final int cartCount;

  @override
  Widget build(BuildContext context) {
    final icon = TweenAnimationBuilder<double>(
      tween: Tween(begin: selected ? 0 : 1, end: selected ? 1 : 0),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (_, fill, _) => Icon(d.icon, fill: fill, weight: selected ? 600 : 400),
    );
    if (index != 1) return icon;
    return TweenAnimationBuilder<double>(
      key: ValueKey(cartCount),
      tween: Tween(begin: cartCount == 0 ? 1 : 1.3, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.elasticOut,
      builder: (_, scale, child) => Badge.count(
        count: cartCount,
        isLabelVisible: cartCount > 0,
        child: Transform.scale(scale: scale, child: child),
      ),
      child: icon,
    );
  }
}
