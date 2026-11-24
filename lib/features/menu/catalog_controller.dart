import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/pizza.dart';
import '../../data/repositories/menu_repository.dart';

/// Menú, búsqueda y favoritos del usuario.
class CatalogController extends ChangeNotifier {
  CatalogController(this._repository, this._prefs);

  final MenuRepository _repository;
  final SharedPreferences _prefs;

  /// Los favoritos son de cada cuenta: se guardan con el uid del usuario.
  String? _userId;
  Set<String> _favorites = {};

  String get _favoritesKey => 'menu.favorites.$_userId';

  /// Lo llama `ChangeNotifierProxyProvider` cada vez que cambia la sesión.
  void bindUser(String? userId) {
    if (userId == _userId) return;
    _userId = userId;
    _favorites = userId == null ? {} : (_prefs.getStringList(_favoritesKey) ?? const []).toSet();
    // Ocurre durante el build del proveedor; se avisa al terminar.
    Future.microtask(notifyListeners);
  }

  List<Pizza> _items = const [];
  List<Extra> _extras = const [];
  bool _loading = false;
  bool _loaded = false;
  String? _error;
  String _query = '';
  MenuSource? _source;

  /// De dónde salió el menú (Firestore, su copia sin conexión o el archivo local).
  MenuSource? get source => _source;

  List<Pizza> get items => _items;
  List<Extra> get extras => _extras;
  bool get isLoading => _loading;
  bool get hasLoaded => _loaded;
  String? get error => _error;
  String get query => _query;

  bool get isSearching => _query.trim().isNotEmpty;

  /// Productos que coinciden con la búsqueda (todos si no hay búsqueda).
  List<Pizza> get searchResults {
    final q = _normalize(_query);
    if (q.isEmpty) return _items;
    return _items
        .where((p) => _normalize('${p.name} ${p.description} ${p.ingredients.join(' ')}').contains(q))
        .toList(growable: false);
  }

  /// Productos de una categoría, en el orden del menú.
  List<Pizza> inCategory(PizzaCategory category) => _items.where((p) => p.category == category).toList(growable: false);

  /// Categorías que tienen al menos un producto (las secciones del inicio).
  List<PizzaCategory> get categories => [
    for (final c in PizzaCategory.values)
      if (_items.any((p) => p.category == c)) c,
  ];

  /// Promedio de calificación del menú (null mientras no haya productos).
  double? get averageRating {
    final rated = _items.where((p) => p.rating > 0);
    if (rated.isEmpty) return null;
    return rated.fold(0.0, (sum, p) => sum + p.rating) / rated.length;
  }

  List<Pizza> get popular => _items.where((p) => p.isPopular).toList(growable: false);

  List<Pizza> get favoriteItems => _items.where((p) => _favorites.contains(p.id)).toList(growable: false);

  Pizza? byId(String id) {
    for (final p in _items) {
      if (p.id == id) return p;
    }
    return null;
  }

  Future<void> load({bool force = false}) async {
    if (_loading || (_loaded && !force)) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final menu = await _repository.fetchMenu();
      _items = menu.items;
      _extras = menu.extras;
      _source = menu.source;
      _loaded = true;
    } catch (e) {
      _error = 'No pudimos cargar el menú. Revisa tu conexión.';
      debugPrint('CatalogController.load: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void search(String query) {
    if (_query == query) return;
    _query = query;
    notifyListeners();
  }

  bool isFavorite(String id) => _favorites.contains(id);

  void toggleFavorite(String id) {
    if (_userId == null) return;
    if (!_favorites.remove(id)) _favorites.add(id);
    _prefs.setStringList(_favoritesKey, _favorites.toList());
    notifyListeners();
  }

  /// Minúsculas y sin acentos para que "champinon" encuentre "Champiñón".
  static String _normalize(String s) {
    const from = 'áéíóúüñ';
    const to = 'aeiouun';
    final buffer = StringBuffer();
    for (final ch in s.toLowerCase().trim().split('')) {
      final i = from.indexOf(ch);
      buffer.write(i == -1 ? ch : to[i]);
    }
    return buffer.toString();
  }
}
