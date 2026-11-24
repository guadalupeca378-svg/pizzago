import 'package:flutter_test/flutter_test.dart';
import 'package:pizzago/core/platform/system_notifications.dart';
import 'package:pizzago/data/models/cart_item.dart';
import 'package:pizzago/data/models/delivery_location.dart';
import 'package:pizzago/data/models/pizza.dart';
import 'package:pizzago/data/models/pizza_order.dart';
import 'package:pizzago/data/repositories/menu_repository.dart';
import 'package:pizzago/data/repositories/order_repository.dart';
import 'package:pizzago/features/notifications/notification_controller.dart';

const _margarita = Pizza(
  id: 'margarita',
  name: 'Margarita',
  description: '',
  basePrice: 159,
  category: PizzaCategory.clasicas,
);

PizzaOrder _order(String id, DateTime createdAt, {DeliveryLocation? location}) => PizzaOrder(
  id: id,
  userId: 'demo',
  items: const [CartItem(pizza: _margarita, size: PizzaSize.chica)],
  subtotal: 159,
  discount: 0,
  deliveryFee: 39,
  total: 198,
  createdAt: createdAt,
  address: 'Calle 1',
  phone: '5512345678',
  paymentMethod: PaymentMethod.efectivo,
  location: location,
);

class _Menu implements MenuRepository {
  _Menu(this.source, {this.fail = false});
  final MenuSource source;
  final bool fail;

  @override
  Future<MenuData> fetchMenu() async {
    if (fail) throw StateError('sin red');
    return MenuData(items: const [_margarita], extras: const [], source: source);
  }
}

class _Local implements OrderRepository {
  final list = <PizzaOrder>[];

  @override
  Future<List<PizzaOrder>> fetchOrders(String userId) async => List.of(list);

  @override
  Future<PizzaOrder> placeOrder(PizzaOrder order) async => (list..add(order)).last;
}

class _Remote implements RemoteOrderStore {
  _Remote({this.fail = false});
  final bool fail;
  final saved = <PizzaOrder>[];

  @override
  Future<void> save(PizzaOrder order) async {
    if (fail) throw StateError('sin red');
    saved.add(order);
  }

  @override
  Future<List<PizzaOrder>> fetch(String userId) async {
    if (fail) throw StateError('sin red');
    return List.of(saved);
  }
}

class _FakeNotifications extends SystemNotifications {
  _FakeNotifications(this.permission);

  @override
  NotificationPermission permission;
  final shown = <String>[];

  @override
  Future<NotificationPermission> requestPermission() async => permission = NotificationPermission.granted;

  @override
  Future<void> show({required String title, required String body, String? tag, String? url}) async =>
      shown.add('$title|$url');
}

void main() {
  group('datos remotos y locales', () {
    test('el menú viene de Firestore cuando hay conexión', () async {
      final menu = await FallbackMenuRepository(_Menu(MenuSource.remoto), _Menu(MenuSource.local)).fetchMenu();
      expect(menu.source, MenuSource.remoto);
    });

    test('sin Firestore el menú sale del archivo incluido', () async {
      final menu = await FallbackMenuRepository(_Menu(MenuSource.remoto, fail: true), _Menu(MenuSource.local)).fetchMenu();
      expect(menu.source, MenuSource.local);
      expect(menu.items, isNotEmpty);
    });

    test('un pedido se guarda en el dispositivo aunque el servidor falle', () async {
      final local = _Local();
      final repo = SyncedOrderRepository(local, _Remote(fail: true));
      await repo.placeOrder(_order('PG-1', DateTime(2026, 11, 23, 20)));
      await Future<void>.delayed(Duration.zero);
      expect(local.list.map((o) => o.id), ['PG-1']);
      expect(repo.status.value.error, isNotNull);
    });

    test('al cargar se juntan los pedidos locales y los del servidor sin repetir', () async {
      final local = _Local();
      final remote = _Remote();
      final repo = SyncedOrderRepository(local, remote);
      await repo.placeOrder(_order('PG-1', DateTime(2026, 11, 23, 20)));
      await Future<void>.delayed(Duration.zero);
      remote.saved.add(_order('PG-2', DateTime(2026, 11, 23, 21)));

      final all = await repo.fetchOrders('demo');
      expect(all.map((o) => o.id), ['PG-2', 'PG-1']);
      expect(repo.status.value.remoteCount, 2);
    });
  });

  group('ubicación GPS', () {
    const punto = DeliveryLocation(latitude: 19.432608, longitude: -99.133209, accuracy: 18.4);

    test('se muestra con cinco decimales y el margen de error', () {
      expect(punto.label, '19.43261, -99.13321 (±18 m)');
      expect(punto.mapUrl.queryParameters['query'], '19.432608,-99.133209');
    });

    test('viaja con el pedido al guardarlo y leerlo', () {
      final copia = PizzaOrder.fromMap(_order('PG-3', DateTime(2026), location: punto).toMap());
      expect(copia.location, punto);
      expect(PizzaOrder.fromMap(_order('PG-4', DateTime(2026)).toMap()).location, isNull);
    });
  });

  group('notificaciones del pedido', () {
    final hecho = DateTime(2026, 11, 23, 20);

    test('un pedido recién hecho avisa que se recibió', () {
      final cambios = statusChanges({}, [_order('PG-1', hecho)], hecho.add(const Duration(seconds: 5)));
      expect(cambios.single.status, OrderStatus.recibido);
    });

    test('un pedido viejo que aparece por primera vez no avisa', () {
      expect(statusChanges({}, [_order('PG-1', hecho)], hecho.add(const Duration(hours: 2))), isEmpty);
    });

    test('avisa cuando el pedido pasa a preparación y no repite si no cambia', () {
      final pedido = _order('PG-1', hecho);
      final a3min = hecho.add(const Duration(minutes: 3));
      expect(statusChanges({'PG-1': OrderStatus.recibido}, [pedido], a3min).single.status, OrderStatus.preparando);
      expect(statusChanges({'PG-1': OrderStatus.preparando}, [pedido], a3min), isEmpty);
    });

    test('al activarlas pide permiso y manda un aviso de prueba', () async {
      final sistema = _FakeNotifications(NotificationPermission.notAsked);
      final controller = NotificationController(sistema);
      await controller.enable();
      expect(controller.isEnabled, isTrue);
      expect(sistema.shown.single, startsWith('Notificaciones activadas|'));
      controller.dispose();
    });
  });
}
