import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pizzago/data/models/app_user.dart';
import 'package:pizzago/data/models/cart_item.dart';
import 'package:pizzago/data/models/pizza.dart';
import 'package:pizzago/data/models/pizza_order.dart';
import 'package:pizzago/data/repositories/order_repository.dart';
import 'package:pizzago/features/cart/cart_controller.dart';
import 'package:pizzago/features/orders/order_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _refresco = Pizza(
  id: 'refresco',
  name: 'Refresco',
  description: '',
  basePrice: 35,
  category: PizzaCategory.bebidas,
);

AppUser _user(String uid) => AppUser(uid: uid, name: 'Prueba', email: '$uid@test.com');

/// Repositorio en memoria; con [gate] se puede pausar la carga para simular
/// una red lenta.
class _FakeOrders implements OrderRepository {
  final saved = <String, List<PizzaOrder>>{};
  Completer<void>? gate;

  @override
  Future<List<PizzaOrder>> fetchOrders(String userId) async {
    await gate?.future;
    return saved[userId] ?? [];
  }

  @override
  Future<PizzaOrder> placeOrder(PizzaOrder order) async {
    (saved[order.userId] ??= []).add(order);
    return order;
  }
}

void main() {
  late _FakeOrders repo;
  late OrderController orders;
  late CartController cart;

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  Future<PizzaOrder?> order() => orders.placeOrder(
    cart: cart,
    address: 'Av. Universidad 100',
    phone: '5512345678',
    paymentMethod: PaymentMethod.efectivo,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    cart = CartController(await SharedPreferences.getInstance());
    repo = _FakeOrders();
    orders = OrderController(repo);
  });

  test('el cupón BIENVENIDA solo vale en el primer pedido', () async {
    orders.bindUser(_user('ana'));
    await settle();
    final bienvenida = CartController.couponFor('bienvenida')!;
    expect(orders.canUse(bienvenida), isTrue);

    cart.add(const CartItem(pizza: _refresco, size: PizzaSize.chica));
    cart.applyCoupon('BIENVENIDA');
    expect(await order(), isNotNull);

    // Segundo pedido: ya no se puede usar.
    expect(orders.canUse(bienvenida), isFalse);
    cart.add(const CartItem(pizza: _refresco, size: PizzaSize.chica));
    cart.applyCoupon('BIENVENIDA');
    expect(await order(), isNull);
    expect(orders.error, contains('primer pedido'));
    // Los demás cupones siguen funcionando.
    expect(orders.canUse(CartController.couponFor('PIZZAGO10')!), isTrue);
  });

  test('si cambia la cuenta a mitad de una carga, se cargan los pedidos de la nueva', () async {
    repo.saved['beto'] = [
      PizzaOrder(
        id: 'PG-BETO',
        userId: 'beto',
        items: const [],
        subtotal: 0,
        discount: 0,
        deliveryFee: 0,
        total: 0,
        createdAt: DateTime(2026),
        address: 'x',
        phone: 'x',
        paymentMethod: PaymentMethod.efectivo,
      ),
    ];
    repo.gate = Completer<void>();
    orders.bindUser(_user('ana'));
    await settle(); // la carga de Ana queda pendiente
    orders.bindUser(_user('beto'));
    await settle();
    repo.gate!.complete();
    await settle();
    await settle();

    expect(orders.orders.single.id, 'PG-BETO');
  });
}
