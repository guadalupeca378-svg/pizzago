import 'package:flutter/foundation.dart';

/// Banner de promoción del inicio. Si trae [couponCode], al tocarlo se
/// aplica ese cupón al carrito.
@immutable
class Promo {
  const Promo({required this.eyebrow, required this.title, required this.cta, required this.photo, this.couponCode});

  final String eyebrow;
  final String title;
  final String cta;

  /// Producto cuya foto ilustra el banner.
  final String photo;
  final String? couponCode;

  /// Promociones vigentes. Los códigos coinciden con los cupones de
  /// `CartController.availableCoupons`.
  static const current = <Promo>[
    Promo(
      eyebrow: 'CUPÓN PIZZAGO10',
      title: '10% de descuento en todo tu pedido',
      cta: 'Aplicar cupón',
      photo: 'pepperoni',
      couponCode: 'PIZZAGO10',
    ),
    Promo(
      eyebrow: 'NUEVOS CLIENTES',
      title: r'$50 de regalo en tu primer pedido',
      cta: 'Aplicar cupón',
      photo: 'margarita',
      couponCode: 'BIENVENIDA',
    ),
    Promo(eyebrow: 'ENVÍO GRATIS', title: r'En pedidos desde $400', cta: 'Ver menú', photo: 'suprema'),
  ];
}
