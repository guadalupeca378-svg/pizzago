import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/common.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/store_info.dart';
import '../../auth/auth_controller.dart';
import '../catalog_controller.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key, required this.searchFocus});

  final FocusNode searchFocus;

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthController, AppUser?>((a) => a.user);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      bottom: false,
      child: ResponsiveCenter(
        maxWidth: double.infinity,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // En pantallas anchas el logo ya está en la barra lateral.
                  if (MediaQuery.sizeOf(context).width < 840) ...[const AppLogo(size: 40), const SizedBox(width: 12)],
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      onTap: () => context.go(AppRoutes.profile),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Entregar en',
                              style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    (user?.address.isEmpty ?? true) ? 'Agrega tu dirección' : user!.address,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.titleSmall,
                                  ),
                                ),
                                const Icon(Symbols.expand_more_rounded, size: 20),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const _ThemeToggle(),
                  const SizedBox(width: 4),
                  Tooltip(
                    message: 'Mi perfil',
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => context.go(AppRoutes.profile),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: scheme.primaryContainer,
                        foregroundColor: scheme.onPrimaryContainer,
                        child: Text(
                          user?.initials ?? '',
                          style: theme.textTheme.labelLarge?.copyWith(color: scheme.onPrimaryContainer),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const _StoreSummary(),
              const SizedBox(height: 16),
              _SearchField(focusNode: searchFocus),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ficha de la pizzería, como en las apps de comida a domicilio: nombre,
/// especialidad, si está abierta, calificación, tiempo y costo de envío.
class _StoreSummary extends StatelessWidget {
  const _StoreSummary();

  static const _store = StoreInfo.pizzago;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rating = context.select<CatalogController, double?>((c) => c.averageRating);
    final muted = theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);

    Widget dot() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text('·', style: muted),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _store.name,
          style: TextStyle(fontFamily: AppTheme.serif, fontSize: 32, height: 1.1, color: scheme.onSurface),
        ),
        const SizedBox(height: 2),
        Text(_store.tagline, style: muted),
        const SizedBox(height: 12),
        // Se recalcula cada minuto para que "Abierto" cambie a la hora justa.
        ClockBuilder(
          interval: const Duration(minutes: 1),
          builder: (context, now) {
            final open = _store.isOpenAt(now);
            final statusColor = open ? scheme.secondary : scheme.error;
            return Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 4,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                ),
                Text(
                  open ? 'Abierto' : 'Cerrado',
                  style: theme.textTheme.bodyMedium?.copyWith(color: statusColor, fontWeight: FontWeight.w600),
                ),
                Text(' · ${_store.scheduleAt(now)}', style: muted),
                if (rating != null) ...[
                  dot(),
                  const Icon(Symbols.star_rounded, fill: 1, size: 16, color: Color(0xFFE8A317)),
                  const SizedBox(width: 3),
                  Text(rating.toStringAsFixed(1), style: theme.textTheme.bodyMedium),
                ],
                dot(),
                Text(_store.deliveryWindow, style: theme.textTheme.bodyMedium),
                dot(),
                Text(
                  'Envío ${Fmt.money(_store.deliveryFee)} · gratis desde ${Fmt.money(_store.freeDeliveryFrom)}',
                  style: muted,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: isDark ? 'Modo claro' : 'Modo oscuro',
      onPressed: () => context.read<ThemeController>().setMode(isDark ? ThemeMode.light : ThemeMode.dark),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, a) => RotationTransition(turns: a, child: child),
        child: Icon(isDark ? Symbols.light_mode_rounded : Symbols.dark_mode_rounded, key: ValueKey(isDark)),
      ),
    );
  }
}

/// Búsqueda con *debounce*: filtra 300 ms después de la última tecla.
class _SearchField extends StatefulWidget {
  const _SearchField({required this.focusNode});

  final FocusNode focusNode;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _controller = TextEditingController(text: context.read<CatalogController>().query);
  Timer? _debounce;

  void _onChanged(String value) {
    setState(() {}); // muestra/oculta el botón de limpiar
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => context.read<CatalogController>().search(value));
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    context.read<CatalogController>().search('');
    setState(() {});
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si la búsqueda se limpió desde fuera (p. ej. al tocar una categoría),
    // el texto del campo también se borra.
    final query = context.select<CatalogController, String>((c) => c.query);
    if (query.isEmpty && _controller.text.isNotEmpty && !(_debounce?.isActive ?? false)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(_controller.clear);
      });
    }
    final scheme = Theme.of(context).colorScheme;
    return SearchBar(
      controller: _controller,
      focusNode: widget.focusNode,
      hintText: 'Busca pizzas, ingredientes o bebidas',
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStatePropertyAll(AppTheme.cardColor(scheme)),
      side: WidgetStateProperty.resolveWith(
        (states) => BorderSide(
          color: states.contains(WidgetState.focused) ? scheme.primary : scheme.outlineVariant,
          width: states.contains(WidgetState.focused) ? 1.6 : 1,
        ),
      ),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm))),
      constraints: const BoxConstraints(minHeight: 52),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16)),
      leading: Icon(Symbols.search_rounded, color: scheme.onSurfaceVariant),
      trailing: [
        if (_controller.text.isNotEmpty)
          IconButton(tooltip: 'Limpiar', onPressed: _clear, icon: const Icon(Symbols.close_rounded)),
      ],
      onChanged: _onChanged,
    );
  }
}
