// Minimal "build" step — copy src/index.js to dist/index.js.
// No bundler: we want the plugin to be transparent and easy to debug.
import fs from "node:fs";
import path from "node:path";

const root = path.dirname(new URL(import.meta.url).pathname);
fs.mkdirSync(path.join(root, "dist"), { recursive: true });
fs.copyFileSync(path.join(root, "src/index.js"), path.join(root, "dist/index.js"));
console.log("[build] copied src/index.js -> dist/index.js");
