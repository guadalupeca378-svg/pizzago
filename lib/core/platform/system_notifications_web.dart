import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'system_notifications.dart';

SystemNotifications createNotifications() => _WebNotifications();

void openExternal(String url) => web.window.open(url, '_blank');

/// Usa la API Notification del navegador y muestra los avisos a través del
/// service worker, así aparecen aunque la pestaña esté en segundo plano y
/// al tocarlos se abre la pantalla del pedido.
class _WebNotifications extends SystemNotifications {
  bool get _supported => (web.window as JSObject).has('Notification');

  @override
  NotificationPermission get permission {
    if (!_supported) return NotificationPermission.unsupported;
    return switch (web.Notification.permission) {
      'granted' => NotificationPermission.granted,
      'denied' => NotificationPermission.denied,
      _ => NotificationPermission.notAsked,
    };
  }

  @override
  Future<NotificationPermission> requestPermission() async {
    if (!_supported) return NotificationPermission.unsupported;
    await web.Notification.requestPermission().toDart;
    return permission;
  }

  @override
  Future<void> show({required String title, required String body, String? tag, String? url}) async {
    if (permission != NotificationPermission.granted) return;
    final options = tag == null
        ? web.NotificationOptions(body: body, icon: 'icons/Icon-192.png', badge: 'icons/Icon-192.png', lang: 'es-MX', data: {'url': url ?? '/'}.jsify())
        : web.NotificationOptions(
            body: body,
            icon: 'icons/Icon-192.png',
            badge: 'icons/Icon-192.png',
            lang: 'es-MX',
            tag: tag,
            data: {'url': url ?? '/'}.jsify(),
          );
    final registration = await web.window.navigator.serviceWorker.ready.toDart;
    await registration.showNotification(title, options).toDart;
  }
}
