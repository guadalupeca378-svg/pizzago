import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/surface_card.dart';
import '../../orders/order_controller.dart';
import '../cart_controller.dart';

/// Aplica un cupón al carrito revisando que exista y que el usuario pueda
/// usarlo. Devuelve el mensaje de error, o `null` si se aplicó. Lo usan el
/// campo de cupón del carrito y los banners de promociones.
String? tryApplyCoupon(BuildContext context, String code) {
  final coupon = CartController.couponFor(code);
  if (coupon == null) return 'Ese cupón no existe';
  if (!context.read<OrderController>().canUse(coupon)) return 'Ese cupón es solo para tu primer pedido';
  context.read<CartController>().applyCoupon(coupon.code);
  return null;
}

class CouponField extends StatefulWidget {
  const CouponField({super.key});

  @override
  State<CouponField> createState() => _CouponFieldState();
}

class _CouponFieldState extends State<CouponField> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply() {
    final error = tryApplyCoupon(context, _controller.text);
    setState(() => _error = error);
    if (error == null) {
      _controller.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final coupon = context.select<CartController, String?>((c) => c.coupon?.code);
    final label = context.select<CartController, String?>((c) => c.coupon?.label);

    if (coupon != null) {
      return SurfaceCard(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Icon(Symbols.local_offer_rounded, fill: 1, color: scheme.secondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(coupon, style: theme.textTheme.titleSmall?.copyWith(letterSpacing: 1)),
                  Text(label ?? '', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            TextButton(onPressed: () => context.read<CartController>().removeCoupon(), child: const Text('Quitar')),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            textCapitalization: TextCapitalization.characters,
            onSubmitted: (_) => _apply(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Symbols.local_offer_rounded),
              hintText: 'Código de cupón',
              helperText: _error == null ? 'Prueba con PIZZAGO10' : null,
              errorText: _error,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 54,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
            ),
            onPressed: _apply,
            child: const Text('Aplicar'),
          ),
        ),
      ],
    );
  }
}
