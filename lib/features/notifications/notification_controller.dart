import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../app/routes.dart';
import '../../core/platform/system_notifications.dart';
import '../../data/models/pizza_order.dart';
import '../../data/services/push_service.dart';
import '../orders/order_controller.dart';

/// Un pedido que cambió de estado desde la última revisión.
typedef StatusChange = ({PizzaOrder order, OrderStatus status});

/// Compara el estado de cada pedido con el que tenía antes. Un pedido nuevo
/// (hecho hace menos de un minuto) cuenta como cambio a "Recibido"; los viejos
/// que aparecen por primera vez solo se registran, para no avisar de golpe.
List<StatusChange> statusChanges(Map<String, OrderStatus> known, List<PizzaOrder> orders, DateTime now) => [
  for (final order in orders)
    if (_changed(known[order.id], order, now)) (order: order, status: order.statusAt(now)),
];

bool _changed(OrderStatus? before, PizzaOrder order, DateTime now) =>
    before == null ? now.difference(order.createdAt) < const Duration(minutes: 1) : before != order.statusAt(now);

/// Permiso de notificaciones, avisos del estado de los pedidos y push.
class NotificationController extends ChangeNotifier {
  NotificationController(this._system, {this.push, this.interval = const Duration(seconds: 15), DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    _permission = _system.permission;
    if (_permission == NotificationPermission.granted) unawaited(_registerPush());
  }

  final SystemNotifications _system;
  final PushService? push;
  final Duration interval;
  final DateTime Function() _clock;

  late NotificationPermission _permission;
  String? _pushToken;
  bool _busy = false;
  String? _error;
  StreamSubscription<(String, String)>? _foreground;

  NotificationPermission get permission => _permission;
  bool get isSupported => _permission != NotificationPermission.unsupported;
  bool get isEnabled => _permission == NotificationPermission.granted;
  bool get pushReady => _pushToken != null;
  bool get isBusy => _busy;
  String? get error => _error;

  /// Pide permiso (tiene que venir de un toque del usuario) y activa el push.
  Future<void> enable() async {
    if (_busy) return;
    _busy = true;
    _error = null;
    notifyListeners();
    _permission = await _system.requestPermission();
    if (isEnabled) {
      await _registerPush();
      await _system.show(
        title: 'Notificaciones activadas',
        body: 'Te avisaremos cuando tu pedido cambie de estado y cuando haya promociones.',
        tag: 'bienvenida',
        url: _link(AppRoutes.orders),
      );
    } else if (_permission == NotificationPermission.denied) {
      _error = 'El navegador bloqueó las notificaciones. Puedes permitirlas desde el candado de la barra de direcciones.';
    }
    _busy = false;
    notifyListeners();
  }

  Future<void> _registerPush() async {
    final service = push;
    if (service == null) return;
    try {
      _pushToken = await service.register();
      _foreground ??= service.foregroundMessages.listen(
        (msg) => _system.show(title: msg.$1, body: msg.$2, tag: 'promo', url: _link(AppRoutes.home)),
      );
    } catch (e) {
      _error = 'Los avisos del pedido funcionan, pero no se pudo activar el push de promociones.';
      debugPrint('NotificationController push: $e');
    }
    notifyListeners();
  }

  // ---- Avisos del estado de los pedidos ----

  OrderController? _orders;
  Timer? _timer;
  final Map<String, OrderStatus> _known = {};

  /// Lo llama el proveedor cada vez que cambian los pedidos.
  void watch(OrderController orders) {
    _orders = orders;
    if (!isSupported) return;
    _timer ??= Timer.periodic(interval, (_) => check());
    check();
  }

  /// Revisa los pedidos y avisa de los que cambiaron de estado.
  void check() {
    final orders = _orders?.orders ?? const <PizzaOrder>[];
    final now = _clock();
    final changes = statusChanges(_known, orders, now);
    for (final order in orders) {
      _known[order.id] = order.statusAt(now);
    }
    if (!isEnabled) return;
    for (final (:order, :status) in changes) {
      unawaited(
        _system.show(
          title: 'Pedido #${order.id}: ${status.label}',
          body: status.message,
          tag: order.id,
          url: _link(AppRoutes.order(order.id)),
        ),
      );
    }
  }

  /// La aplicación usa rutas con # en web.
  static String _link(String route) => '/#$route';

  @override
  void dispose() {
    _timer?.cancel();
    _foreground?.cancel();
    super.dispose();
  }
}
