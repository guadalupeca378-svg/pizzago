import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/pizza_order.dart';

/// Pedidos del usuario. En Firebase corresponderá a la colección `orders`
/// filtrada por `userId`.
abstract interface class OrderRepository {
  Future<List<PizzaOrder>> fetchOrders(String userId);
  Future<PizzaOrder> placeOrder(PizzaOrder order);
}

class LocalOrderRepository implements OrderRepository {
  LocalOrderRepository(this._prefs, {this.latency = const Duration(milliseconds: 700)});

  final SharedPreferences _prefs;
  final Duration latency;

  String _key(String userId) => 'orders.$userId';

  List<PizzaOrder> _read(String userId) {
    final raw = _prefs.getString(_key(userId));
    if (raw == null) return [];
    return (jsonDecode(raw) as List).map((e) => PizzaOrder.fromMap(Map<String, dynamic>.from(e as Map))).toList();
  }

  @override
  Future<List<PizzaOrder>> fetchOrders(String userId) async {
    await Future<void>.delayed(latency ~/ 2);
    return _read(userId)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<PizzaOrder> placeOrder(PizzaOrder order) async {
    await Future<void>.delayed(latency);
    final orders = _read(order.userId)..add(order);
    await _prefs.setString(_key(order.userId), jsonEncode(orders.map((o) => o.toMap()).toList()));
    return order;
  }
}
