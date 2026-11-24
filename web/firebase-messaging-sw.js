// Service worker de Firebase Cloud Messaging.
// Recibe las promociones push aunque PizzaGo esté cerrada y las muestra
// como notificación del sistema. Vive en su propio alcance
// (/firebase-cloud-messaging-push-scope), aparte de sw.js.
importScripts('https://www.gstatic.com/firebasejs/13.3.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/13.3.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyDrpRRXDg5uiV6sUd9RbQWZJMr8f2-9t6E',
  appId: '1:517144629815:web:09112ed7fe68cfc28765b2',
  messagingSenderId: '517144629815',
  projectId: 'pizzago-874f4',
  authDomain: 'pizzago-874f4.firebaseapp.com',
  storageBucket: 'pizzago-874f4.firebasestorage.app',
});

// Los mensajes con "notification" se muestran solos; este manejador cubre
// los que solo traen datos.
firebase.messaging().onBackgroundMessage((payload) => {
  if (payload.notification) return;
  const data = payload.data || {};
  self.registration.showNotification(data.title || 'PizzaGo', {
    body: data.body || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: { url: data.url || '/' },
  });
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const url = (event.notification.data && event.notification.data.url) || '/';
  event.waitUntil(clients.openWindow(url));
});
