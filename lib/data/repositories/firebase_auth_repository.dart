import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import 'auth_repository.dart';

/// Cuentas con Firebase Authentication (correo y contraseña).
///
/// La contraseña nunca se guarda en la aplicación: Firebase la recibe por
/// HTTPS y la almacena cifrada. La sesión es un token que Firebase renueva
/// solo. Los datos del perfil (teléfono y dirección) viven en
/// `usuarios/{uid}` y las reglas de Firestore solo dejan leerlos al dueño.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _profile(String uid) => _db.collection('usuarios').doc(uid);

  /// Junta la cuenta de Firebase con el perfil guardado en Firestore.
  Future<AppUser> _load(User user) async {
    final snap = await _profile(user.uid).get();
    final data = snap.data() ?? const {};
    return AppUser(
      uid: user.uid,
      name: data['name'] as String? ?? user.displayName ?? user.email!.split('@').first,
      email: user.email!,
      phone: data['phone'] as String? ?? '',
      address: data['address'] as String? ?? '',
    );
  }

  @override
  Future<AppUser?> restoreSession() async {
    final user = await _auth.authStateChanges().first;
    // Las sesiones anónimas de la versión anterior no cuentan como cuenta.
    if (user == null || user.isAnonymous || user.email == null) return null;
    try {
      return await _load(user);
    } on FirebaseException {
      return null;
    }
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) => _guard(() async {
    final cred = await _auth.signInWithEmailAndPassword(email: email.trim().toLowerCase(), password: password);
    return _load(cred.user!);
  });

  @override
  Future<AppUser> register({required String name, required String email, required String password}) => _guard(() async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email.trim().toLowerCase(), password: password);
    final user = cred.user!;
    await user.updateDisplayName(name.trim());
    final profile = AppUser(uid: user.uid, name: name.trim(), email: user.email!);
    await _profile(user.uid).set({..._fields(profile), 'creado': FieldValue.serverTimestamp()});
    return profile;
  });

  @override
  Future<void> sendPasswordReset(String email) => _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<AppUser> updateProfile(AppUser user) async {
    await _profile(user.uid).set(_fields(user), SetOptions(merge: true));
    return user;
  }

  Map<String, dynamic> _fields(AppUser u) => {'name': u.name, 'email': u.email, 'phone': u.phone, 'address': u.address};

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (e) {
      throw AuthException(authMessage(e.code));
    }
  }

  /// Mensaje para el cliente según el código de error de Firebase. No se dice
  /// si el correo existe o no, para no dar pistas a quien prueba cuentas.
  static String authMessage(String code) => switch (code) {
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' ||
    'invalid-login-credentials' => 'El correo o la contraseña no son correctos.',
    'email-already-in-use' => 'Ya existe una cuenta con ese correo.',
    'invalid-email' => 'El correo no es válido.',
    'weak-password' || 'password-does-not-meet-requirements' => 'La contraseña es muy débil.',
    'too-many-requests' => 'Hubo demasiados intentos. Espera unos minutos y vuelve a probar.',
    'user-disabled' => 'Esta cuenta está desactivada.',
    'network-request-failed' => 'Sin conexión. Revisa tu internet e intenta de nuevo.',
    _ => 'No pudimos completar la operación. Intenta de nuevo.',
  };
}
