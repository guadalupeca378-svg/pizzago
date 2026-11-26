#!/usr/bin/env node
/**
 * Prueba las reglas de Firestore publicadas, como lo haría un cliente.
 * Crea dos cuentas temporales en Firebase Authentication (A y B), intenta
 * leer y escribir datos propios y ajenos, y al final borra ambas cuentas.
 * Las pruebas usan solo la configuración pública de la web, como cualquier
 * navegador; la llave de servicio se usa únicamente para limpiar al final.
 *
 * Uso (desde esta carpeta): npm run prueba:reglas
 */
const API_KEY = "AIzaSyDrpRRXDg5uiV6sUd9RbQWZJMr8f2-9t6E";
const PROYECTO = "pizzago-874f4";
const AUTH = "https://identitytoolkit.googleapis.com/v1/accounts";
const DB = `https://firestore.googleapis.com/v1/projects/${PROYECTO}/databases/(default)/documents`;

async function cuentaTemporal(nombre) {
  const correo = `reglas.${nombre}.${Date.now()}@pizzago.com`;
  const res = await fetch(`${AUTH}:signUp?key=${API_KEY}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email: correo, password: "Prueba2026x", returnSecureToken: true }),
  });
  const j = await res.json();
  if (!res.ok) throw new Error(j.error.message);
  return { correo, uid: j.localId, token: j.idToken };
}

const valor = (v) =>
  typeof v === "number" ? { integerValue: String(v) }
  : Array.isArray(v) ? { arrayValue: { values: v.map(valor) } }
  : typeof v === "object" ? { mapValue: { fields: campos(v) } }
  : { stringValue: v };
const campos = (o) => Object.fromEntries(Object.entries(o).map(([k, v]) => [k, valor(v)]));

async function pedir(metodo, ruta, token, datos) {
  const res = await fetch(`${DB}/${ruta}`, {
    method: metodo,
    headers: { ...(token && { Authorization: `Bearer ${token}` }), "Content-Type": "application/json" },
    body: datos && JSON.stringify({ fields: campos(datos) }),
  });
  return res.status;
}

(async () => {
  const a = await cuentaTemporal("a");
  const b = await cuentaTemporal("b");
  const perfil = (u) => ({ name: "Cliente de prueba", email: u.correo, phone: "9931234567", address: "Calle 5 #12, Centro" });
  const pedido = (id, userId) => ({ id, userId, total: 246, items: [{ nombre: "Pepperoni" }] });

  const casos = [
    ["A guarda su propio perfil", 200, () => pedir("PATCH", `usuarios/${a.uid}`, a.token, perfil(a))],
    ["A lee su propio perfil", 200, () => pedir("GET", `usuarios/${a.uid}`, a.token)],
    ["Sin sesión no se lee el perfil de A", 403, () => pedir("GET", `usuarios/${a.uid}`)],
    ["B no puede leer el perfil de A", 403, () => pedir("GET", `usuarios/${a.uid}`, b.token)],
    ["B no puede cambiar el perfil de A", 403, () => pedir("PATCH", `usuarios/${a.uid}`, b.token, perfil(b))],
    ["A no puede guardar un campo extra", 403, () => pedir("PATCH", `usuarios/${a.uid}`, a.token, { ...perfil(a), rol: "admin" })],
    ["A guarda un pedido suyo", 200, () => pedir("PATCH", `usuarios/${a.uid}/pedidos/P1`, a.token, pedido("P1", a.uid))],
    ["A no puede firmar un pedido como B", 403, () => pedir("PATCH", `usuarios/${a.uid}/pedidos/P2`, a.token, pedido("P2", b.uid))],
    ["B no puede leer los pedidos de A", 403, () => pedir("GET", `usuarios/${a.uid}/pedidos/P1`, b.token)],
    ["A no puede borrar su pedido", 403, () => pedir("DELETE", `usuarios/${a.uid}/pedidos/P1`, a.token)],
    ["Cualquiera puede leer el menú", 200, () => pedir("GET", "pizzas/pepperoni")],
    ["Un cliente no puede cambiar precios", 403, () => pedir("PATCH", "pizzas/pepperoni", a.token, { name: "Gratis" })],
  ];

  let bien = 0;
  console.log("Reglas de Firestore de PizzaGo\n");
  for (const [nombre, esperado, accion] of casos) {
    const obtenido = await accion();
    const ok = obtenido === esperado;
    if (ok) bien++;
    console.log(`${ok ? "OK   " : "FALLA"} ${nombre.padEnd(40)} esperado ${esperado}, obtenido ${obtenido}`);
  }
  console.log(`\n${bien} de ${casos.length} casos correctos.`);

  // Limpieza: las reglas no dejan borrar a los clientes, así que los
  // documentos de prueba se borran con el Admin SDK y luego las cuentas.
  const path = require("path");
  const { initializeApp, cert } = require("firebase-admin/app");
  const { getFirestore } = require("firebase-admin/firestore");
  initializeApp({ credential: cert(require(path.join(__dirname, "serviceAccountKey.json"))) });
  for (const u of [a, b]) await getFirestore().recursiveDelete(getFirestore().doc(`usuarios/${u.uid}`));
  for (const u of [a, b]) {
    await fetch(`${AUTH}:delete?key=${API_KEY}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ idToken: u.token }),
    });
  }
  console.log("Cuentas temporales eliminadas.");
  process.exitCode = bien === casos.length ? 0 : 1;
})().catch((e) => {
  console.error(e.message);
  process.exitCode = 1;
});
