import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/product_image.dart';
import '../../../data/models/promo.dart';
import '../../cart/widgets/coupon_field.dart';

/// Banners de promociones con avance automático cada 5 s. Los que traen
/// cupón lo aplican al carrito al tocarlos.
class PromoCarousel extends StatefulWidget {
  const PromoCarousel({super.key});

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  // Los banners miden como máximo ~460 px; en pantallas anchas se ven
  // varios a la vez. El controlador se recrea si cambia esa proporción.
  PageController _controller = PageController(viewportFraction: .9);
  double _fraction = .9;
  Timer? _timer;
  int _page = 0;

  static const _promos = Promo.current;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_controller.hasClients) return;
      _controller.animateToPage(
        (_page + 1) % _promos.length,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _apply(String code) {
    final error = tryApplyCoupon(context, code);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error ?? 'Cupón $code aplicado a tu carrito')));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, constraints) {
            final fraction = ((480 / constraints.maxWidth).clamp(.3, .9) * 100).round() / 100;
            if (fraction != _fraction) {
              final old = _controller;
              _fraction = fraction;
              _controller = PageController(viewportFraction: fraction, initialPage: _page);
              WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
            }
            return SizedBox(
              height: 148,
              child: PageView.builder(
                key: ValueKey(_fraction),
                controller: _controller,
                itemCount: _promos.length,
                padEnds: false,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final promo = _promos[i];
                  return Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: PressableScale(
                      child: _PromoBanner(
                        promo: promo,
                        onTap: promo.couponCode == null ? null : () => _apply(promo.couponCode!),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _promos.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _page ? scheme.onSurface : scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Banner con el mismo estilo para todas las promociones: fondo café muy
/// oscuro, la foto del producto a la derecha (se funde con el fondo) y el
/// texto a la izquierda con el rojo de la marca como acento.
class _PromoBanner extends StatelessWidget {
  const _PromoBanner({required this.promo, this.onTap});

  final Promo promo;
  final VoidCallback? onTap;

  static const _ink = Color(0xFF211915);
  static const _accent = Color(0xFFFF8A65);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: ColoredBox(
        color: _ink,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FractionallySizedBox(
              alignment: Alignment.centerRight,
              widthFactor: .5,
              child: Image.asset(AppImages.product(promo.photo), fit: BoxFit.cover),
            ),
            // La foto se funde con el fondo para que el texto se lea.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(stops: [.5, .8], colors: [_ink, Color(0x00211915)]),
              ),
            ),
            // El texto ocupa la parte izquierda; la foto se ve a la derecha.
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: .6,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 8, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      promo.eyebrow,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _accent,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      promo.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppTheme.tomato, borderRadius: BorderRadius.circular(999)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              promo.cta,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Symbols.arrow_forward_rounded, size: 14, color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned.fill(
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(onTap: onTap),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
