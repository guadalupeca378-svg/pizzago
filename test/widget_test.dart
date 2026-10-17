import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pizzago/app/app.dart';
import 'package:pizzago/core/widgets/motion.dart';
import 'package:pizzago/data/models/pizza.dart';
import 'package:pizzago/data/repositories/auth_repository.dart';
import 'package:pizzago/data/repositories/menu_repository.dart';
import 'package:pizzago/data/repositories/order_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeMenuRepository implements MenuRepository {
  @override
  Future<MenuData> fetchMenu() async => const MenuData(
    items: [
      Pizza(
        id: 'pepperoni',
        name: 'Pepperoni',
        description: 'Clásica',
        basePrice: 159,
        category: PizzaCategory.clasicas,
        isPopular: true,
      ),
      Pizza(
        id: 'horchata',
        name: 'Agua de horchata',
        description: 'Bebida',
        basePrice: 30,
        category: PizzaCategory.bebidas,
      ),
    ],
    extras: [Extra(id: 'queso', name: 'Queso extra', price: 25)],
  );
}

Future<AppDependencies> _deps() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return AppDependencies(
    prefs: prefs,
    menuRepository: _FakeMenuRepository(),
    authRepository: LocalAuthRepository(prefs, latency: Duration.zero),
    orderRepository: LocalOrderRepository(prefs, latency: Duration.zero),
    splashDuration: Duration.zero,
  );
}

/// Escribe en la búsqueda del menú y espera el debounce de 300 ms.
Future<void> _search(WidgetTester tester, String text) async {
  await tester.enterText(find.descendant(of: find.byType(SearchBar), matching: find.byType(TextField)), text);
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('es_MX'));

  testWidgets('sin sesión muestra el login', (tester) async {
    await tester.pumpWidget(PizzaGoApp(dependencies: await _deps()));
    await tester.pumpAndSettle();

    expect(find.text('Hola de nuevo'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  testWidgets('valida el formulario de login', (tester) async {
    await tester.pumpWidget(PizzaGoApp(dependencies: await _deps()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Iniciar sesión'));
    await tester.pump();

    expect(find.text('El correo es obligatorio'), findsOneWidget);
    expect(find.text('La contraseña es obligatoria'), findsOneWidget);
  });

  testWidgets('con la cuenta demo entra al menú y agrega al carrito', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(PizzaGoApp(dependencies: await _deps()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Usar cuenta de demostración'));
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    // El inicio muestra la ficha de la pizzería.
    expect(find.text('Pizzería artesanal · Horno de piedra'), findsOneWidget);

    // Busca un producto (con debounce de 300 ms).
    await _search(tester, 'horchata');
    expect(find.text('Agua de horchata'), findsOneWidget);
    expect(find.text('Pepperoni'), findsNothing);

    await tester.tap(find.byTooltip('Agregar al carrito').first);
    await tester.pumpAndSettle();

    // La barra flotante del carrito aparece con el total.
    expect(find.text('Ver mi pedido'), findsOneWidget);
    // El badge del carrito en la barra de navegación.
    expect(find.descendant(of: find.byType(Badge), matching: find.text('1')), findsOneWidget);
  });

  testWidgets('las categorías llevan a su sección y se marcan', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(PizzaGoApp(dependencies: await _deps()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usar cuenta de demostración'));
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    final bebidas = find.widgetWithText(ChoiceChip, 'Bebidas');
    expect(tester.widget<ChoiceChip>(bebidas).selected, isFalse);

    await tester.tap(bebidas);
    await tester.pumpAndSettle();

    // La sección quedó a la vista y su chip activo; el menú no se filtró.
    expect(tester.widget<ChoiceChip>(bebidas).selected, isTrue);
    expect(find.text('Agua de horchata').hitTestable(), findsOneWidget);
    expect(find.text('Clásicas', skipOffstage: false), findsWidgets);
  });

  testWidgets('flujo completo: menú, carrito, pago y seguimiento', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(PizzaGoApp(dependencies: await _deps()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usar cuenta de demostración'));
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    await _search(tester, 'horchata');
    await tester.tap(find.byTooltip('Agregar al carrito').first);
    await tester.pumpAndSettle();

    // Barra flotante -> carrito (transición fade through entre pestañas).
    await tester.tap(find.text('Ver mi pedido'));
    await tester.pumpAndSettle();
    expect(find.text('Tu pedido'), findsOneWidget);

    await tester.tap(find.textContaining('Continuar'));
    await tester.pumpAndSettle();
    // La cuenta demo ya trae dirección y teléfono.
    await tester.tap(find.textContaining('Pedir ahora'));
    await tester.pumpAndSettle();
    // Ya sin confeti: la confirmación es la palomita, ya dibujada.
    final check = tester.renderObject(
      find.descendant(of: find.byType(AnimatedCheck), matching: find.byType(CustomPaint)),
    );
    expect(
      check,
      paints
        ..circle()
        ..path(),
    );
    expect(find.text('¡Ya está en el horno!'), findsOneWidget);

    await tester.tap(find.text('Seguir mi pedido'));
    await tester.pumpAndSettle();
    expect(find.textContaining('#PG-'), findsWidgets);
    expect(find.text('Recibido'), findsWidgets);
  });

  testWidgets('el detalle muestra el contenido y la barra de agregar', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(PizzaGoApp(dependencies: await _deps()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usar cuenta de demostración'));
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle();

    await _search(tester, 'horchata');
    await tester.tap(find.text('Agua de horchata'));
    await tester.pumpAndSettle();

    // Si la barra inferior ocupara toda la pantalla, el contenido no se vería.
    expect(find.text('Instrucciones especiales').hitTestable(), findsOneWidget);
    final bar = tester.getRect(find.widgetWithText(FilledButton, r'Agregar · $30'));
    expect(bar.height, lessThan(80));
    expect(bar.bottom, greaterThan(tester.view.physicalSize.height / 2.75 - 100));
  });
}
