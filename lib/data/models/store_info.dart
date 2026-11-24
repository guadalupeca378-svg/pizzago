import 'package:flutter/foundation.dart';

import 'pizza_order.dart';

/// Datos de la pizzería que se muestran en el encabezado del inicio y que
/// usan el carrito (costo de envío) y los pedidos (tiempo de entrega).
@immutable
class StoreInfo {
  const StoreInfo({
    required this.name,
    required this.tagline,
    required this.opensAtHour,
    required this.closesAtHour,
    required this.minDeliveryMinutes,
    required this.maxDeliveryMinutes,
    required this.deliveryFee,
    required this.freeDeliveryFrom,
  });

  static const pizzago = StoreInfo(
    name: 'PizzaGo',
    tagline: 'Pizzería artesanal · Horno de piedra',
    opensAtHour: 12,
    closesAtHour: 23,
    minDeliveryMinutes: 25,
    maxDeliveryMinutes: PizzaOrder.deliveryMinutes,
    deliveryFee: 39,
    freeDeliveryFrom: 400,
  );

  final String name;
  final String tagline;
  final int opensAtHour;
  final int closesAtHour;
  final int minDeliveryMinutes;
  final int maxDeliveryMinutes;
  final double deliveryFee;
  final double freeDeliveryFrom;

  bool isOpenAt(DateTime now) => now.hour >= opensAtHour && now.hour < closesAtHour;

  /// "cierra a las 23:00" o "abre a las 12:00", según la hora.
  String scheduleAt(DateTime now) =>
      isOpenAt(now) ? 'cierra a las ${_hour(closesAtHour)}' : 'abre a las ${_hour(opensAtHour)}';

  String get deliveryWindow => '$minDeliveryMinutes–$maxDeliveryMinutes min';

  static String _hour(int h) => '${h.toString().padLeft(2, '0')}:00';
}
