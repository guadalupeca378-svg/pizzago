import 'package:firebase_core/firebase_core.dart';

/// Configuración de la aplicación web "PizzaGo Web" en el proyecto
/// pizzago-874f4. Estos valores identifican al proyecto y son públicos:
/// el acceso a los datos lo controlan las reglas de Firestore.
abstract final class DefaultFirebaseOptions {
  static const web = FirebaseOptions(
    apiKey: 'AIzaSyDrpRRXDg5uiV6sUd9RbQWZJMr8f2-9t6E',
    appId: '1:517144629815:web:09112ed7fe68cfc28765b2',
    messagingSenderId: '517144629815',
    projectId: 'pizzago-874f4',
    authDomain: 'pizzago-874f4.firebaseapp.com',
    storageBucket: 'pizzago-874f4.firebasestorage.app',
  );

  /// Llave pública para suscribirse a las notificaciones push (Web Push).
  static const vapidKey = 'BE4rDajMOFtFAhRl9WVvtbCPa9jvZ2nO9qg35eXBt2Oqwt05b9JFfxao_6fn7_wAh3NVW2m8_kH40nEhGwkYE7c';
}
