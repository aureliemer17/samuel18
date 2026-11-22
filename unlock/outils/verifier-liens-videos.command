#!/bin/zsh

# Inventorie les vidéos locales et vérifie leurs liens Google Drive associés.
# Ne modifie aucun fichier. Deux tableaux CSV sont enregistrés dans ../dossiers/ :
# - rapport-liens-videos.csv : inventaire complet, réécrit à chaque lancement.
# - liens-videos-a-completer.csv : uniquement les vidéos sans lien, à compléter
#   puis importer avec importer-liens-videos-csv.command.
set -e
setopt null_glob extended_glob
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

OUTILS_DIR="${0:A:h}"
DOSSIERS_DIR="${OUTILS_DIR:h:h}/dossiers"
REPORT_FILE="${DOSSIERS_DIR}/rapport-liens-videos.csv"
IMPORT_FILE="${DOSSIERS_DIR}/liens-videos-a-completer.csv"

if [[ ! -d "$DOSSIERS_DIR" ]]; then
  print -u2 "Dossier introuvable : $DOSSIERS_DIR"
  exit 1
fi

total=0
configured=0
missing=0
total_size_bytes=0

csv_escape() {
  local value="${1//\"/\"\"}"
  print -r -- "\"${value}\""
}

header='"Thème","Dossier","Nom exact de la vidéo","Lien Google Drive","Taille en Mo","État"'
print "$header" > "$REPORT_FILE"
print "$header" > "$IMPORT_FILE"

for category_dir in "$DOSSIERS_DIR"/*(/N); do
  category_name="${category_dir:t}"
  [[ "$category_name" == "heic" || "$category_name" == "videos" ]] && continue
  for folder_dir in "$category_dir"/*(/N); do
    folder_name="${folder_dir:t}"
    links_file="${folder_dir}/video-urls.txt"
    folder_videos=()
    for video_file in "$folder_dir"/*.(#i)(mp4|mov|m4v|webm|mts)(.N); do
      folder_videos+=("$video_file")
    done
    (( ${#folder_videos} == 0 )) && continue

    for video_file in "${folder_videos[@]}"; do
      video_name="${video_file:t}"
      size_bytes="$(stat -f '%z' "$video_file")"
      size_mo="$(awk -v bytes="$size_bytes" 'BEGIN { printf "%.2f", bytes / 1024 / 1024 }')"
      link=""
      if [[ -f "$links_file" ]]; then
        link="$(VIDEO_NAME="$video_name" perl -ne 'if (/^\Q$ENV{VIDEO_NAME}\E\s*\|\s*(https?:\/\/\S+)/) { print $1; exit }' "$links_file")"
      fi
      (( total += 1 ))
      (( total_size_bytes += size_bytes ))
      if [[ -n "$link" ]]; then
        (( configured += 1 ))
        link_status="Configuré"
      else
        (( missing += 1 ))
        link_status="À compléter"
      fi
      row="$(csv_escape "$category_name"),$(csv_escape "$folder_name"),$(csv_escape "$video_name"),$(csv_escape "$link"),${size_mo},$(csv_escape "$link_status")"
      print "$row" >> "$REPORT_FILE"
      [[ -z "$link" ]] && print "$row" >> "$IMPORT_FILE"
    done
  done
done

total_size_mo="$(awk -v bytes="$total_size_bytes" 'BEGIN { printf "%.2f", bytes / 1024 / 1024 }')"
pbcopy < "$IMPORT_FILE"
print ""
print "Rapport complet : $REPORT_FILE"
print "Fichier à compléter : $IMPORT_FILE"
print "Le fichier à compléter est aussi copié dans le presse-papiers."
print "Vidéos trouvées : ${total} | Liens configurés : ${configured} | Liens manquants : ${missing} | Taille totale : ${total_size_mo} Mo"
print ""
read "?Appuyez sur Entree pour fermer cette fenetre..."
