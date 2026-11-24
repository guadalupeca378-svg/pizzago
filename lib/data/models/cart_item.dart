import 'package:flutter/foundation.dart';

import 'pizza.dart';

@immutable
class CartItem {
  const CartItem({required this.pizza, required this.size, this.extras = const [], this.quantity = 1, this.note = ''});

  factory CartItem.fromMap(Map<String, dynamic> map) => CartItem(
    pizza: Pizza.fromMap(Map<String, dynamic>.from(map['pizza'] as Map)),
    size: PizzaSize.fromName(map['size'] as String),
    extras: (map['extras'] as List? ?? const [])
        .map((e) => Extra.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList(),
    quantity: (map['quantity'] as num).toInt(),
    note: map['note'] as String? ?? '',
  );

  final Pizza pizza;
  final PizzaSize size;
  final List<Extra> extras;
  final int quantity;
  final String note;

  /// Dos renglones del carrito son "el mismo producto" cuando coinciden
  /// pizza, tamaño, extras (sin importar el orden) y nota.
  String get key {
    final extraIds = extras.map((e) => e.id).toList()..sort();
    return [pizza.id, size.name, extraIds.join(','), note.trim().toLowerCase()].join('|');
  }

  double get unitPrice => pizza.priceFor(size) + extras.fold(0.0, (sum, e) => sum + e.price);

  double get total => unitPrice * quantity;

  /// Texto corto para listas: "Grande · Queso extra, Tocino".
  String get details {
    final parts = <String>[
      if (pizza.hasSizes) '${size.label} (${size.diameter})',
      if (extras.isNotEmpty) extras.map((e) => e.name).join(', '),
      if (note.trim().isNotEmpty) '“${note.trim()}”',
    ];
    return parts.join(' · ');
  }

  CartItem copyWith({int? quantity}) =>
      CartItem(pizza: pizza, size: size, extras: extras, quantity: quantity ?? this.quantity, note: note);

  Map<String, dynamic> toMap() => {
    'pizza': pizza.toMap(),
    'size': size.name,
    'extras': extras.map((e) => e.toMap()).toList(),
    'quantity': quantity,
    'note': note,
  };
}
