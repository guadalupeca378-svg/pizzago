import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/motion.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/cart/screens/cart_screen.dart';
import '../features/cart/screens/checkout_screen.dart';
import '../features/menu/screens/home_screen.dart';
import '../features/menu/screens/pizza_detail_screen.dart';
import '../features/orders/screens/order_detail_screen.dart';
import '../features/orders/screens/order_success_screen.dart';
import '../features/orders/screens/orders_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import 'main_shell.dart';
import 'routes.dart';

/// Rutas de la aplicación. El router escucha a [AuthController] y redirige
/// según la sesión: sin sesión → /login, con sesión → menú.
GoRouter createRouter(AuthController auth) {
  final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: AppRoutes.home,
    refreshListenable: auth,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final onAuthPage = location == AppRoutes.login || location == AppRoutes.register;
      final onSplash = location == AppRoutes.splash;

      switch (auth.status) {
        case AuthStatus.unknown:
          // Recordamos a dónde quería ir (útil al recargar la página en web).
          return onSplash
              ? null
              : Uri(path: AppRoutes.splash, queryParameters: {'from': state.uri.toString()}).toString();
        case AuthStatus.signedOut:
          return onAuthPage ? null : AppRoutes.login;
        case AuthStatus.signedIn:
          if (onSplash) return state.uri.queryParameters['from'] ?? AppRoutes.home;
          return onAuthPage ? AppRoutes.home : null;
      }
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: AppRoutes.login, pageBuilder: (_, state) => _sharedAxis(state, const LoginScreen())),
      GoRoute(path: AppRoutes.register, pageBuilder: (_, state) => _sharedAxis(state, const RegisterScreen())),
      // Pestañas con estado propio y transición "fade through" de Material 3.
      StatefulShellRoute(
        builder: (_, _, shell) => MainShell(navigationShell: shell),
        navigatorContainerBuilder: (_, shell, children) =>
            FadeThroughBranches(currentIndex: shell.currentIndex, children: children),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, _) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'pizza/:id',
                    parentNavigatorKey: rootKey,
                    pageBuilder: (_, state) => _fadeUp(state, PizzaDetailScreen(pizzaId: state.pathParameters['id']!)),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.cart,
                builder: (_, _) => const CartScreen(),
                routes: [
                  GoRoute(
                    path: 'checkout',
                    parentNavigatorKey: rootKey,
                    pageBuilder: (_, state) => _sharedAxis(state, const CheckoutScreen()),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.orders,
                builder: (_, _) => const OrdersScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    parentNavigatorKey: rootKey,
                    pageBuilder: (_, state) => _sharedAxis(
                      state,
                      OrderDetailScreen(orderId: state.pathParameters['id']!),
                      type: SharedAxisTransitionType.vertical,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: AppRoutes.profile, builder: (_, _) => const ProfileScreen())],
          ),
        ],
      ),
      GoRoute(
        path: '/order-success/:id',
        pageBuilder: (_, state) => CustomTransitionPage(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 450),
          child: OrderSuccessScreen(orderId: state.pathParameters['id']!),
          transitionsBuilder: (_, animation, _, child) => FadeScaleTransition(animation: animation, child: child),
        ),
      ),
    ],
  );
}

/// Eje compartido (Material motion): la pantalla nueva entra deslizándose
/// mientras la anterior sale en la misma dirección.
CustomTransitionPage<void> _sharedAxis(
  GoRouterState state,
  Widget child, {
  SharedAxisTransitionType type = SharedAxisTransitionType.horizontal,
}) => CustomTransitionPage(
  key: state.pageKey,
  transitionDuration: const Duration(milliseconds: 380),
  reverseTransitionDuration: const Duration(milliseconds: 320),
  child: child,
  transitionsBuilder: (_, animation, secondaryAnimation, child) => SharedAxisTransition(
    animation: animation,
    secondaryAnimation: secondaryAnimation,
    transitionType: type,
    fillColor: Colors.transparent,
    child: child,
  ),
);

/// Fundido con un leve ascenso; deja lucir la animación Hero del plato.
CustomTransitionPage<void> _fadeUp(GoRouterState state, Widget child) => CustomTransitionPage(
  key: state.pageKey,
  transitionDuration: const Duration(milliseconds: 420),
  reverseTransitionDuration: const Duration(milliseconds: 300),
  child: child,
  transitionsBuilder: (_, animation, _, child) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, .04), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  },
);
