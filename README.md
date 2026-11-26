# PizzaGo

Aplicación web progresiva (PWA) de pedidos para una pizzería, hecha con
Flutter y Material 3 y publicada en Firebase Hosting.

**En línea:** <https://pizzago-874f4.web.app> · menú generado en el servidor:
<https://pizzago-874f4.web.app/menu/>

## Qué incluye

| Función | Dónde está |
| --- | --- |
| Pantallas de Splash y Home | `lib/features/auth/screens/splash_screen.dart`, `lib/features/menu/screens/home_screen.dart` |
| Vistas del lado del cliente | Toda la aplicación Flutter, que se dibuja en el navegador |
| Vistas del lado del servidor | `firebase-admin-setup/render_menu.js`: genera `/menu/` y una página por producto con datos de Firestore antes de cada publicación |
| Datos locales | Sesión, carrito, favoritos y pedidos en el navegador (`shared_preferences`) |
| Datos remotos | Menú en Cloud Firestore y copia de los pedidos en `usuarios/{uid}/pedidos` (`lib/data/repositories/firestore_repositories.dart`) |
| Datos sin conexión | Service worker propio (`web/sw.js`) y persistencia de Firestore en el navegador; si no hay red ni copia, el menú sale de `assets/data/menu.json` |
| Notificaciones | Avisos del estado del pedido (`lib/features/notifications/`) y promociones push con Firebase Cloud Messaging (`web/firebase-messaging-sw.js`, `firebase-admin-setup/enviar_promo.js`) |
| Elementos físicos del dispositivo | GPS: botón **Usar mi ubicación** en el pago (`lib/data/services/location_service.dart`) |
| Instalación | `web/manifest.json` con íconos, capturas y accesos directos |
| Cuentas | Firebase Authentication con correo y contraseña y recuperación por correo (`lib/data/repositories/firebase_auth_repository.dart`) |
| API de terceros | Nominatim de OpenStreetMap: convierte el punto del GPS en calle y colonia (`lib/data/services/address_lookup_service.dart`) |

## Seguridad

- Las contraseñas las guarda Firebase Authentication (cifradas con scrypt);
  la aplicación nunca las almacena. Al registrarse se piden 8 caracteres
  con letras y números.
- Los mensajes de error no dicen si un correo tiene cuenta, y Firebase
  bloquea por unos minutos tras muchos intentos fallidos.
- `firestore.rules`: el menú es solo de lectura; el perfil, los pedidos y
  los dispositivos de `usuarios/{uid}` solo los lee y escribe el dueño de
  la cuenta, con validación de campos y tamaños.
- Todo viaja por HTTPS (Firebase Hosting). La llave de servicio queda fuera
  del repositorio (`.gitignore`).

## Ejecutar

```bash
flutter pub get
flutter run -d chrome
```

Cuenta de demostración: botón **Usar cuenta de demostración** en el login
(`demo@pizzago.com` / `pizzago123`, registrada en Firebase y en los datos locales).

Cupones de prueba: `PIZZAGO10` (10 %) y `BIENVENIDA` ($50, solo el primer pedido).

## Publicar

```bash
flutter build web --release --no-web-resources-cdn
firebase deploy --only hosting
```

`--no-web-resources-cdn` deja el motor de dibujo en el propio sitio para que
el service worker lo guarde y la aplicación abra sin conexión. Antes de subir,
Firebase corre `npm --prefix firebase-admin-setup run render` y genera las
vistas del servidor. Al cambiar la aplicación, sube el nombre de la caché en
`web/sw.js`.

## Pruebas

```bash
flutter analyze
flutter test
```

## Estructura de `lib/`

Organizada por módulos: cada función de la aplicación tiene su carpeta con su
controlador, sus pantallas y sus widgets.

```
lib/
├── main.dart           arranca Firebase en web (o datos locales si no hay)
├── firebase_options.dart
├── app/            PizzaGoApp y dependencias, router, rutas (AppRoutes), navegación
├── core/           tema, formateadores, validadores, widgets y platform/ (notificaciones del navegador)
├── data/
│   ├── models/         Pizza, CartItem, Coupon, PizzaOrder, DeliveryLocation, Promo, AppUser
│   ├── repositories/   menú, sesión y pedidos: versiones locales, de Firestore y combinadas
│   └── services/       ubicación GPS, dirección con OpenStreetMap y push de Cloud Messaging
└── features/
    ├── auth/           auth_controller · screens/ (splash, login, registro) · widgets/
    ├── menu/           catalog_controller · screens/ (inicio, detalle) · widgets/
    ├── cart/           cart_controller · screens/ (carrito, pago) · widgets/
    ├── orders/         order_controller · screens/ (lista, detalle, confirmación) · widgets/
    ├── notifications/  notification_controller (permiso, avisos del pedido, push)
    └── profile/        screens/ (perfil) · widgets/
```

Reglas que sigue el código:

- Las pantallas solo hablan con controladores (`provider`); los
  controladores hablan con repositorios. Las fuentes de datos se eligen en
  `AppDependencies` (`lib/app/app.dart`).
- Las rutas salen de `AppRoutes` (`lib/app/routes.dart`), nunca se escriben
  a mano.
- Un archivo por pantalla; los widgets que usa una sola función viven en su
  carpeta `widgets/`, y los que se usan en varias, en `core/widgets/`.

## Diseño

- Superficies neutras con un solo color de acento (rojo tomate), tarjetas
  con sombra suave y radios de 12/16/24 px (`lib/core/theme/app_theme.dart`).
- Tipografía Poppins con la escala de Material 3; DM Serif Display solo en
  el logotipo (licencia OFL en `assets/fonts/`).
- Íconos: Material Symbols (*Rounded*); el ícono activo anima su relleno.
- Movimiento (Material motion, paquete `animations`): *fade through* entre
  pestañas, *shared axis* en login/registro y pago, entrada escalonada de
  tarjetas, esqueleto con brillo mientras carga y palomita animada al
  confirmar el pedido.
- Accesibilidad: si el sistema tiene desactivados los efectos de animación,
  Flutter acorta las animaciones.
- Imágenes: fotografías reales de Wikimedia Commons con licencias libres,
  en `assets/images/products/<id>.jpg`. Autores y licencias en
  `assets/images/CREDITOS.md`.

## Herramientas del servidor (`firebase-admin-setup/`)

Requieren `serviceAccountKey.json`, que **no** se comparte ni se sube a
ningún repositorio.

```bash
npm run seed:dry    # valida menu.json sin conectarse
npm run seed        # sube el menú a Firestore (colecciones pizzas y extras)
npm run reglas      # publica firestore.rules
npm run prueba:reglas  # prueba las reglas publicadas con dos cuentas temporales
npm run render      # genera las vistas del servidor en build/web/menu/
npm run promo -- --titulo "2x1 los martes" --texto "Pide dos y paga una."
```
