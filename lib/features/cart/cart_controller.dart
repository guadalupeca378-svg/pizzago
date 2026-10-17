import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/cart_item.dart';
import '../../data/models/coupon.dart';
import '../../data/models/store_info.dart';

class CartController extends ChangeNotifier {
  CartController(this._prefs) {
    _restore();
  }

  static final deliveryFee = StoreInfo.pizzago.deliveryFee;
  static final freeDeliveryFrom = StoreInfo.pizzago.freeDeliveryFrom;

  static const _storageKey = 'cart.state';
  static const availableCoupons = <Coupon>[
    PercentCoupon('PIZZAGO10', '10% de descuento', 10),
    FixedCoupon('BIENVENIDA', r'$50 de descuento en tu primer pedido', 50, firstOrderOnly: true),
  ];

  final SharedPreferences _prefs;
  final List<CartItem> _items = [];
  Coupon? _coupon;

  UnmodifiableListView<CartItem> get items => UnmodifiableListView(_items);
  Coupon? get coupon => _coupon;
  bool get isEmpty => _items.isEmpty;
  int get itemCount => _items.fold(0, (sum, i) => sum + i.quantity);

  double get subtotal => _items.fold(0.0, (sum, i) => sum + i.total);

  double get discount {
    final value = _coupon?.discountFor(subtotal) ?? 0;
    return (value * 100).roundToDouble() / 100;
  }

  double get _afterDiscount => subtotal - discount;

  double get delivery => isEmpty || _afterDiscount >= freeDeliveryFrom ? 0 : deliveryFee;

  double get total => _afterDiscount + delivery;

  double get missingForFreeDelivery => math.max(0, freeDeliveryFrom - _afterDiscount);

  double get freeDeliveryProgress => (_afterDiscount / freeDeliveryFrom).clamp(0.0, 1.0);

  /// Máximo de piezas iguales por renglón (también es el tope del selector).
  static const maxQuantity = 20;

  void add(CartItem item) {
    final index = _items.indexWhere((i) => i.key == item.key);
    if (index == -1) {
      _items.add(item.copyWith(quantity: math.min(item.quantity, maxQuantity)));
    } else {
      final current = _items[index];
      _items[index] = current.copyWith(quantity: math.min(current.quantity + item.quantity, maxQuantity));
    }
    _changed();
  }

  void setQuantity(String key, int quantity) {
    final index = _items.indexWhere((i) => i.key == key);
    if (index == -1) return;
    if (quantity <= 0) {
      _items.removeAt(index);
    } else {
      _items[index] = _items[index].copyWith(quantity: math.min(quantity, maxQuantity));
    }
    _changed();
  }

  /// Quita un renglón y devuelve su posición para poder deshacer.
  ({CartItem item, int index})? remove(String key) {
    final index = _items.indexWhere((i) => i.key == key);
    if (index == -1) return null;
    final item = _items.removeAt(index);
    _changed();
    return (item: item, index: index);
  }

  void undoRemove(CartItem item, int index) {
    _items.insert(index.clamp(0, _items.length), item);
    _changed();
  }

  /// Busca un cupón por su código, sin importar mayúsculas ni espacios.
  static Coupon? couponFor(String code) {
    final normalized = code.trim().toUpperCase();
    return availableCoupons.where((c) => c.code == normalized).firstOrNull;
  }

  /// Devuelve `true` si el código existe.
  bool applyCoupon(String code) {
    final coupon = couponFor(code);
    if (coupon == null) return false;
    _coupon = coupon;
    _changed();
    return true;
  }

  void removeCoupon() {
    _coupon = null;
    _changed();
  }

  void clear() {
    _items.clear();
    _coupon = null;
    _changed();
  }

  void _changed() {
    notifyListeners();
    _prefs.setString(
      _storageKey,
      jsonEncode({'items': _items.map((i) => i.toMap()).toList(), 'coupon': _coupon?.code}),
    );
  }

  void _restore() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _items.addAll((data['items'] as List).map((e) => CartItem.fromMap(Map<String, dynamic>.from(e as Map))));
      final code = data['coupon'] as String?;
      if (code != null) {
        _coupon = couponFor(code);
      }
    } catch (e) {
      // Si cambió el formato guardado, empezamos con un carrito vacío.
      debugPrint('CartController._restore: $e');
      _items.clear();
    }
  }
}
