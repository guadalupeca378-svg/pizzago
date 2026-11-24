#!/usr/bin/env node
/**
 * Envía una notificación push de promoción a todos los navegadores que
 * activaron las notificaciones en PizzaGo (Firebase Cloud Messaging).
 *
 * Uso (desde esta carpeta):
 *   npm run promo -- --dry-run
 *   npm run promo -- --titulo "2x1 los martes" --texto "Pide dos pizzas medianas y paga una."
 *
 * Los destinatarios salen de Firestore: usuarios/{uid}/dispositivos/{fid}.
 * Si un identificador ya no es válido (el usuario quitó el permiso), se borra.
 */
const path = require("path");

const args = process.argv.slice(2);
const opt = (name, fallback) => {
  const i = args.indexOf(`--${name}`);
  return i >= 0 && args[i + 1] ? args[i + 1] : fallback;
};
const DRY_RUN = args.includes("--dry-run");
const TITULO = opt("titulo", "Cupón PIZZAGO10");
const TEXTO = opt("texto", "Hoy tienes 10 % de descuento en todo tu pedido con el cupón PIZZAGO10.");
const SITE = "https://pizzago-874f4.web.app";

async function main() {
  const { initializeApp, cert } = require("firebase-admin/app");
  const { getFirestore } = require("firebase-admin/firestore");
  const { getMessaging } = require("firebase-admin/messaging");
  initializeApp({ credential: cert(require(path.join(__dirname, "serviceAccountKey.json"))) });

  const snap = await getFirestore().collectionGroup("dispositivos").get();
  const destinos = snap.docs.map((d) => ({ fid: d.get("fid"), token: d.get("token"), ref: d.ref })).filter((d) => d.fid);
  console.log(`→ ${destinos.length} navegador(es) con notificaciones activadas.`);
  console.log(`  Título: ${TITULO}\n  Texto:  ${TEXTO}`);
  if (DRY_RUN || destinos.length === 0) {
    console.log(DRY_RUN ? "Modo --dry-run: no se envió nada." : "No hay a quién enviar.");
    return;
  }

  const contenido = {
    notification: { title: TITULO, body: TEXTO },
    webpush: {
      notification: { icon: `${SITE}/icons/Icon-192.png`, badge: `${SITE}/icons/Icon-192.png`, lang: "es-MX" },
      fcmOptions: { link: `${SITE}/` },
    },
  };
  const messaging = getMessaging();
  const res = await messaging.sendEachForMulticast({ fids: destinos.map((d) => d.fid), ...contenido });

  const VENCIDO = /not-registered|invalid-argument/;
  let enviadas = res.successCount;
  let borrados = 0;
  await Promise.all(
    res.responses.map(async (r, i) => {
      if (!r.error) return;
      const d = destinos[i];
      // Respaldo: el token anterior de ese navegador, si se guardó.
      if (d.token) {
        try {
          await messaging.send({ token: d.token, ...contenido });
          enviadas++;
          return;
        } catch (e) {
          r.error = e;
        }
      }
      if (VENCIDO.test(r.error.code ?? "")) {
        await d.ref.delete();
        borrados++;
      } else {
        console.log(`  ✖ ${d.fid.slice(0, 12)}…: ${r.error.code}`);
      }
    }),
  );
  console.log(`✔ Enviadas: ${enviadas}. Fallidas: ${destinos.length - enviadas}. Registros vencidos borrados: ${borrados}.`);
}

main().catch((err) => {
  console.error(`✖ ${err.message}`);
  process.exitCode = 1;
});
