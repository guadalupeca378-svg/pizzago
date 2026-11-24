/// Rutas de la aplicación en un solo lugar: las pantallas navegan con
/// `context.go(AppRoutes.cart)` en vez de escribir la cadena a mano.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';

  static const home = '/';
  static const cart = '/cart';
  static const checkout = '/cart/checkout';
  static const orders = '/orders';
  static const profile = '/profile';

  static String pizza(String id) => '/pizza/$id';
  static String order(String id) => '/orders/$id';
  static String orderSuccess(String id) => '/order-success/$id';
}
