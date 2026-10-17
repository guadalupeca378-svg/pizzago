import 'package:flutter/foundation.dart';

import '../../data/models/app_user.dart';
import '../../data/models/coupon.dart';
import '../../data/models/pizza_order.dart';
import '../../data/repositories/order_repository.dart';
import '../cart/cart_controller.dart';

class OrderController extends ChangeNotifier {
  OrderController(this._repository);

  final OrderRepository _repository;

  String? _userId;
  List<PizzaOrder> _orders = const [];
  bool _loading = false;
  bool _placing = false;
  String? _error;

  List<PizzaOrder> get orders => _orders;
  bool get isLoading => _loading;
  bool get isPlacing => _placing;
  String? get error => _error;

  double get totalSpent => _orders.fold(0.0, (sum, o) => sum + o.total);

  PizzaOrder? byId(String id) {
    for (final o in _orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  /// Lo llama `ChangeNotifierProxyProvider` cada vez que cambia la sesión.
  /// Se difiere con un microtask porque ocurre durante el build.
  void bindUser(AppUser? user) {
    if (user?.uid == _userId) return;
    _userId = user?.uid;
    Future.microtask(() {
      _orders = const [];
      if (_userId == null) {
        notifyListeners();
      } else {
        load();
      }
    });
  }

  /// Usuario cuyos pedidos se están cargando. Si cambia la sesión a mitad
  /// de una carga, la del nuevo usuario no se salta.
  String? _loadingFor;

  Future<void> load() async {
    final userId = _userId;
    if (userId == null || _loadingFor == userId) return;
    _loadingFor = userId;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _repository.fetchOrders(userId);
      if (userId == _userId) _orders = result;
    } catch (e) {
      _error = 'No pudimos cargar tus pedidos.';
      debugPrint('OrderController.load: $e');
    } finally {
      if (_loadingFor == userId) {
        _loadingFor = null;
        _loading = false;
      }
      notifyListeners();
    }
  }

  /// Los cupones de primer pedido solo valen si aún no hay pedidos.
  bool canUse(Coupon coupon) => !coupon.firstOrderOnly || _orders.isEmpty;

  Future<PizzaOrder?> placeOrder({
    required CartController cart,
    required String address,
    required String phone,
    required PaymentMethod paymentMethod,
    String notes = '',
  }) async {
    final userId = _userId;
    if (userId == null || cart.isEmpty || _placing) return null;
    final coupon = cart.coupon;
    if (coupon != null && !canUse(coupon)) {
      _error = 'El cupón ${coupon.code} es solo para tu primer pedido.';
      notifyListeners();
      return null;
    }

    final order = PizzaOrder(
      id: _newOrderId(),
      userId: userId,
      items: List.of(cart.items),
      subtotal: cart.subtotal,
      discount: cart.discount,
      deliveryFee: cart.delivery,
      total: cart.total,
      createdAt: DateTime.now(),
      address: address.trim(),
      phone: phone.trim(),
      paymentMethod: paymentMethod,
      notes: notes.trim(),
      couponCode: cart.coupon?.code,
    );

    _placing = true;
    _error = null;
    notifyListeners();
    try {
      final saved = await _repository.placeOrder(order);
      _orders = [saved, ..._orders];
      cart.clear();
      return saved;
    } catch (e) {
      _error = 'No se pudo enviar el pedido. Intenta de nuevo.';
      debugPrint('OrderController.placeOrder: $e');
      return null;
    } finally {
      _placing = false;
      notifyListeners();
    }
  }

  static String _newOrderId() {
    final stamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    return 'PG-${stamp.substring(stamp.length - 6).toUpperCase()}';
  }
}
