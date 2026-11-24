import 'package:flutter_test/flutter_test.dart';
import 'package:pizzago/data/models/pizza_order.dart';

void main() {
  final createdAt = DateTime(2026, 10, 3, 14);
  final order = PizzaOrder(
    id: 'PG-TEST',
    userId: 'demo',
    items: const [],
    subtotal: 0,
    discount: 0,
    deliveryFee: 0,
    total: 0,
    createdAt: createdAt,
    address: 'Av. Universidad 100',
    phone: '5512345678',
    paymentMethod: PaymentMethod.efectivo,
  );

  DateTime after(int minutes) => createdAt.add(Duration(minutes: minutes));

  test('el estado avanza con el tiempo', () {
    expect(order.statusAt(after(0)), OrderStatus.recibido);
    expect(order.statusAt(after(5)), OrderStatus.preparando);
    expect(order.statusAt(after(20)), OrderStatus.enCamino);
    expect(order.statusAt(after(PizzaOrder.deliveryMinutes)), OrderStatus.entregado);
  });

  test('sigue en curso hasta que se entrega', () {
    expect(order.isActiveAt(after(20)), isTrue);
    expect(order.isActiveAt(after(PizzaOrder.deliveryMinutes)), isFalse);
  });

  test('el avance va de 0 a 1 y no se pasa', () {
    expect(order.progressAt(createdAt), 0);
    expect(order.progressAt(after(PizzaOrder.deliveryMinutes ~/ 2)), closeTo(.5, .02));
    expect(order.progressAt(after(PizzaOrder.deliveryMinutes * 2)), 1);
  });

  test('se guarda y se recupera igual', () {
    final copy = PizzaOrder.fromMap(order.toMap());
    expect(copy.id, order.id);
    expect(copy.createdAt, order.createdAt);
    expect(copy.paymentMethod, order.paymentMethod);
  });
}
