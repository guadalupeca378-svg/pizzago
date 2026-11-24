#!/usr/bin/env node
/**
 * Vistas generadas del lado del servidor.
 *
 * Lee el menú de Cloud Firestore con el Firebase Admin SDK y escribe páginas
 * HTML completas en build/web/menu/: la lista del menú y una página por
 * producto, más build/web/sitemap.xml. El navegador recibe el HTML ya armado,
 * sin ejecutar Flutter, así que cargan al instante y los buscadores las leen.
 *
 * Se ejecuta solo antes de cada `firebase deploy` (predeploy en firebase.json)
 * o a mano con `npm run render` desde esta carpeta.
 */
const fs = require("fs");
const path = require("path");

const SITE = "https://pizzago-874f4.web.app";
const OUT = path.resolve(__dirname, "..", "build", "web");
const KEY_PATH = path.resolve(__dirname, "serviceAccountKey.json");

// Mismas reglas que la aplicación (lib/data/models/pizza.dart).
const CATEGORIES = [
  ["clasicas", "Clásicas"],
  ["especiales", "Especiales"],
  ["vegetarianas", "Veggie"],
  ["bebidas", "Bebidas"],
  ["postres", "Postres"],
];
const PIZZA_CATEGORIES = new Set(["clasicas", "especiales", "vegetarianas"]);
const SIZES = [
  ["Chica", "25 cm", 1.0],
  ["Mediana", "30 cm", 1.3],
  ["Grande", "35 cm", 1.6],
];
const hasSizes = (p) => PIZZA_CATEGORIES.has(p.category);
const priceFor = (p, multiplier) => (hasSizes(p) ? Math.ceil(p.basePrice * multiplier) : p.basePrice);
const money = (n) => `$${n.toLocaleString("es-MX", { maximumFractionDigits: 2 })}`;

const esc = (s) =>
  String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);

function generatedAt() {
  return new Intl.DateTimeFormat("es-MX", {
    dateStyle: "long",
    timeStyle: "short",
    timeZone: "America/Mexico_City",
  }).format(new Date());
}

const STYLE = `
@font-face{font-family:Poppins;src:url(/assets/assets/fonts/Poppins-Regular.ttf);font-weight:400}
@font-face{font-family:Poppins;src:url(/assets/assets/fonts/Poppins-SemiBold.ttf);font-weight:600}
@font-face{font-family:Poppins;src:url(/assets/assets/fonts/Poppins-Bold.ttf);font-weight:700}
@font-face{font-family:'DM Serif Display';src:url(/assets/assets/fonts/DMSerifDisplay-Regular.ttf)}
:root{--tomate:#D0331F;--carbon:#2B2928;--fondo:#F7F6F3;--tarjeta:#fff;--tenue:#6B6560;--linea:#E6E2DC}
@media (prefers-color-scheme:dark){:root{--carbon:#F2EFEA;--fondo:#151413;--tarjeta:#1E1D1B;--tenue:#A8A29C;--linea:#2E2C2A}}
*{box-sizing:border-box}body{margin:0;font-family:Poppins,system-ui,sans-serif;background:var(--fondo);color:var(--carbon);line-height:1.5}
a{color:inherit}header{background:var(--tomate);color:#fff;padding:20px 24px}
header .marca{font-family:'DM Serif Display',serif;font-size:28px;text-decoration:none}
header p{margin:4px 0 0;opacity:.9;font-size:14px}
main{max-width:1040px;margin:0 auto;padding:24px}
h1{font-size:28px;margin:8px 0 4px}h2{font-size:20px;margin:32px 0 12px}
.rejilla{display:grid;grid-template-columns:repeat(auto-fill,minmax(230px,1fr));gap:16px}
.tarjeta{background:var(--tarjeta);border:1px solid var(--linea);border-radius:16px;overflow:hidden;text-decoration:none;display:flex;flex-direction:column}
.tarjeta img{width:100%;aspect-ratio:4/3;object-fit:cover;display:block}
.tarjeta div{padding:12px 14px 16px}.tarjeta h3{margin:0;font-size:16px}
.tarjeta p{margin:4px 0 8px;color:var(--tenue);font-size:13px}
.precio{font-weight:700}.desde{font-weight:400;color:var(--tenue);font-size:12px}
.boton{display:inline-block;background:var(--tomate);color:#fff;text-decoration:none;padding:12px 20px;border-radius:999px;font-weight:600}
.ficha{display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1fr);gap:28px}
@media (max-width:760px){.ficha{grid-template-columns:1fr}}
.ficha img{width:100%;border-radius:16px;aspect-ratio:4/3;object-fit:cover}
table{width:100%;border-collapse:collapse;margin:12px 0 20px}td,th{text-align:left;padding:10px;border-bottom:1px solid var(--linea)}
.etiqueta{display:inline-block;background:var(--tarjeta);border:1px solid var(--linea);border-radius:999px;padding:2px 10px;font-size:12px;margin-right:6px}
footer{max-width:1040px;margin:0 auto;padding:24px;color:var(--tenue);font-size:12px;border-top:1px solid var(--linea)}
`;

