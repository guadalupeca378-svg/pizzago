import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Contrato de autenticación. La versión local sirve para desarrollar y
/// probar sin backend; `FirebaseAuthRepository` lo implementará después con
/// `firebase_auth` sin tocar pantallas ni controladores.
abstract interface class AuthRepository {
  Future<AppUser?> restoreSession();
  Future<AppUser> signIn({required String email, required String password});
  Future<AppUser> register({required String name, required String email, required String password});
  Future<void> signOut();
  Future<AppUser> updateProfile(AppUser user);
}

/// Cuentas guardadas en el navegador / dispositivo con SharedPreferences.
///
/// SOLO PARA DESARROLLO: la contraseña se guarda tal cual en el almacenamiento
/// local. En producción la autenticación la hace Firebase Auth.
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this._prefs, {this.latency = const Duration(milliseconds: 500)});

  static const demoEmail = 'demo@pizzago.com';
  static const demoPassword = 'pizzago123';

  static const _usersKey = 'auth.users';
  static const _sessionKey = 'auth.session';

  final SharedPreferences _prefs;
  final Duration latency;

  Map<String, dynamic> _readUsers() {
    final users = Map<String, dynamic>.from(jsonDecode(_prefs.getString(_usersKey) ?? '{}') as Map);
    users.putIfAbsent(
      demoEmail,
      () => {
        'password': demoPassword,
        'user': const AppUser(
          uid: 'demo',
          name: 'Equipo PizzaGo',
          email: demoEmail,
          phone: '5512345678',
          address: 'Av. Universidad 100, Col. Centro',
        ).toMap(),
      },
    );
    return users;
  }

  Future<void> _writeUsers(Map<String, dynamic> users) => _prefs.setString(_usersKey, jsonEncode(users));

  AppUser _userFrom(Object? record) => AppUser.fromMap(Map<String, dynamic>.from((record! as Map)['user'] as Map));

  @override
  Future<AppUser?> restoreSession() async {
    final email = _prefs.getString(_sessionKey);
    if (email == null) return null;
    final record = _readUsers()[email];
    return record == null ? null : _userFrom(record);
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    await Future<void>.delayed(latency);
    final key = email.trim().toLowerCase();
    final record = _readUsers()[key] as Map?;
    if (record == null) {
      throw const AuthException('No existe una cuenta con ese correo.');
    }
    if (record['password'] != password) {
      throw const AuthException('La contraseña es incorrecta.');
    }
    await _prefs.setString(_sessionKey, key);
    return _userFrom(record);
  }

  @override
  Future<AppUser> register({required String name, required String email, required String password}) async {
    await Future<void>.delayed(latency);
    final key = email.trim().toLowerCase();
    final users = _readUsers();
    if (users.containsKey(key)) {
      throw const AuthException('Ya existe una cuenta con ese correo.');
    }
    final user = AppUser(uid: 'local-${DateTime.now().microsecondsSinceEpoch}', name: name.trim(), email: key);
    users[key] = {'password': password, 'user': user.toMap()};
    await _writeUsers(users);
    await _prefs.setString(_sessionKey, key);
    return user;
  }

  @override
  Future<void> signOut() => _prefs.remove(_sessionKey);

  @override
  Future<AppUser> updateProfile(AppUser user) async {
    final users = _readUsers();
    final record = Map<String, dynamic>.from(users[user.email] as Map);
    record['user'] = user.toMap();
    users[user.email] = record;
    await _writeUsers(users);
    return user;
  }
}
