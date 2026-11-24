import 'package:flutter_test/flutter_test.dart';
import 'package:pizzago/data/models/cart_item.dart';
import 'package:pizzago/data/models/pizza.dart';
import 'package:pizzago/features/cart/cart_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _pepperoni = Pizza(
  id: 'pepperoni',
  name: 'Pepperoni',
  description: '',
  basePrice: 159,
  category: PizzaCategory.clasicas,
);
const _refresco = Pizza(
  id: 'refresco',
  name: 'Refresco',
  description: '',
  basePrice: 35,
  category: PizzaCategory.bebidas,
);
const _queso = Extra(id: 'queso', name: 'Queso extra', price: 25);
const _tocino = Extra(id: 'tocino', name: 'Tocino', price: 30);

void main() {
  late SharedPreferences prefs;
  late CartController cart;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    cart = CartController(prefs);
  });

  test('el precio depende del tamaño y los extras', () {
    const item = CartItem(pizza: _pepperoni, size: PizzaSize.grande, extras: [_queso], quantity: 2);
    // 159 × 1.6 = 254.4 → 255, más 25 de queso = 280 por pizza.
    expect(item.unitPrice, 280);
    expect(item.total, 560);
  });

  test('las bebidas no cambian de precio con el tamaño', () {
    expect(_refresco.priceFor(PizzaSize.grande), 35);
  });

  test('junta productos iguales aunque los extras vengan en otro orden', () {
    cart
      ..add(const CartItem(pizza: _pepperoni, size: PizzaSize.mediana, extras: [_queso, _tocino]))
      ..add(const CartItem(pizza: _pepperoni, size: PizzaSize.mediana, extras: [_tocino, _queso]));

    expect(cart.items, hasLength(1));
    expect(cart.itemCount, 2);
  });

  test('separa renglones por tamaño', () {
    cart
      ..add(const CartItem(pizza: _pepperoni, size: PizzaSize.chica))
      ..add(const CartItem(pizza: _pepperoni, size: PizzaSize.grande));

    expect(cart.items, hasLength(2));
  });

  test('cobra envío debajo del mínimo y lo regala arriba', () {
    cart.add(const CartItem(pizza: _pepperoni, size: PizzaSize.chica));
    expect(cart.delivery, CartController.deliveryFee);
    expect(cart.total, 159 + CartController.deliveryFee);

    cart.add(const CartItem(pizza: _pepperoni, size: PizzaSize.chica, quantity: 2));
    expect(cart.subtotal, 477);
    expect(cart.delivery, 0);
  });

  test('aplica cupones válidos y rechaza los inválidos', () {
    cart.add(const CartItem(pizza: _pepperoni, size: PizzaSize.chica, quantity: 2));

    expect(cart.applyCoupon('nope'), isFalse);
    expect(cart.discount, 0);

    expect(cart.applyCoupon(' pizzago10 '), isTrue);
    expect(cart.discount, closeTo(31.8, 0.001));

    expect(cart.applyCoupon('BIENVENIDA'), isTrue);
    expect(cart.discount, 50);
  });

  test('no pasa del máximo de piezas por renglón', () {
    cart.add(const CartItem(pizza: _refresco, size: PizzaSize.chica, quantity: 15));
    cart.add(const CartItem(pizza: _refresco, size: PizzaSize.chica, quantity: 15));
    expect(cart.items.single.quantity, CartController.maxQuantity);

    cart.setQuantity(cart.items.single.key, 99);
    expect(cart.items.single.quantity, CartController.maxQuantity);
  });

  test('quitar y deshacer regresa el producto a su lugar', () {
    cart
      ..add(const CartItem(pizza: _pepperoni, size: PizzaSize.chica))
      ..add(const CartItem(pizza: _refresco, size: PizzaSize.chica));

    final removed = cart.remove(cart.items.first.key)!;
    expect(cart.items.single.pizza.id, 'refresco');

    cart.undoRemove(removed.item, removed.index);
    expect(cart.items.first.pizza.id, 'pepperoni');
  });

  test('el carrito sobrevive a reiniciar la aplicación', () {
    cart
      ..add(const CartItem(pizza: _pepperoni, size: PizzaSize.grande, extras: [_queso]))
      ..applyCoupon('PIZZAGO10');

    final restored = CartController(prefs);
    expect(restored.items.single.extras.single.id, 'queso');
    expect(restored.coupon?.code, 'PIZZAGO10');
    expect(restored.total, cart.total);
  });
}
