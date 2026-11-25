#!/bin/zsh

# Copie toutes les vidéos locales dans ../dossiers/videos/ en conservant
# l'arborescence des thèmes et dossiers, pour un glisser-déposer vers Google Drive.
set -e
setopt null_glob extended_glob
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

OUTILS_DIR="${0:A:h}"
DOSSIERS_DIR="${OUTILS_DIR:h:h}/dossiers"
VIDEOS_DIR="${DOSSIERS_DIR}/videos"

if [[ ! -d "$DOSSIERS_DIR" ]]; then
  print -u2 "Dossier introuvable : $DOSSIERS_DIR"
  exit 1
fi

copied=0
updated=0

for category_dir in "$DOSSIERS_DIR"/*(/N); do
  category_name="${category_dir:t}"
  [[ "$category_name" == "heic" || "$category_name" == "videos" || "$category_name" == "pdf-images" || "$category_name" == "photos" || "$category_name" == "travail" || "$category_name" == "rapports" || "$category_name" == "drive-imports" ]] && continue
  for folder_dir in "$category_dir"/*(/N); do
    folder_name="${folder_dir:t}"
    for video_file in "$folder_dir"/*.(#i)(mp4|mov|m4v|webm|mts)(.N); do
      destination_dir="${VIDEOS_DIR}/${category_name}/${folder_name}"
      destination_file="${destination_dir}/${video_file:t}"
      mkdir -p "$destination_dir"
      if [[ ! -f "$destination_file" ]]; then
        cp -p "$video_file" "$destination_file"
        print "Copié : ${category_name}/${folder_name}/${video_file:t}"
        (( copied += 1 ))
      elif [[ "$video_file" -nt "$destination_file" ]]; then
        cp -p "$video_file" "$destination_file"
        print "Mis à jour : ${category_name}/${folder_name}/${video_file:t}"
        (( updated += 1 ))
      fi
    done
  done
done

print ""
print "Vidéos nouvelles : ${copied} | Vidéos mises à jour : ${updated}"
print "Dossier prêt pour Google Drive : ${VIDEOS_DIR}"
print ""
read "?Appuyez sur Entree pour fermer cette fenetre..."
