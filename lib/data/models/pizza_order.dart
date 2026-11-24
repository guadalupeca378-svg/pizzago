import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'cart_item.dart';

enum OrderStatus {
  recibido('Recibido', 'Recibimos tu pedido', Symbols.receipt_long_rounded),
  preparando('En preparación', 'Tu pizza está en el horno', Symbols.soup_kitchen_rounded),
  enCamino('En camino', 'El repartidor va hacia ti', Symbols.delivery_dining_rounded),
  entregado('Entregado', '¡Buen provecho!', Symbols.check_circle_rounded);

  const OrderStatus(this.label, this.message, this.icon);

  final String label;
  final String message;
  final IconData icon;
}

enum PaymentMethod {
  efectivo('Efectivo', Symbols.payments_rounded),
  tarjeta('Tarjeta al recibir', Symbols.credit_card_rounded);

  const PaymentMethod(this.label, this.icon);

  final String label;
  final IconData icon;

  static PaymentMethod fromName(String name) => values.firstWhere((p) => p.name == name, orElse: () => efectivo);
}

@immutable
class PizzaOrder {
  const PizzaOrder({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.deliveryFee,
    required this.total,
    required this.createdAt,
    required this.address,
    required this.phone,
    required this.paymentMethod,
    this.notes = '',
    this.couponCode,
  });

  factory PizzaOrder.fromMap(Map<String, dynamic> map) => PizzaOrder(
    id: map['id'] as String,
    userId: map['userId'] as String,
    items: (map['items'] as List).map((e) => CartItem.fromMap(Map<String, dynamic>.from(e as Map))).toList(),
    subtotal: (map['subtotal'] as num).toDouble(),
    discount: (map['discount'] as num).toDouble(),
    deliveryFee: (map['deliveryFee'] as num).toDouble(),
    total: (map['total'] as num).toDouble(),
    createdAt: DateTime.parse(map['createdAt'] as String),
    address: map['address'] as String,
    phone: map['phone'] as String,
    paymentMethod: PaymentMethod.fromName(map['paymentMethod'] as String),
    notes: map['notes'] as String? ?? '',
    couponCode: map['couponCode'] as String?,
  );

  /// Tiempos simulados de cada etapa (minutos desde que se hizo el pedido).
  /// Cuando exista backend, el estado vendrá de Firestore.
  static const _preparingAt = 2;
  static const _onTheWayAt = 15;
  static const deliveryMinutes = 35;

  final String id;
  final String userId;
  final List<CartItem> items;
  final double subtotal;
  final double discount;
  final double deliveryFee;
  final double total;
  final DateTime createdAt;
  final String address;
  final String phone;
  final PaymentMethod paymentMethod;
  final String notes;
  final String? couponCode;

  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);

  DateTime get estimatedDelivery => createdAt.add(const Duration(minutes: deliveryMinutes));

  OrderStatus statusAt(DateTime now) {
    final minutes = now.difference(createdAt).inMinutes;
    return switch (minutes) {
      < _preparingAt => OrderStatus.recibido,
      < _onTheWayAt => OrderStatus.preparando,
      < deliveryMinutes => OrderStatus.enCamino,
      _ => OrderStatus.entregado,
    };
  }

  /// Sigue en curso mientras no se haya entregado.
  bool isActiveAt(DateTime now) => statusAt(now) != OrderStatus.entregado;

  /// Avance del reparto de 0 a 1 (para las barras de progreso).
  double progressAt(DateTime now) => (now.difference(createdAt).inSeconds / (deliveryMinutes * 60)).clamp(0.0, 1.0);

  /// Hora aproximada en que el pedido llega (o llegó) a cada etapa.
  DateTime timeFor(OrderStatus status) => createdAt.add(
    Duration(
      minutes: switch (status) {
        OrderStatus.recibido => 0,
        OrderStatus.preparando => _preparingAt,
        OrderStatus.enCamino => _onTheWayAt,
        OrderStatus.entregado => deliveryMinutes,
      },
    ),
  );

  String get itemsSummary => items.map((i) => '${i.quantity}× ${i.pizza.name}').join(', ');

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'items': items.map((i) => i.toMap()).toList(),
    'subtotal': subtotal,
    'discount': discount,
    'deliveryFee': deliveryFee,
    'total': total,
    'createdAt': createdAt.toIso8601String(),
    'address': address,
    'phone': phone,
    'paymentMethod': paymentMethod.name,
    'notes': notes,
    'couponCode': couponCode,
  };
}
