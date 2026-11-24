import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/pizza.dart';

/// De dónde salió el menú que se está mostrando.
enum MenuSource {
  remoto('Firestore (en línea)'),
  cache('Copia sin conexión de Firestore'),
  local('Archivo incluido en la aplicación');

  const MenuSource(this.label);
  final String label;
}

class MenuData {
  const MenuData({required this.items, required this.extras, this.source = MenuSource.local});

  final List<Pizza> items;
  final List<Extra> extras;
  final MenuSource source;
}

/// Fuente del menú: el archivo `assets/data/menu.json` o las colecciones
/// `pizzas` y `extras` de Firestore (las que llena `seed_menu.js`).
abstract interface class MenuRepository {
  Future<MenuData> fetchMenu();
}

/// Intenta la fuente remota y, si falla o tarda demasiado, usa la local.
/// Así el menú siempre aparece, con o sin Firebase.
class FallbackMenuRepository implements MenuRepository {
  FallbackMenuRepository(this.remote, this.local, {this.timeout = const Duration(seconds: 8)});

  final MenuRepository remote;
  final MenuRepository local;
  final Duration timeout;

  @override
  Future<MenuData> fetchMenu() async {
    try {
      final data = await remote.fetchMenu().timeout(timeout);
      if (data.items.isNotEmpty) return data;
    } catch (e) {
      // Sin conexión y sin copia guardada: se usa el menú incluido.
    }
    return local.fetchMenu();
  }
}

class LocalMenuRepository implements MenuRepository {
  LocalMenuRepository({AssetBundle? bundle, this.latency = const Duration(milliseconds: 600)})
    : _bundle = bundle ?? rootBundle;

  static const assetPath = 'assets/data/menu.json';

  final AssetBundle _bundle;

  /// Retraso artificial para que la interfaz muestre los estados de carga
  /// igual que lo hará con una base de datos remota.
  final Duration latency;

  @override
  Future<MenuData> fetchMenu() async {
    final (raw, _) = await (_bundle.loadString(assetPath), Future<void>.delayed(latency)).wait;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    List<Map<String, dynamic>> list(String key) => (json[key] as List).cast<Map<String, dynamic>>();

    return MenuData(
      items: list('pizzas').map(Pizza.fromMap).toList(growable: false),
      extras: list('extras').map(Extra.fromMap).toList(growable: false),
    );
  }
}
