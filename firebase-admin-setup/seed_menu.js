#!/usr/bin/env node
/**
 * Carga el menú de PizzaGo en Cloud Firestore con el Firebase Admin SDK.
 *
 * Usa el mismo archivo que la aplicación Flutter (assets/data/menu.json),
 * así el menú local y el de Firestore nunca se desincronizan.
 *
 * Uso (desde la carpeta firebase-admin-setup):
 *   npm run seed:dry      Valida el JSON y muestra lo que se subiría (no se conecta)
 *   npm run seed          Crea o actualiza las colecciones `pizzas` y `extras`
 *   npm run seed:clean    Borra ambas colecciones y las vuelve a crear
 *
 * Requisitos: serviceAccountKey.json en esta carpeta y Firestore activado
 * en la consola de Firebase (Compilación → Firestore Database).
 */
const fs = require("fs");
const path = require("path");

const MENU_PATH = path.resolve(__dirname, "..", "assets", "data", "menu.json");
const KEY_PATH = path.resolve(__dirname, "serviceAccountKey.json");
const BATCH_LIMIT = 450; // Firestore permite 500 operaciones por lote.
const CATEGORIES = new Set(["clasicas", "especiales", "vegetarianas", "bebidas", "postres"]);

const args = new Set(process.argv.slice(2));
const DRY_RUN = args.has("--dry-run");
const CLEAN = args.has("--clean");

function loadMenu() {
  const menu = JSON.parse(fs.readFileSync(MENU_PATH, "utf8"));
  const errors = [];

  const checkUnique = (list, name) => {
    const seen = new Set();
    for (const doc of list) {
      if (!doc.id || typeof doc.id !== "string") errors.push(`${name}: documento sin id`);
      else if (seen.has(doc.id)) errors.push(`${name}: id repetido "${doc.id}"`);
      seen.add(doc.id);
    }
  };

  if (!Array.isArray(menu.pizzas) || !Array.isArray(menu.extras)) {
    throw new Error("menu.json debe tener los arreglos `pizzas` y `extras`.");
  }
  checkUnique(menu.pizzas, "pizzas");
  checkUnique(menu.extras, "extras");

  for (const p of menu.pizzas) {
    if (typeof p.name !== "string" || !p.name) errors.push(`pizzas/${p.id}: falta name`);
    if (typeof p.basePrice !== "number" || p.basePrice <= 0) errors.push(`pizzas/${p.id}: basePrice inválido`);
    if (!CATEGORIES.has(p.category)) errors.push(`pizzas/${p.id}: categoría "${p.category}" no existe`);
  }
  for (const e of menu.extras) {
    if (typeof e.price !== "number" || e.price < 0) errors.push(`extras/${e.id}: price inválido`);
  }

  if (errors.length) {
    throw new Error(`menu.json tiene ${errors.length} error(es):\n  - ${errors.join("\n  - ")}`);
  }
  return menu;
}

/** Divide un arreglo en trozos de `size` elementos. */
const chunk = (list, size) =>
  Array.from({ length: Math.ceil(list.length / size) }, (_, i) => list.slice(i * size, (i + 1) * size));

async function deleteCollection(db, name) {
  let deleted = 0;
  for (;;) {
    const snapshot = await db.collection(name).limit(BATCH_LIMIT).get();
    if (snapshot.empty) return deleted;
    const batch = db.batch();
    snapshot.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    deleted += snapshot.size;
  }
}

async function writeCollection(db, FieldValue, name, docs) {
  for (const part of chunk(docs, BATCH_LIMIT)) {
    const batch = db.batch();
    for (const { id, ...data } of part) {
      batch.set(
        db.collection(name).doc(id),
        { ...data, updatedAt: FieldValue.serverTimestamp() },
        { merge: true },
      );
    }
    await batch.commit();
  }
}

async function main() {
  const menu = loadMenu();
  console.log(`✔ menu.json válido: ${menu.pizzas.length} productos, ${menu.extras.length} extras.`);

  if (DRY_RUN) {
    const byCategory = menu.pizzas.reduce((acc, p) => ({ ...acc, [p.category]: (acc[p.category] ?? 0) + 1 }), {});
    console.table(byCategory);
    console.log("Modo --dry-run: no se escribió nada en Firestore.");
    return;
  }

  if (!fs.existsSync(KEY_PATH)) {
    throw new Error("No se encontró serviceAccountKey.json en firebase-admin-setup/.");
  }

  const { initializeApp, cert } = require("firebase-admin/app");
  const { getFirestore, FieldValue } = require("firebase-admin/firestore");
  const serviceAccount = require(KEY_PATH);
  initializeApp({ credential: cert(serviceAccount) });
  const db = getFirestore();
  console.log(`→ Proyecto: ${serviceAccount.project_id}`);

  if (CLEAN) {
    for (const name of ["pizzas", "extras"]) {
      const count = await deleteCollection(db, name);
      console.log(`  borrados ${count} documentos de ${name}`);
    }
  }

  await writeCollection(db, FieldValue, "pizzas", menu.pizzas);
  await writeCollection(db, FieldValue, "extras", menu.extras);
  console.log(`✔ Firestore actualizado: pizzas (${menu.pizzas.length}) y extras (${menu.extras.length}).`);
}

main().catch((err) => {
  console.error(`✖ ${err.message}`);
  if (err.code === 5 || /NOT_FOUND/.test(err.message)) {
    console.error("  ¿Ya creaste la base de datos de Firestore en la consola de Firebase?");
  }
  process.exitCode = 1;
});
