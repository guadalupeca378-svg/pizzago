import 'package:flutter_test/flutter_test.dart';
import 'package:pizzago/data/models/pizza.dart';
import 'package:pizzago/data/repositories/menu_repository.dart';
import 'package:pizzago/features/menu/catalog_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeMenu implements MenuRepository {
  @override
  Future<MenuData> fetchMenu() async => const MenuData(
    items: [
      Pizza(
        id: 'champinones',
        name: 'Champiñones al ajo',
        description: 'Con ajo confitado',
        basePrice: 165,
        category: PizzaCategory.vegetarianas,
        ingredients: ['Champiñón', 'Ajo'],
      ),
      Pizza(id: 'pepperoni', name: 'Pepperoni', description: '', basePrice: 159, category: PizzaCategory.clasicas),
      Pizza(id: 'horchata', name: 'Agua de horchata', description: '', basePrice: 30, category: PizzaCategory.bebidas),
    ],
    extras: [],
  );
}

void main() {
  late CatalogController catalog;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    catalog = CatalogController(_FakeMenu(), await SharedPreferences.getInstance());
    await catalog.load();
  });

  test('las secciones siguen el orden de las categorías y omiten las vacías', () {
    expect(catalog.categories, [PizzaCategory.clasicas, PizzaCategory.vegetarianas, PizzaCategory.bebidas]);
    expect(catalog.inCategory(PizzaCategory.bebidas).single.id, 'horchata');
  });

  test('la búsqueda ignora acentos y mayúsculas y revisa ingredientes', () {
    catalog.search('CHAMPINON');
    expect(catalog.isSearching, isTrue);
    expect(catalog.searchResults.single.id, 'champinones');

    catalog.search('ajo');
    expect(catalog.searchResults.single.id, 'champinones');

    catalog.search('');
    expect(catalog.isSearching, isFalse);
    expect(catalog.searchResults, hasLength(3));
  });

  test('los favoritos se guardan por cuenta', () async {
    catalog.bindUser('ana');
    catalog.toggleFavorite('pepperoni');
    expect(catalog.favoriteItems.single.id, 'pepperoni');

    // Otra cuenta en el mismo dispositivo no ve los favoritos de Ana.
    catalog.bindUser('beto');
    expect(catalog.favoriteItems, isEmpty);

    // Al volver a entrar como Ana (o reabrir la app) siguen ahí.
    final reopened = CatalogController(_FakeMenu(), await SharedPreferences.getInstance());
    await reopened.load();
    reopened.bindUser('ana');
    expect(reopened.isFavorite('pepperoni'), isTrue);
  });

  test('sin sesión no se guardan favoritos', () {
    catalog.toggleFavorite('pepperoni');
    expect(catalog.favoriteItems, isEmpty);
  });
}
