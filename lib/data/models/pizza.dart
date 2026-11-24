import 'package:flutter/foundation.dart';

/// Categorías del menú. El `name` del enum es el valor que se guarda en
/// JSON / Firestore, por eso no debe cambiarse sin migrar los datos.
enum PizzaCategory {
  clasicas('Clásicas'),
  especiales('Especiales'),
  vegetarianas('Veggie'),
  bebidas('Bebidas'),
  postres('Postres');

  const PizzaCategory(this.label);

  final String label;

  bool get isPizza => this == clasicas || this == especiales || this == vegetarianas;

  static PizzaCategory fromName(String name) => values.firstWhere((c) => c.name == name, orElse: () => clasicas);
}

enum PizzaSize {
  chica('Chica', '25 cm', 1.0),
  mediana('Mediana', '30 cm', 1.3),
  grande('Grande', '35 cm', 1.6);

  const PizzaSize(this.label, this.diameter, this.multiplier);

  final String label;
  final String diameter;
  final double multiplier;

  static PizzaSize fromName(String name) => values.firstWhere((s) => s.name == name, orElse: () => mediana);
}

@immutable
class Extra {
  const Extra({required this.id, required this.name, required this.price, this.topping = 'cheese'});

  factory Extra.fromMap(Map<String, dynamic> map) => Extra(
    id: map['id'] as String,
    name: map['name'] as String,
    price: (map['price'] as num).toDouble(),
    topping: map['topping'] as String? ?? 'cheese',
  );

  final String id;
  final String name;
  final double price;

  /// Foto del ingrediente: `assets/images/toppings/<topping>.jpg`.
  final String topping;

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'price': price, 'topping': topping};

  @override
  bool operator ==(Object other) => other is Extra && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

@immutable
class Pizza {
  const Pizza({
    required this.id,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.category,
    this.rating = 0,
    this.prepMinutes = 15,
    this.ingredients = const [],
    this.isPopular = false,
    this.isSpicy = false,
    this.isVeggie = false,
  });

  factory Pizza.fromMap(Map<String, dynamic> map) => Pizza(
    id: map['id'] as String,
    name: map['name'] as String,
    description: map['description'] as String? ?? '',
    basePrice: (map['basePrice'] as num).toDouble(),
    category: PizzaCategory.fromName(map['category'] as String),
    rating: (map['rating'] as num?)?.toDouble() ?? 0,
    prepMinutes: (map['prepMinutes'] as num?)?.toInt() ?? 15,
    ingredients: List<String>.from(map['ingredients'] as List? ?? const []),
    isPopular: map['isPopular'] as bool? ?? false,
    isSpicy: map['isSpicy'] as bool? ?? false,
    isVeggie: map['isVeggie'] as bool? ?? false,
  );

  final String id;
  final String name;
  final String description;
  final double basePrice;
  final PizzaCategory category;

  final double rating;
  final int prepMinutes;
  final List<String> ingredients;
  final bool isPopular;
  final bool isSpicy;
  final bool isVeggie;

  /// Solo las pizzas tienen tamaños y aceptan ingredientes extra;
  /// bebidas y postres tienen precio único.
  bool get hasSizes => category.isPizza;
  bool get acceptsExtras => category.isPizza;

  /// La etiqueta "vegetariana" solo informa algo útil en las pizzas.
  bool get showsVeggieBadge => isVeggie && category.isPizza;

  double priceFor(PizzaSize size) => hasSizes ? (basePrice * size.multiplier).ceilToDouble() : basePrice;

  /// Precio más bajo con el que aparece en el menú (la chica en pizzas).
  double get startingPrice => priceFor(PizzaSize.chica);

  /// Tamaño con el que se agrega desde el botón rápido del menú.
  PizzaSize get defaultSize => hasSizes ? PizzaSize.mediana : PizzaSize.chica;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'basePrice': basePrice,
    'category': category.name,
    'rating': rating,
    'prepMinutes': prepMinutes,
    'ingredients': ingredients,
    'isPopular': isPopular,
    'isSpicy': isSpicy,
    'isVeggie': isVeggie,
  };

  @override
  bool operator ==(Object other) => other is Pizza && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
