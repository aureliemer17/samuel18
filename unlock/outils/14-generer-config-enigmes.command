#!/bin/zsh

# Valide les registres separes et genere les configurations du jeu.
set -e
OUTILS_DIR="${0:A:h}"
ROOT_DIR="${OUTILS_DIR:h:h}"
REGISTRE_DIR="${ROOT_DIR}/registre"
for file in registre-machines.csv registre-pages.csv registre-indices.csv; do
  [[ -f "$REGISTRE_DIR/$file" ]] || { print -u2 "Registre introuvable : $file"; exit 1; }
done
node - "$REGISTRE_DIR" "$ROOT_DIR/unlock/config" <<'NODE'
const fs = require("fs");
const path = require("path");
const [registryDir, configDir] = process.argv.slice(2);
const read = (name) => {
  const lines = fs.readFileSync(path.join(registryDir, name), "utf8").trim().split(/\r?\n/);
  const headers = lines.shift().split(";");
  return lines.filter(Boolean).map((line) => Object.fromEntries(headers.map((header, index) => [header, (line.split(";")[index] || "").trim()])));
};
const active = (row) => row.Actif.toLowerCase() === "oui";
const machines = read("registre-machines.csv").filter(active);
const pages = read("registre-pages.csv").filter(active);
const hints = read("registre-indices.csv").filter(active);
const duplicateCodes = machines.map((row) => row.Code).filter((code, index, codes) => codes.indexOf(code) !== index);
if (duplicateCodes.length) throw new Error(`Codes machine dupliques : ${[...new Set(duplicateCodes)].join(", ")}`);
const machineMap = Object.fromEntries(machines.map((row) => [row.Code, row.Destination]));
const pageMap = Object.fromEntries(pages.map((row) => [row.Identifiant, Object.fromEntries([
  ["entryCode", row["Code entree"]],
  ["unlockCode", row["Code devoile"]],
].filter(([, value]) => value))]));
const hintMap = {};
for (const row of hints) {
  const entry = hintMap[row.Carte] ||= { hints: [] };
  entry.hints[Number(row.Position) - 1] = row.Texte;
  if (row.Solution.toLowerCase() === "oui") entry.solution = Number(row.Position);
}
for (const entry of Object.values(hintMap)) entry.hints = entry.hints.filter(Boolean);
fs.writeFileSync(path.join(configDir, "config.js"), `// Genere depuis registre/registre-machines.csv et registre/registre-pages.csv.\nwindow.PUZZLE_CONFIG = ${JSON.stringify({ machines: machineMap, pages: pageMap }, null, 2)};\n`);
fs.writeFileSync(path.join(configDir, "hints-config.js"), `// Genere depuis registre/registre-indices.csv.\nwindow.HINTS_CONFIG = ${JSON.stringify(hintMap, null, 2)};\n`);
console.log(`Configurations generees : ${machines.length} machine(s), ${pages.length} page(s), ${hints.length} indice(s).`);
NODE
read "?Appuyez sur Entree pour fermer cette fenetre..."
