import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pizza_order.dart';

/// Pedidos del usuario.
abstract interface class OrderRepository {
  Future<List<PizzaOrder>> fetchOrders(String userId);
  Future<PizzaOrder> placeOrder(PizzaOrder order);
}

/// Copia de los pedidos en un servidor (Firestore).
abstract interface class RemoteOrderStore {
  Future<void> save(PizzaOrder order);
  Future<List<PizzaOrder>> fetch(String userId);
}

/// Estado de la copia remota, para mostrarlo en el perfil.
@immutable
class SyncStatus {
  const SyncStatus({this.remoteCount, this.lastSync, this.error});

  /// Pedidos que hay en el servidor (null si todavía no se consulta).
  final int? remoteCount;
  final DateTime? lastSync;
  final String? error;
}

/// Guarda primero en el dispositivo (funciona sin conexión) y manda una copia
/// al servidor en segundo plano. Al cargar, junta los pedidos de los dos lados.
class SyncedOrderRepository implements OrderRepository {
  SyncedOrderRepository(this.local, this.remote, {this.timeout = const Duration(seconds: 6)});

  final OrderRepository local;
  final RemoteOrderStore remote;
  final Duration timeout;

  final status = ValueNotifier(const SyncStatus());

  @override
  Future<List<PizzaOrder>> fetchOrders(String userId) async {
    final mine = await local.fetchOrders(userId);
    try {
      final remoteOrders = await remote.fetch(userId).timeout(timeout);
      status.value = SyncStatus(remoteCount: remoteOrders.length, lastSync: DateTime.now());
      final known = {for (final o in mine) o.id};
      final merged = [...mine, ...remoteOrders.where((o) => !known.contains(o.id))]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return merged;
    } catch (e) {
      status.value = SyncStatus(remoteCount: status.value.remoteCount, error: 'Sin conexión con Firestore');
      return mine;
    }
  }

  @override
  Future<PizzaOrder> placeOrder(PizzaOrder order) async {
    final saved = await local.placeOrder(order);
    // Sin conexión, Firestore deja la escritura en cola y la envía al volver la red.
    unawaited(
      remote
          .save(saved)
          .then((_) {
            final count = (status.value.remoteCount ?? 0) + 1;
            status.value = SyncStatus(remoteCount: count, lastSync: DateTime.now());
          })
          .catchError((Object e) {
            status.value = SyncStatus(remoteCount: status.value.remoteCount, error: 'Pendiente de enviar a Firestore');
          }),
    );
    return saved;
  }
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
