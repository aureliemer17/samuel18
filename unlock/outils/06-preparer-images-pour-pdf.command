#!/bin/zsh

# Crée des copies JPEG légères des photos pour les exports PDF, sans toucher
# aux originaux. Requiert seulement sips, fourni avec macOS.
set -e
setopt null_glob extended_glob
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

OUTILS_DIR="${0:A:h}"
DOSSIERS_DIR="${OUTILS_DIR:h:h}/dossiers"
PDF_IMAGES_DIR="${DOSSIERS_DIR}/pdf-images"
MAX_PIXELS=1800
JPEG_QUALITY=78

if [[ ! -d "$DOSSIERS_DIR" ]]; then
  print -u2 "Dossier introuvable : $DOSSIERS_DIR"
  exit 1
fi

created=0
updated=0
skipped=0

for category_dir in "$DOSSIERS_DIR"/*(/N); do
  category_name="${category_dir:t}"
  [[ "$category_name" == "heic" || "$category_name" == "videos" || "$category_name" == "pdf-images" || "$category_name" == "photos" || "$category_name" == "travail" || "$category_name" == "rapports" || "$category_name" == "drive-imports" ]] && continue
  for folder_dir in "$category_dir"/*(/N); do
    folder_name="${folder_dir:t}"
    for image_file in "$folder_dir"/*.(#i)(jpg|jpeg|png|gif|webp|avif)(.N); do
      destination_dir="${PDF_IMAGES_DIR}/${category_name}/${folder_name}"
      destination_file="${destination_dir}/${image_file:r:t}.jpg"
      existed=false
      [[ -f "$destination_file" ]] && existed=true
      if [[ -f "$destination_file" && "$destination_file" -nt "$image_file" ]]; then
        (( skipped += 1 ))
        continue
      fi
      mkdir -p "$destination_dir"
      sips -s format jpeg -s formatOptions "$JPEG_QUALITY" -Z "$MAX_PIXELS" "$image_file" --out "$destination_file" >/dev/null
      if [[ -f "$destination_file" ]]; then
        if [[ "$existed" == true ]]; then
          print "Mis à jour : ${category_name}/${folder_name}/${destination_file:t}"
          (( updated += 1 ))
        else
          print "Créé : ${category_name}/${folder_name}/${destination_file:t}"
          (( created += 1 ))
        fi
      fi
    done
  done
done

print ""
print "Images PDF créées : ${created} | Mises à jour : ${updated} | Déjà à jour : ${skipped}"
print "Dossier : ${PDF_IMAGES_DIR}"
print "Ouvrez ensuite decouvertes.html?admin=1 et utilisez PDF COMPLET."
print ""
read "?Appuyez sur Entree pour fermer cette fenetre..."
