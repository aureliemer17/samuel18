#!/bin/zsh

# Inventorie les vidéos locales et vérifie leurs liens Google Drive associés.
# Ne modifie aucun fichier. Le rapport est enregistré dans
# ../dossiers/rapport-liens-videos.txt et copié dans le presse-papiers.
set -e
setopt null_glob extended_glob
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

OUTILS_DIR="${0:A:h}"
DOSSIERS_DIR="${OUTILS_DIR:h:h}/dossiers"
REPORT_FILE="${DOSSIERS_DIR}/rapport-liens-videos.txt"

if [[ ! -d "$DOSSIERS_DIR" ]]; then
  print -u2 "Dossier introuvable : $DOSSIERS_DIR"
  exit 1
fi

total=0
configured=0
missing=0
report=""

for category_dir in "$DOSSIERS_DIR"/*(/N); do
  category_name="${category_dir:t}"
  [[ "$category_name" == "heic" ]] && continue
  for folder_dir in "$category_dir"/*(/N); do
    folder_name="${folder_dir:t}"
    links_file="${folder_dir}/video-urls.txt"
    folder_videos=()
    for video_file in "$folder_dir"/*.(#i)(mp4|mov|m4v|webm|mts)(.N); do
      folder_videos+=("$video_file")
    done
    (( ${#folder_videos} == 0 )) && continue

    report+="${category_name}/${folder_name}\n"
    for video_file in "${folder_videos[@]}"; do
      video_name="${video_file:t}"
      link=""
      if [[ -f "$links_file" ]]; then
        link="$(VIDEO_NAME="$video_name" perl -ne 'if (/^\Q$ENV{VIDEO_NAME}\E\s*\|\s*(https?:\/\/\S+)/) { print $1; exit }' "$links_file")"
      fi
      (( total += 1 ))
      if [[ -n "$link" ]]; then
        (( configured += 1 ))
        report+="  [OK] ${video_name}\n"
      else
        (( missing += 1 ))
        report+="  [MANQUANT] ${video_name}\n"
      fi
    done
    report+="\n"
  done
done

{
  print "RAPPORT DES LIENS VIDÉOS"
  print ""
  print "Vidéos trouvées : ${total}"
  print "Liens configurés : ${configured}"
  print "Liens manquants : ${missing}"
  print ""
  print "INVENTAIRE"
  print ""
  print -r -- "$report"
} > "$REPORT_FILE"

pbcopy < "$REPORT_FILE"
print ""
print "Rapport enregistré : $REPORT_FILE"
print "L'inventaire est aussi copié dans le presse-papiers."
print "Vidéos trouvées : ${total} | Liens configurés : ${configured} | Liens manquants : ${missing}"
print ""
read "?Appuyez sur Entree pour fermer cette fenetre..."
