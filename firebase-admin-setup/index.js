const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.cert(serviceAccount),
});

console.log("Firebase Admin SDK inicializado correctamente.");
console.log("Proyecto conectado:", serviceAccount.project_id);
