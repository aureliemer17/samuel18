#!/bin/zsh

# Crée un inventaire séparé des photos à déposer ou lier dans Google Drive.
# Ne modifie ni les photos, ni les vidéos, ni les configurations d'archives.
set -e
setopt null_glob extended_glob
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

OUTILS_DIR="${0:A:h}"
DOSSIERS_DIR="${OUTILS_DIR:h:h}/dossiers"
REPORT_FILE="${DOSSIERS_DIR}/photos-google-drive-a-completer.csv"

if [[ ! -d "$DOSSIERS_DIR" ]]; then
  print -u2 "Dossier introuvable : $DOSSIERS_DIR"
  exit 1
fi

csv_escape() {
  local value="${1//\"/\"\"}"
  print -r -- "\"${value}\""
}

header='"Thème","Dossier","Nom exact de la photo","Extension","Taille en Mo","Date de création","Lien Google Drive","État"'
print "$header" > "$REPORT_FILE"

total=0
total_size_bytes=0

for category_dir in "$DOSSIERS_DIR"/*(/N); do
  category_name="${category_dir:t}"
  [[ "$category_name" == "heic" || "$category_name" == "videos" || "$category_name" == "pdf-images" || "$category_name" == "photos" || "$category_name" == "travail" || "$category_name" == "rapports" || "$category_name" == "drive-imports" ]] && continue
  for folder_dir in "$category_dir"/*(/N); do
    folder_name="${folder_dir:t}"
    for photo_file in "$folder_dir"/*.(#i)(jpg|jpeg|png|gif|webp|avif)(.N); do
      photo_name="${photo_file:t}"
      extension="${photo_name:e:u}"
      size_bytes="$(stat -f '%z' "$photo_file")"
      size_mo="$(awk -v bytes="$size_bytes" 'BEGIN { printf "%.2f", bytes / 1024 / 1024 }')"
      created_at="$(stat -f '%SB' -t '%d/%m/%Y %H:%M' "$photo_file")"
      row="$(csv_escape "$category_name"),$(csv_escape "$folder_name"),$(csv_escape "$photo_name"),$(csv_escape "$extension"),${size_mo},$(csv_escape "$created_at"),$(csv_escape ""),$(csv_escape "À compléter")"
      print "$row" >> "$REPORT_FILE"
      (( total += 1 ))
      (( total_size_bytes += size_bytes ))
    done
  done
done

total_size_mo="$(awk -v bytes="$total_size_bytes" 'BEGIN { printf "%.2f", bytes / 1024 / 1024 }')"
pbcopy < "$REPORT_FILE"

print ""
print "Inventaire photos : ${REPORT_FILE}"
print "Photos trouvées : ${total} | Taille totale : ${total_size_mo} Mo"
print "Le tableau est aussi copié dans le presse-papiers."
print ""
read "?Appuyez sur Entree pour fermer cette fenetre..."
