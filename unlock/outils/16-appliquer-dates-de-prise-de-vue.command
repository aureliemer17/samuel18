#!/bin/zsh

# Aligne les dates de fichiers photo avec la date de prise de vue indexee par
# macOS (EXIF/Spotlight). Les originaux ne sont modifies qu'apres confirmation.
set -e
setopt null_glob extended_glob
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

OUTILS_DIR="${0:A:h}"
DOSSIERS_DIR="${OUTILS_DIR:h:h}/dossiers"
REPORT_FILE="$(mktemp)"

cleanup() {
  rm -f "$REPORT_FILE"
}
trap cleanup EXIT

[[ -d "$DOSSIERS_DIR" ]] || { print -u2 "Dossier introuvable : $DOSSIERS_DIR"; exit 1; }
command -v SetFile >/dev/null || { print -u2 "SetFile est requis pour modifier la date de creation. Installez les Command Line Tools Apple puis relancez."; exit 1; }

updates=0
skipped=0
for category_dir in "$DOSSIERS_DIR"/*(/N); do
  category_name="${category_dir:t}"
  [[ "$category_name" == (heic|videos|photos|pdf-images|travail|rapports|drive-imports) ]] && continue
  for folder_dir in "$category_dir"/*(/N); do
    for image_file in "$folder_dir"/*.(#i)(jpg|jpeg|png|gif|webp|avif|heic|heif)(.N); do
      captured_at="$(mdls -raw -name kMDItemContentCreationDate "$image_file" 2>/dev/null || true)"
      [[ -n "$captured_at" && "$captured_at" != "(null)" ]] || { (( skipped += 1 )); continue; }
      timestamp="$(date -j -f "%Y-%m-%d %H:%M:%S %z" "$captured_at" "+%Y%m%d%H%M.%S" 2>/dev/null || true)"
      [[ -n "$timestamp" ]] || { print "Date ignorée : ${image_file:t} (${captured_at})"; (( skipped += 1 )); continue; }
      current_timestamp="$(stat -f "%Sm" -t "%Y%m%d%H%M.%S" "$image_file")"
      [[ "$current_timestamp" == "$timestamp" ]] && continue
      print -r -- "${timestamp}|${image_file}" >> "$REPORT_FILE"
      (( updates += 1 ))
    done
  done
done

if (( updates == 0 )); then
  print "Aucune date de fichier à modifier. Photos sans date de prise de vue : ${skipped}."
  read "?Appuyez sur Entree pour fermer cette fenetre..."
  exit 0
fi

print ""
print "${updates} photo(s) seront mises à jour avec leur date de prise de vue."
print "Photos ignorées (métadonnée absente ou invalide) : ${skipped}."
print ""
while IFS='|' read -r timestamp image_file; do
  print "${timestamp}  ${image_file#$DOSSIERS_DIR/}"
done < "$REPORT_FILE"
print ""
read "confirmation?Appliquer ces dates ? (o/N) : "
[[ "$confirmation" == [oO] ]] || { print "Aucune modification effectuée."; exit 0; }

while IFS='|' read -r timestamp image_file; do
  touch -t "$timestamp" "$image_file"
  SetFile -d "$(date -j -f "%Y%m%d%H%M.%S" "$timestamp" "+%m/%d/%Y %H:%M:%S")" "$image_file"
done < "$REPORT_FILE"

print ""
print "Dates appliquées : ${updates}."
print "Relancez ensuite la régénération locale pour actualiser archive-config.local.js."
read "?Appuyez sur Entree pour fermer cette fenetre..."
