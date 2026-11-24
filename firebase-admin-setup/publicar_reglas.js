#!/usr/bin/env node
/**
 * Publica firestore.rules en el proyecto con el Admin SDK.
 * Uso (desde esta carpeta): npm run reglas
 */
const fs = require("fs");
const path = require("path");
const { initializeApp, cert } = require("firebase-admin/app");
const { getSecurityRules } = require("firebase-admin/security-rules");

initializeApp({ credential: cert(require(path.join(__dirname, "serviceAccountKey.json"))) });

const source = fs.readFileSync(path.resolve(__dirname, "..", "firestore.rules"), "utf8");
getSecurityRules()
  .releaseFirestoreRulesetFromSource(source)
  .then((r) => console.log(`✔ Reglas de Firestore publicadas (${r.name.split("/").pop()}, ${r.createTime}).`))
  .catch((err) => {
    console.error(`✖ ${err.message}`);
    process.exitCode = 1;
  });
