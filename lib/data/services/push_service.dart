import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Notificaciones push que manda el servidor (promociones).
abstract interface class PushService {
  /// Registra el navegador y guarda su identificador para que el servidor le escriba.
  Future<String?> register();

  /// Mensajes que llegan con la aplicación abierta (título y texto).
  Stream<(String, String)> get foregroundMessages;
}

/// Firebase Cloud Messaging. El identificador se guarda en
/// `usuarios/{uid}/dispositivos/{fid}`, de donde lo lee `enviar_promo.js`.
class FcmPushService implements PushService {
  FcmPushService(this._messaging, this._db, this._auth, this._vapidKey) {
    // Se escucha desde el arranque: si se empezara a escuchar al registrar,
    // el aviso de registro a veces llega antes y se pierde.
    _messaging.onRegistered.listen((fid) {
      if (!_fid.isCompleted) _fid.complete(fid);
    });
  }

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final String _vapidKey;
  final _fid = Completer<String>();

  /// Registra el navegador en Cloud Messaging y guarda su identificador de
  /// instalación (FID), que es el destino al que el servidor manda el push.
  /// Se guarda el token anterior como respaldo para el servidor.
  @override
  Future<String?> register() async {
    await _messaging.register(vapidKey: _vapidKey);
    final token = await _tokenOrNull();
    final fid = await _fid.future.timeout(
      const Duration(seconds: 30),
      // El token tiene la forma "<FID>:<resto>".
      onTimeout: () => token?.split(':').first ?? (throw TimeoutException('Sin identificador de Cloud Messaging')),
    );
    final user = _auth.currentUser ?? (await _auth.signInAnonymously()).user!;
    await _db.collection('usuarios').doc(user.uid).collection('dispositivos').doc(fid).set({
      'fid': fid,
      'token': ?token,
      'plataforma': 'web',
      'actualizado': FieldValue.serverTimestamp(),
    });
    return fid;
  }

  Future<String?> _tokenOrNull() async {
    try {
      // ignore: deprecated_member_use
      return await _messaging.getToken(vapidKey: _vapidKey);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<(String, String)> get foregroundMessages => FirebaseMessaging.onMessage.map(
    (m) => (m.notification?.title ?? 'PizzaGo', m.notification?.body ?? ''),
  );
}
