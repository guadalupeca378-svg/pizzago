import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../core/widgets/product_image.dart';
import '../data/models/pizza.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/menu_repository.dart';
import '../data/repositories/order_repository.dart';
import '../features/auth/auth_controller.dart';
import '../features/cart/cart_controller.dart';
import '../features/menu/catalog_controller.dart';
import '../features/orders/order_controller.dart';
import 'router.dart';

/// Todo lo que la aplicación necesita del exterior. Para conectar Firebase
/// solo se crea otra fábrica (p. ej. `AppDependencies.firebase()`) con
/// repositorios que usen Firestore y Firebase Auth.
class AppDependencies {
  const AppDependencies({
    required this.prefs,
    required this.menuRepository,
    required this.authRepository,
    required this.orderRepository,
    this.splashDuration = const Duration(milliseconds: 1200),
  });

  factory AppDependencies.local(SharedPreferences prefs) => AppDependencies(
    prefs: prefs,
    menuRepository: LocalMenuRepository(),
    authRepository: LocalAuthRepository(prefs),
    orderRepository: LocalOrderRepository(prefs),
  );

  final SharedPreferences prefs;
  final MenuRepository menuRepository;
  final AuthRepository authRepository;
  final OrderRepository orderRepository;
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
