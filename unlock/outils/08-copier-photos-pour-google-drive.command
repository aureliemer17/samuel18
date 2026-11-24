#!/bin/zsh

# Copie les photos dans ../dossiers/photos/ avec l'arborescence d'archives,
# afin de déposer ce dossier dans Google Drive sans déplacer les originaux.
set -e
setopt null_glob extended_glob
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

OUTILS_DIR="${0:A:h}"
DOSSIERS_DIR="${OUTILS_DIR:h:h}/dossiers"
PHOTOS_DIR="${DOSSIERS_DIR}/photos"

if [[ ! -d "$DOSSIERS_DIR" ]]; then
  print -u2 "Dossier introuvable : $DOSSIERS_DIR"
  exit 1
fi

copied=0
updated=0

for category_dir in "$DOSSIERS_DIR"/*(/N); do
  category_name="${category_dir:t}"
  [[ "$category_name" == "heic" || "$category_name" == "videos" || "$category_name" == "pdf-images" || "$category_name" == "photos" ]] && continue
  for folder_dir in "$category_dir"/*(/N); do
    folder_name="${folder_dir:t}"
    for photo_file in "$folder_dir"/*.(#i)(jpg|jpeg|png|gif|webp|avif)(.N); do
      destination_dir="${PHOTOS_DIR}/${category_name}/${folder_name}"
      destination_file="${destination_dir}/${photo_file:t}"
      mkdir -p "$destination_dir"
      if [[ ! -f "$destination_file" ]]; then
        cp -p "$photo_file" "$destination_file"
        print "Copié : ${category_name}/${folder_name}/${photo_file:t}"
        (( copied += 1 ))
      elif [[ "$photo_file" -nt "$destination_file" ]]; then
        cp -p "$photo_file" "$destination_file"
        print "Mis à jour : ${category_name}/${folder_name}/${photo_file:t}"
        (( updated += 1 ))
      fi
    done
  done
done

print ""
print "Photos nouvelles : ${copied} | Photos mises à jour : ${updated}"
print "Dossier prêt pour Google Drive : ${PHOTOS_DIR}"
print ""
read "?Appuyez sur Entree pour fermer cette fenetre..."
