# PizzaGo

Aplicación de pedidos para pizzería hecha con Flutter y Material 3.
Por ahora funciona con datos locales; la capa de repositorios está lista para
cambiarse a Firebase (Firestore y Auth).

## Ejecutar

```bash
flutter pub get
flutter run -d chrome
```

Cuenta de demostración: botón **Usar cuenta de demostración** en el login
(`demo@pizzago.com` / `pizzago123`, solo existe en local).

Cupones de prueba: `PIZZAGO10` (10 %) y `BIENVENIDA` ($50).

## Pruebas

```bash
flutter analyze
flutter test
```

## Estructura de `lib/`

Organizada por módulos: cada función de la app tiene su carpeta con su
controlador, sus pantallas y sus widgets.

```
lib/
├── main.dart
├── app/            PizzaGoApp y dependencias, router, rutas (AppRoutes), navegación
├── core/           tema y modo oscuro, formateadores, validadores, widgets compartidos
├── data/
│   ├── models/         Pizza, CartItem, Coupon, PizzaOrder, Promo, AppUser
│   └── repositories/   contratos + versiones locales (menú, sesión, pedidos)
└── features/
    ├── auth/       auth_controller · screens/ (splash, login, registro) · widgets/
    ├── menu/       catalog_controller · screens/ (inicio, detalle) · widgets/
    ├── cart/       cart_controller · screens/ (carrito, pago) · widgets/
    ├── orders/     order_controller · screens/ (lista, detalle, confirmación) · widgets/
    └── profile/    screens/ (perfil) · widgets/
```

Reglas que sigue el código:

- Las pantallas solo hablan con controladores (`provider`); los
  controladores hablan con repositorios. Para usar Firebase basta con otros
  repositorios en `AppDependencies` (`lib/app/app.dart`).
- Las rutas salen de `AppRoutes` (`lib/app/routes.dart`), nunca se escriben
  a mano.
- Un archivo por pantalla; los widgets que usa una sola función viven en su
  carpeta `widgets/`, y los que se usan en varias, en `core/widgets/`.

El menú vive en `assets/data/menu.json`.

## Diseño

- Superficies neutras con un solo color de acento (rojo tomate), tarjetas
  con sombra suave y radios de 12/16/24 px (`lib/core/theme/app_theme.dart`).
- Tipografía Poppins con la escala de Material 3; DM Serif Display solo en
  el logotipo (Google Fonts, licencia OFL en `assets/fonts/`).
- Componentes estándar de Material 3: NavigationBar/NavigationRail, chips de
  filtro, SegmentedButton, listas agrupadas y casillas de verificación.
- Íconos: Material Symbols (*Rounded*), fuente variable; el ícono activo
  anima su eje de relleno (`fill`).
- Movimiento (Material motion, paquete `animations`): *fade through* entre
  pestañas, *shared axis* en login/registro y pago, entrada escalonada de
  tarjetas, esqueleto con brillo mientras carga, barra de categorías fija,
  barra flotante del carrito, montos que cuentan y confeti al confirmar.
- Accesibilidad: si el sistema tiene desactivados los efectos de animación
  (`prefers-reduced-motion`), Flutter acorta las animaciones al 5 %.
- Imágenes: fotografías reales de Wikimedia Commons con licencias libres
  (CC BY, CC BY-SA y CC0), recortadas a 1200×900 en
  `assets/images/products/<id>.jpg`. Autores y licencias en
  `assets/images/CREDITOS.md`; si agregas un producto, agrega su foto con
  el mismo `id` y su crédito.
- Logotipo: monograma "P" dibujado con código (`AppLogo`), sin imagen.

## Firebase Admin SDK

En `firebase-admin-setup/` (requiere `serviceAccountKey.json`, que **no** se
comparte ni se sube a ningún repositorio):

```bash
npm run seed:dry    # valida menu.json sin conectarse
npm run seed        # sube el menú a Firestore (colecciones pizzas y extras)
```
