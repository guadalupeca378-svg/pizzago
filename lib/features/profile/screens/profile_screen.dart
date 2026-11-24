import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/theme_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/surface_card.dart';
import '../../../data/models/app_user.dart';
import '../../auth/auth_controller.dart';
import '../../cart/cart_controller.dart';
import '../../menu/catalog_controller.dart';
import '../../menu/widgets/product_cards.dart';
import '../../orders/order_controller.dart';
import '../widgets/app_data_cards.dart';
import '../widgets/edit_profile_sheet.dart';
import '../widgets/stat_tile.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmSignOut(BuildContext context) async {
    final auth = context.read<AuthController>();
    final cart = context.read<CartController>();
    final ok = await showConfirmDialog(
      context,
      icon: Symbols.logout_rounded,
      title: '¿Cerrar sesión?',
      message: 'Tu carrito se vaciará.',
      confirmLabel: 'Cerrar sesión',
    );
    if (ok) {
      cart.clear();
      await auth.signOut();
    }
  }

  void _editProfile(BuildContext context, AppUser user) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => EditProfileSheet(user: user),
  );

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    if (user == null) return const SizedBox.shrink();

    final orders = context.watch<OrderController>();
    final favorites = context.watch<CatalogController>().favoriteItems;
    final themeMode = context.watch<ThemeController>().mode;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: ResponsiveCenter(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            SurfaceCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: scheme.primaryContainer,
                    child: Text(
                      user.initials,
                      style: theme.textTheme.titleLarge?.copyWith(color: scheme.onPrimaryContainer),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: theme.textTheme.titleMedium),
                        Text(user.email, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                    onPressed: () => _editProfile(context, user),
                    child: const Text('Editar'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final (i, (icon, value, label)) in [
                  (Symbols.receipt_long_rounded, '${orders.orders.length}', 'Pedidos'),
                  (Symbols.favorite_rounded, '${favorites.length}', 'Favoritos'),
                  (Symbols.payments_rounded, Fmt.money(orders.totalSpent), 'Gastado'),
                ].indexed) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(
                    child: EntranceAnimation(
                      index: i,
                      child: StatTile(icon: icon, value: value, label: label),
                    ),
                  ),
                ],
              ],
            ),
            const SectionHeader('Favoritos', padding: EdgeInsets.only(top: 28, bottom: 12)),
            if (favorites.isEmpty)
              SurfaceCard(
                child: Row(
                  children: [
                    Icon(Symbols.favorite_rounded, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Toca el corazón de cualquier producto para guardarlo aquí.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: favorites.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => PizzaTile(pizza: favorites[i]),
                ),
              ),
            const SectionHeader('Datos de entrega', padding: EdgeInsets.only(top: 28, bottom: 12)),
            SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Symbols.location_on_rounded),
                    title: Text(user.address.isEmpty ? 'Sin dirección guardada' : user.address),
                    subtitle: const Text('Dirección'),
                    trailing: const Icon(Symbols.chevron_right_rounded),
                    onTap: () => _editProfile(context, user),
                  ),
                  const Divider(indent: 56),
                  ListTile(
                    leading: const Icon(Symbols.phone_rounded),
                    title: Text(user.phone.isEmpty ? 'Sin teléfono guardado' : user.phone),
                    subtitle: const Text('Teléfono'),
                    trailing: const Icon(Symbols.chevron_right_rounded),
                    onTap: () => _editProfile(context, user),
                  ),
                ],
              ),
            ),
            const SectionHeader('Notificaciones', padding: EdgeInsets.only(top: 28, bottom: 12)),
            const NotificationsCard(),
            const SectionHeader('Datos de la aplicación', padding: EdgeInsets.only(top: 28, bottom: 12)),
            const AppDataCard(),
            const SectionHeader('Apariencia', padding: EdgeInsets.only(top: 28, bottom: 12)),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    icon: Icon(Symbols.brightness_auto_rounded),
                    label: Text('Sistema'),
                  ),
                  ButtonSegment(value: ThemeMode.light, icon: Icon(Symbols.light_mode_rounded), label: Text('Claro')),
                  ButtonSegment(value: ThemeMode.dark, icon: Icon(Symbols.dark_mode_rounded), label: Text('Oscuro')),
                ],
                selected: {themeMode},
                showSelectedIcon: false,
                onSelectionChanged: (s) {
                  HapticFeedback.selectionClick();
                  context.read<ThemeController>().setMode(s.first);
                },
              ),
            ),
            const SectionHeader('Cuenta', padding: EdgeInsets.only(top: 28, bottom: 12)),
            SurfaceCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(Symbols.logout_rounded, color: scheme.error),
                title: Text('Cerrar sesión', style: TextStyle(color: scheme.error)),
                onTap: () => _confirmSignOut(context),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'PizzaGo 1.1.0',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
