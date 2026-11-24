import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/platform/system_notifications.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../core/widgets/product_image.dart';
import '../data/models/pizza.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/firestore_repositories.dart';
import '../data/repositories/menu_repository.dart';
import '../data/repositories/order_repository.dart';
import '../data/services/location_service.dart';
import '../data/services/push_service.dart';
import '../features/auth/auth_controller.dart';
import '../features/cart/cart_controller.dart';
import '../features/menu/catalog_controller.dart';
import '../features/notifications/notification_controller.dart';
import '../features/orders/order_controller.dart';
import '../firebase_options.dart';
import 'router.dart';

/// Todo lo que la aplicación necesita del exterior: datos locales en
/// [AppDependencies.local] y, en web, Firestore, push y GPS en
/// [AppDependencies.firebase].
class AppDependencies {
  const AppDependencies({
    required this.prefs,
    required this.menuRepository,
    required this.authRepository,
    required this.orderRepository,
    this.notifications = const NoNotifications(),
    this.push,
    this.location = const DeviceLocationService(),
    this.syncStatus,
    this.splashDuration = const Duration(milliseconds: 1200),
  });

  factory AppDependencies.local(SharedPreferences prefs) => AppDependencies(
    prefs: prefs,
    menuRepository: LocalMenuRepository(),
    authRepository: LocalAuthRepository(prefs),
    orderRepository: LocalOrderRepository(prefs),
  );

  /// Menú desde Firestore (con copia sin conexión y respaldo local), pedidos
  /// guardados en el dispositivo y copiados a Firestore, y notificaciones.
  factory AppDependencies.firebase(SharedPreferences prefs) {
    final db = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    final orders = SyncedOrderRepository(LocalOrderRepository(prefs), FirestoreOrderStore(db, auth));
    return AppDependencies(
      prefs: prefs,
      menuRepository: FallbackMenuRepository(
        FirestoreMenuRepository(db),
        LocalMenuRepository(latency: Duration.zero),
      ),
      authRepository: LocalAuthRepository(prefs),
      orderRepository: orders,
      syncStatus: orders.status,
      notifications: SystemNotifications.platform(),
      push: FcmPushService(FirebaseMessaging.instance, db, auth, DefaultFirebaseOptions.vapidKey),
    );
  }

  final SharedPreferences prefs;
  final MenuRepository menuRepository;
  final AuthRepository authRepository;
  final OrderRepository orderRepository;
  final SystemNotifications notifications;
  final PushService? push;
  final LocationService location;

  /// Estado de la copia de pedidos en Firestore (null sin Firebase).
  final ValueListenable<SyncStatus>? syncStatus;
  final Duration splashDuration;
}

class PizzaGoApp extends StatefulWidget {
  const PizzaGoApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<PizzaGoApp> createState() => _PizzaGoAppState();
}

class _PizzaGoAppState extends State<PizzaGoApp> {
  late final AuthController _auth = AuthController(widget.dependencies.authRepository)
    ..restore(minDuration: widget.dependencies.splashDuration);

  late final GoRouter _router = createRouter(_auth);

  @override
  void dispose() {
    _router.dispose();
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deps = widget.dependencies;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _auth),
        ChangeNotifierProvider(create: (_) => ThemeController(deps.prefs)),
        ChangeNotifierProxyProvider<AuthController, CatalogController>(
          create: (_) => CatalogController(deps.menuRepository, deps.prefs)..load(),
          update: (_, auth, catalog) => catalog!..bindUser(auth.user?.uid),
        ),
        ChangeNotifierProvider(create: (_) => CartController(deps.prefs)),
        ChangeNotifierProxyProvider<AuthController, OrderController>(
          create: (_) => OrderController(deps.orderRepository),
          update: (_, auth, orders) => orders!..bindUser(auth.user),
        ),
        ChangeNotifierProxyProvider<OrderController, NotificationController>(
          create: (_) => NotificationController(deps.notifications, push: deps.push),
          update: (_, orders, notifications) => notifications!..watch(orders),
        ),
        Provider<LocationService>.value(value: deps.location),
        Provider<AppDependencies>.value(value: deps),
      ],
      child: Builder(
        builder: (context) => MaterialApp.router(
          title: 'PizzaGo',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: context.select<ThemeController, ThemeMode>((t) => t.mode),
          locale: const Locale('es', 'MX'),
          supportedLocales: const [Locale('es', 'MX'), Locale('es')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          routerConfig: _router,
          // La lista de productos solo cambia al recargar el menú, así que
          // el precargador se reconstruye muy pocas veces.
          builder: (context, child) {
            final items = context.select<CatalogController, List<Pizza>>((c) => c.items);
            return ImagePrecacher(productIds: [for (final p in items) p.id], child: child!);
          },
        ),
      ),
    );
  }
}
