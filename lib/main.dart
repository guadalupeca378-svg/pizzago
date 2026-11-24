import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'es_MX';
  await initializeDateFormatting('es_MX');
  final prefs = await SharedPreferences.getInstance();

  runApp(PizzaGoApp(dependencies: await _dependencies(prefs)));
}

/// En web se conecta a Firebase; si no se puede (o en otras plataformas,
/// que todavía no tienen su configuración), la aplicación usa datos locales.
Future<AppDependencies> _dependencies(SharedPreferences prefs) async {
  if (!kIsWeb) return AppDependencies.local(prefs);
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
    // Copia del menú y de los pedidos en el navegador para trabajar sin conexión.
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
    return AppDependencies.firebase(prefs);
  } catch (e) {
    debugPrint('Firebase no disponible, se usan datos locales: $e');
    return AppDependencies.local(prefs);
  }
}
