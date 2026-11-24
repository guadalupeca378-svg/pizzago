// Service worker de PizzaGo.
// Guarda la aplicación en el navegador para que abra sin conexión
// y cargue más rápido en las visitas siguientes.

// Cambiar este nombre en cada versión para que se descarte la caché anterior.
const CACHE = 'pizzago-v1.1.0';

// Lo mínimo para que la aplicación arranque sin internet.
const ESENCIALES = [
  './',
  'index.html',
  'flutter_bootstrap.js',
  'main.dart.js',
  'manifest.json',
  'favicon.png',
  'icons/Icon-192.png',
  'icons/Icon-512.png',
  'icons/Icon-maskable-192.png',
  'icons/Icon-maskable-512.png',
  'assets/AssetManifest.bin.json',
  'assets/FontManifest.json',
  'assets/fonts/MaterialIcons-Regular.otf',
  'assets/assets/data/menu.json',
  'assets/assets/fonts/Poppins-Regular.ttf',
  'assets/assets/fonts/Poppins-Medium.ttf',
  'assets/assets/fonts/Poppins-SemiBold.ttf',
  'assets/assets/fonts/Poppins-Bold.ttf',
  'assets/assets/fonts/Poppins-ExtraBold.ttf',
  'assets/assets/fonts/DMSerifDisplay-Regular.ttf',
  'assets/assets/fonts/DMSerifDisplay-Italic.ttf',
  'assets/packages/material_symbols_icons/lib/fonts/MaterialSymbolsRounded.ttf',
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE)
      // Si un archivo falla, los demás se guardan igual.
      .then((cache) => Promise.all(ESENCIALES.map((url) => cache.add(url).catch(() => null))))
      .then(() => self.skipWaiting()),
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys()
      .then((nombres) => Promise.all(nombres.filter((n) => n !== CACHE).map((n) => caches.delete(n))))
      .then(() => self.clients.claim()),
  );
});

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  if (new URL(req.url).origin !== self.location.origin) return;

  // Páginas: primero la red para ver siempre la versión nueva;
  // sin conexión, la copia guardada.
  if (req.mode === 'navigate') {
    event.respondWith(
      fetch(req)
        .then((res) => {
          const copia = res.clone();
          caches.open(CACHE).then((cache) => cache.put('index.html', copia));
          return res;
        })
        .catch(() => caches.match('index.html')),
    );
    return;
  }

  // Código, fuentes e imágenes: primero la caché y se actualiza en segundo plano.
  event.respondWith(
    caches.open(CACHE).then(async (cache) => {
      const guardada = await cache.match(req, { ignoreSearch: true });
      const deRed = fetch(req)
        .then((res) => {
          if (res.ok) cache.put(req, res.clone());
          return res;
        })
        .catch(() => guardada);
      return guardada || deRed;
    }),
  );
});
