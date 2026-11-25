#!/bin/zsh

# Produit ou applique un registre des codes d'archives. Les renommages locaux et
# Drive ne sont jamais effectues sans apercu puis confirmation explicite.
set -e
setopt null_glob extended_glob
OUTILS_DIR="${0:A:h}"
ROOT_DIR="${OUTILS_DIR:h:h}"
DOSSIERS_DIR="${ROOT_DIR}/dossiers"
REGISTRY="${ROOT_DIR}/registre/registre-archives.csv"
PLAN="${ROOT_DIR}/registre/plan-renommage-drive.csv"

if [[ ! -f "$REGISTRY" ]]; then
  print '"Theme","Dossier actuel","Code actuel","Nouveau code","Titre","Action"' > "$REGISTRY"
  for category_dir in "$DOSSIERS_DIR"/*(/N); do
    category="${category_dir:t}"
    [[ "$category" == (heic|videos|photos|pdf-images|travail|rapports|drive-imports) ]] && continue
    for folder_dir in "$category_dir"/*(/N); do
      folder="${folder_dir:t}"
      if [[ "$folder" =~ '^((I|II|III|IV|V|VI|VII)-[A-J]-[1-8])( - (.*))?$' ]]; then
        code="$match[1]"; title="$match[4]"
        print "\"$category\",\"$folder\",\"$code\",\"$code\",\"$title\",\"Aucune\"" >> "$REGISTRY"
      fi
    done
  done
  print "Registre genere : $REGISTRY"
  print "Modifiez Nouveau code puis relancez cette commande pour obtenir un apercu."
  read "?Appuyez sur Entree pour fermer cette fenetre..."
  exit 0
fi

node - "$REGISTRY" "$PLAN" <<'NODE'
const fs = require("fs");
const [registry, plan] = process.argv.slice(2);
const parse = (line) => line.match(/(?:^|,)(?:"((?:[^"]|"")*)"|([^,]*))/g).map((cell) => cell.replace(/^,/, "").replace(/^"|"$/g, "").replaceAll('""', '"'));
const rows = fs.readFileSync(registry, "utf8").trim().split(/\r?\n/).slice(1).map(parse);
const changes = rows.filter((row) => row[2] !== row[3] && row[5].toLowerCase() === "renommer");
const quote = (value) => `"${String(value).replaceAll('"', '""')}"`;
const output = [["Type", "Theme", "Ancien dossier", "Nouveau dossier", "Action"]];
for (const [theme, folder, oldCode, newCode, title] of changes) {
  output.push(["Dossier", theme, folder, `${newCode}${title ? ` - ${title}` : ""}`, "renommer"]);
}
fs.writeFileSync(plan, output.map((row) => row.map(quote).join(",")).join("\n") + "\n");
console.log(`Plan genere : ${changes.length} renommage(s).`);
NODE
print "Plan Google Drive genere : $PLAN"
print "Verifiez-le, puis utilisez google-drive-synchroniser-medias.gs pour appliquer les renommages Drive."
read "confirm?Appliquer aussi les renommages locaux indiques dans le plan ? [oui/N] "
if [[ "$confirm" == "oui" ]]; then
  node - "$REGISTRY" "$DOSSIERS_DIR" <<'NODE'
const fs = require("fs");
const path = require("path");
const [registry, root] = process.argv.slice(2);
const parse = (line) => line.match(/(?:^|,)(?:"((?:[^"]|"")*)"|([^,]*))/g).map((cell) => cell.replace(/^,/, "").replace(/^"|"$/g, "").replaceAll('""', '"'));
for (const [theme, folder, oldCode, newCode, title, action] of fs.readFileSync(registry, "utf8").trim().split(/\r?\n/).slice(1).map(parse)) {
  if (action.toLowerCase() !== "renommer" || oldCode === newCode) continue;
  const oldPath = path.join(root, theme, folder);
  const newPath = path.join(root, theme, `${newCode}${title ? ` - ${title}` : ""}`);
  if (!fs.existsSync(oldPath)) throw new Error(`Dossier local introuvable : ${oldPath}`);
  if (fs.existsSync(newPath)) throw new Error(`Destination locale existante : ${newPath}`);
  fs.renameSync(oldPath, newPath);
  console.log(`Renomme : ${folder} -> ${path.basename(newPath)}`);
}
NODE
fi
read "?Appuyez sur Entree pour fermer cette fenetre..."