function page({ title, description, canonical, body, jsonLd, stamp }) {
  return `<!DOCTYPE html>
<html lang="es-MX">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${esc(title)}</title>
<meta name="description" content="${esc(description)}">
<meta name="theme-color" content="#D0331F">
<link rel="canonical" href="${SITE}${canonical}">
<link rel="icon" type="image/png" href="/favicon.png">
<link rel="manifest" href="/manifest.json">
<meta property="og:title" content="${esc(title)}">
<meta property="og:description" content="${esc(description)}">
<meta property="og:type" content="website">
<style>${STYLE}</style>
${jsonLd ? `<script type="application/ld+json">${JSON.stringify(jsonLd)}</script>` : ""}
</head>
<body>
<header><a class="marca" href="/menu/">PizzaGo</a><p>Pizzería artesanal · Horno de piedra</p></header>
<main>
${body}
</main>
<footer>Página generada en el servidor el ${esc(stamp)} con datos de Cloud Firestore. <a href="/">Abrir la aplicación PizzaGo</a></footer>
</body>
</html>
`;
}

function card(p) {
  return `<a class="tarjeta" href="/menu/${esc(p.id)}/">
<img src="/assets/assets/images/products/${esc(p.id)}.jpg" alt="${esc(p.name)}" loading="lazy" width="400" height="300">
<div><h3>${esc(p.name)}</h3><p>${esc(p.description)}</p>
<span class="desde">${hasSizes(p) ? "desde " : ""}</span><span class="precio">${money(priceFor(p, 1))}</span></div></a>`;
}

function menuPage(items, stamp) {
  const sections = CATEGORIES.map(([id, label]) => {
    const list = items.filter((p) => p.category === id);
    return list.length ? `<h2 id="${id}">${label}</h2>\n<div class="rejilla">${list.map(card).join("\n")}</div>` : "";
  }).join("\n");
  return page({
    title: "Menú de PizzaGo",
    description: `Menú de PizzaGo: ${items.length} productos entre pizzas, bebidas y postres. Envío de $39, gratis desde $400.`,
    canonical: "/menu/",
    stamp,
    body: `<h1>Menú</h1>
<p>${items.length} productos. Envío de $39, gratis en pedidos desde $400.</p>
<p><a class="boton" href="/">Pedir en la aplicación</a></p>
${sections}`,
    jsonLd: {
      "@context": "https://schema.org",
      "@type": "Restaurant",
      name: "PizzaGo",
      servesCuisine: "Pizza",
      url: SITE,
      hasMenu: `${SITE}/menu/`,
    },
  });
}

