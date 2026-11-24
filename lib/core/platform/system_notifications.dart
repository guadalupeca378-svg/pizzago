import 'system_notifications_stub.dart' if (dart.library.js_interop) 'system_notifications_web.dart' as impl;

enum NotificationPermission { granted, denied, notAsked, unsupported }

/// Notificaciones del sistema operativo (las que salen fuera del navegador).
abstract class SystemNotifications {
  const SystemNotifications();

  /// La del navegador en web; una versión vacía en las pruebas.
  factory SystemNotifications.platform() => impl.createNotifications();

  NotificationPermission get permission;
  Future<NotificationPermission> requestPermission();

  /// [tag] reemplaza la notificación anterior con la misma etiqueta y
  /// [url] es la pantalla que se abre al tocarla.
  Future<void> show({required String title, required String body, String? tag, String? url});
}

/// Sin notificaciones (pruebas y plataformas que no las tienen).
class NoNotifications extends SystemNotifications {
  const NoNotifications();

  @override
  NotificationPermission get permission => NotificationPermission.unsupported;

  @override
  Future<NotificationPermission> requestPermission() async => NotificationPermission.unsupported;

  @override
  Future<void> show({required String title, required String body, String? tag, String? url}) async {}
}

/// Abre un enlace en otra pestaña (web).
void openExternal(String url) => impl.openExternal(url);
