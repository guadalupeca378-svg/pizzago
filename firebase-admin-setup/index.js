const { initializeApp, cert } = require("firebase-admin/app");
const serviceAccount = require("./serviceAccountKey.json");

initializeApp({ credential: cert(serviceAccount) });

console.log("Firebase Admin SDK inicializado correctamente.");
console.log("Proyecto conectado:", serviceAccount.project_id);