function productPage(p, extras, stamp) {
  const rows = hasSizes(p)
    ? SIZES.map(([name, cm, m]) => `<tr><td>${name}</td><td>${cm}</td><td class="precio">${money(priceFor(p, m))}</td></tr>`).join("")
    : `<tr><td>Precio</td><td></td><td class="precio">${money(p.basePrice)}</td></tr>`;
  const extrasHtml = hasSizes(p)
    ? `<h2>Extras</h2><table>${extras.map((e) => `<tr><td>${esc(e.name)}</td><td class="precio">+${money(e.price)}</td></tr>`).join("")}</table>`
    : "";
  const tags = [
    p.isPopular && "Más pedida",
    p.isSpicy && "Picante",
    p.isVeggie && hasSizes(p) && "Vegetariana",
    p.prepMinutes && `${p.prepMinutes} min`,
    p.rating && `★ ${p.rating}`,
  ].filter(Boolean);

  return page({
    title: `${p.name} · PizzaGo`,
    description: `${p.name}: ${p.description}`,
    canonical: `/menu/${p.id}/`,
    stamp,
    body: `<p><a href="/menu/">← Volver al menú</a></p>
<div class="ficha">
<img src="/assets/assets/images/products/${esc(p.id)}.jpg" alt="${esc(p.name)}" width="800" height="600">
<div>
<h1>${esc(p.name)}</h1>
<p>${tags.map((t) => `<span class="etiqueta">${esc(t)}</span>`).join("")}</p>
<p>${esc(p.description)}</p>
${p.ingredients?.length ? `<p><strong>Ingredientes:</strong> ${p.ingredients.map(esc).join(", ")}.</p>` : ""}
<table><tr><th>Tamaño</th><th></th><th>Precio</th></tr>${rows}</table>
<p><a class="boton" href="/#/pizza/${esc(p.id)}">Pedirla en PizzaGo</a></p>
</div></div>
${extrasHtml}`,
    jsonLd: {
      "@context": "https://schema.org",
      "@type": "Product",
      name: p.name,
      description: p.description,
      image: `${SITE}/assets/assets/images/products/${p.id}.jpg`,
      offers: { "@type": "Offer", priceCurrency: "MXN", price: priceFor(p, 1), availability: "https://schema.org/InStock" },
    },
  });
}

async function main() {
  if (!fs.existsSync(path.join(OUT, "index.html"))) {
    throw new Error("No existe build/web. Corre antes: flutter build web --release --no-web-resources-cdn");
  }
  const { initializeApp, cert } = require("firebase-admin/app");
  const { getFirestore } = require("firebase-admin/firestore");
  initializeApp({ credential: cert(require(KEY_PATH)) });
  const db = getFirestore();

  const [pizzasSnap, extrasSnap] = await Promise.all([
    db.collection("pizzas").orderBy("order").get(),
    db.collection("extras").orderBy("order").get(),
  ]);
  const items = pizzasSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
  const extras = extrasSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
  if (!items.length) throw new Error("Firestore no tiene productos. Corre npm run seed.");

  const stamp = generatedAt();
  const menuDir = path.join(OUT, "menu");
  fs.rmSync(menuDir, { recursive: true, force: true });
  fs.mkdirSync(menuDir, { recursive: true });
  fs.writeFileSync(path.join(menuDir, "index.html"), menuPage(items, stamp));
  for (const p of items) {
    fs.mkdirSync(path.join(menuDir, p.id), { recursive: true });
    fs.writeFileSync(path.join(menuDir, p.id, "index.html"), productPage(p, extras, stamp));
  }

  const urls = ["/", "/menu/", ...items.map((p) => `/menu/${p.id}/`)];
  fs.writeFileSync(
    path.join(OUT, "sitemap.xml"),
    `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${urls
      .map((u) => `  <url><loc>${SITE}${u}</loc></url>`)
      .join("\n")}\n</urlset>\n`,
  );
  console.log(`✔ Vistas del servidor: menú + ${items.length} productos y sitemap.xml (${stamp}).`);
}

main().catch((err) => {
  console.error(`✖ ${err.message}`);
  process.exitCode = 1;
});
