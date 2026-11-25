#!/bin/zsh

# Importe l'inventaire unifie Drive. Les liens photo et video sont extraits
# vers les formats de compatibilite actuels, puis leurs configurations sont regenerees.
set -e
OUTILS_DIR="${0:A:h}"
DOSSIERS_DIR="${OUTILS_DIR:h:h}/dossiers"
IMPORT_DIR="${DOSSIERS_DIR}/drive-imports"
INPUT="${IMPORT_DIR}/drive-inventaire-medias.csv"
[[ -f "$INPUT" ]] || { print -u2 "Placez le CSV Drive ici : $INPUT"; exit 1; }
mkdir -p "$IMPORT_DIR"
PHOTO_CSV="${DOSSIERS_DIR}/photos-google-drive-inventaire.csv"
VIDEO_CSV="${DOSSIERS_DIR}/liens-videos-a-completer.csv"
node - "$INPUT" "$PHOTO_CSV" "$VIDEO_CSV" <<'NODE'
const fs = require("fs");
const [input, photos, videos] = process.argv.slice(2);
const parse = (line) => {
  const values = [];
  let value = "";
  let quoted = false;
  for (let index = 0; index < line.length; index += 1) {
    const character = line[index];
    if (character === '"') {
      if (quoted && line[index + 1] === '"') { value += '"'; index += 1; }
      else quoted = !quoted;
    } else if (character === "," && !quoted) { values.push(value); value = ""; }
    else value += character;
  }
  values.push(value);
  return values;
};
const quote = (value) => `"${String(value).replaceAll('"', '""')}"`;
const rows = fs.readFileSync(input, "utf8").split(/\r?\n/).filter(Boolean).slice(1).map(parse);
const photoRows = [["Thème", "Dossier", "Nom exact de la photo", "ID Google Drive", "Lien Google Drive"]];
const videoRows = [["Thème", "Dossier", "Nom exact de la vidéo", "Lien Google Drive"]];
for (const [theme, folder, name, type, , id, link] of rows) {
  if (!theme || !folder || !name || !id || !link) continue;
  if (type === "Photo") photoRows.push([theme, folder, name, id, link]);
  if (type === "Video") videoRows.push([theme, folder, name, link]);
}
fs.writeFileSync(photos, photoRows.map((row) => row.map(quote).join(",")).join("\n") + "\n");
fs.writeFileSync(videos, videoRows.map((row) => row.map(quote).join(",")).join("\n") + "\n");
console.log(`Photos importables : ${photoRows.length - 1} | Videos importables : ${videoRows.length - 1}`);
NODE
printf '\n' | "$OUTILS_DIR/09-importer-liens-photos-google-drive.command"
printf '\n' | "$OUTILS_DIR/03-importer-liens-videos-csv.command"
printf '\n' | "$OUTILS_DIR/04-mettre-a-jour-liens-videos.command"
