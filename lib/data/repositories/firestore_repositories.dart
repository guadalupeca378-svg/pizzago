import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/pizza.dart';
import '../models/pizza_order.dart';
import 'menu_repository.dart';
import 'order_repository.dart';

/// Lee el menú de las colecciones `pizzas` y `extras` de Firestore.
/// Con la persistencia activada, sin conexión responde con la última copia.
class FirestoreMenuRepository implements MenuRepository {
  FirestoreMenuRepository(this._db);

  final FirebaseFirestore _db;

  @override
  Future<MenuData> fetchMenu() async {
    final (pizzas, extras) = await (
      _db.collection('pizzas').orderBy('order').get(),
      _db.collection('extras').orderBy('order').get(),
    ).wait;
    Map<String, dynamic> withId(QueryDocumentSnapshot<Map<String, dynamic>> d) => {...d.data(), 'id': d.id};

    return MenuData(
      items: pizzas.docs.map((d) => Pizza.fromMap(withId(d))).toList(growable: false),
      extras: extras.docs.map((d) => Extra.fromMap(withId(d))).toList(growable: false),
      source: pizzas.metadata.isFromCache ? MenuSource.cache : MenuSource.remoto,
    );
  }
}

/// Copia de los pedidos en `usuarios/{uid}/pedidos/{id}`. El uid es el de la
/// cuenta de Firebase Authentication: las reglas solo dejan a cada cliente
/// leer y escribir sus propios pedidos.
class FirestoreOrderStore implements RemoteOrderStore {
  FirestoreOrderStore(this._db, this._auth);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  Future<String> _uid() async => (_auth.currentUser ?? (throw StateError('Sin sesión iniciada'))).uid;

  Future<CollectionReference<Map<String, dynamic>>> _orders() async =>
      _db.collection('usuarios').doc(await _uid()).collection('pedidos');

  @override
  Future<void> save(PizzaOrder order) async {
    final ref = (await _orders()).doc(order.id);
    await ref.set({...order.toMap(), 'syncedAt': FieldValue.serverTimestamp()});
  }

  @override
  Future<List<PizzaOrder>> fetch(String userId) async {
    final snap = await (await _orders()).where('userId', isEqualTo: userId).get();
    return snap.docs.map((d) => PizzaOrder.fromMap(d.data())).toList(growable: false);
  }
}
