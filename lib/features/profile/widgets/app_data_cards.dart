import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../../app/app.dart';
import '../../../core/platform/system_notifications.dart';
import '../../../core/widgets/surface_card.dart';
import '../../../data/repositories/order_repository.dart';
import '../../menu/catalog_controller.dart';
import '../../notifications/notification_controller.dart';
import '../../orders/order_controller.dart';

/// Activar los avisos del pedido y las promociones push.
class NotificationsCard extends StatelessWidget {
  const NotificationsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final n = context.watch<NotificationController>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final (String title, String subtitle) = switch (n.permission) {
      NotificationPermission.unsupported => ('No disponibles', 'Este navegador no permite notificaciones.'),
      NotificationPermission.denied => ('Bloqueadas', 'Permítelas desde el candado de la barra de direcciones.'),
      NotificationPermission.notAsked => ('Desactivadas', 'Te avisamos cuando tu pedido cambie de estado y de nuevas promociones.'),
      NotificationPermission.granted =>
        n.pushReady
            ? ('Activadas', 'Avisos del pedido y promociones push.')
            : ('Activadas', 'Avisos del estado de tus pedidos.'),
    };

    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              n.isEnabled ? Symbols.notifications_active_rounded : Symbols.notifications_off_rounded,
              color: n.isEnabled ? scheme.primary : null,
            ),
            title: Text(title),
            subtitle: Text(subtitle),
            trailing: n.permission == NotificationPermission.notAsked
                ? FilledButton.tonal(
                    onPressed: n.isBusy ? null : n.enable,
                    child: n.isBusy
                        ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Activar'),
                  )
                : null,
          ),
          if (n.error case final error?)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(error, style: theme.textTheme.bodySmall?.copyWith(color: scheme.error)),
            ),
        ],
      ),
    );
  }
}

/// De dónde viene cada dato: local, remoto u offline, y la vista del servidor.
class AppDataCard extends StatelessWidget {
  const AppDataCard({super.key});

  @override
  Widget build(BuildContext context) {
    final source = context.select<CatalogController, String?>((c) => c.source?.label);
    final localOrders = context.select<OrderController, int>((o) => o.orders.length);
    final sync = context.read<AppDependencies>().syncStatus;

    return SurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Symbols.cloud_rounded),
            title: Text(source ?? 'Cargando…'),
            subtitle: const Text('Origen del menú'),
          ),
          const Divider(indent: 56),
          ListTile(
            leading: const Icon(Symbols.phone_android_rounded),
            title: Text('$localOrders guardados en este dispositivo'),
            subtitle: const Text('Pedidos locales (funcionan sin conexión)'),
          ),
          if (sync != null) ...[
            const Divider(indent: 56),
            ValueListenableBuilder<SyncStatus>(
              valueListenable: sync,
              builder: (context, s, _) => ListTile(
                leading: const Icon(Symbols.cloud_sync_rounded),
                title: Text(switch (s) {
                  SyncStatus(:final error?) => error,
                  SyncStatus(:final remoteCount?) => '$remoteCount copiados en Firestore',
                  _ => 'Sincronizando…',
                }),
                subtitle: Text(
                  s.lastSync == null
                      ? 'Copia remota de tus pedidos'
                      : 'Última sincronización: ${DateFormat.Hm().format(s.lastSync!)}',
                ),
              ),
            ),
          ],
          const Divider(indent: 56),
          ListTile(
            leading: const Icon(Symbols.dns_rounded),
            title: const Text('Menú generado en el servidor'),
            subtitle: const Text('Versión en HTML que se crea al publicar'),
            trailing: const Icon(Symbols.open_in_new_rounded),
            onTap: () => openExternal('/menu/'),
          ),
        ],
      ),
    );
  }
}
