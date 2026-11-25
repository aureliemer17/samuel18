#!/bin/zsh

# Copie les anecdotes, instructions et documents légers dans le site publié.
# Les photos et vidéos restent sur Google Drive ; les originaux locaux restent
# intacts dans ../dossiers.
set -e
setopt null_glob extended_glob
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

OUTILS_DIR="${0:A:h}"
UNLOCK_DIR="${OUTILS_DIR:h}"
DOSSIERS_DIR="${UNLOCK_DIR:h}/dossiers"
CONTENT_DIR="${UNLOCK_DIR}/contenu-archives"

if [[ ! -d "$DOSSIERS_DIR" ]]; then
  print -u2 "Dossier introuvable : $DOSSIERS_DIR"
  exit 1
fi

copied=0

# contenu-archives is generated output. Rebuild it so renamed or deleted
# dossiers cannot leave stale published paths behind.
rm -rf "$CONTENT_DIR"
mkdir -p "$CONTENT_DIR"

for category_dir in "$DOSSIERS_DIR"/*(/N); do
  category_name="${category_dir:t}"
  [[ "$category_name" == "heic" || "$category_name" == "videos" || "$category_name" == "pdf-images" || "$category_name" == "photos" || "$category_name" == "travail" || "$category_name" == "rapports" || "$category_name" == "drive-imports" ]] && continue
  for folder_dir in "$category_dir"/*(/N); do
    folder_name="${folder_dir:t}"
    destination_dir="${CONTENT_DIR}/${category_name}/${folder_name}"
    for content_file in "$folder_dir"/*.(#i)(html|htm|txt|pdf)(.N); do
      file_name="${content_file:t}"
      case "$file_name" in
        titre.txt|titre.html|titre.htm|video-urls.txt|video-affichage.txt) continue ;;
      esac
      destination_file="${destination_dir}/${file_name}"
      mkdir -p "$destination_dir"
      if [[ ! -f "$destination_file" ]]; then
        cp -p "$content_file" "$destination_file"
        print "Copié : ${category_name}/${folder_name}/${file_name}"
        (( copied += 1 ))
      fi
    done
  done
done

print ""
print "Documents publiés : ${copied}"
print "Contenu publié : ${CONTENT_DIR}"
print "Ajoutez ensuite ce dossier à Git avec :"
print "git add -A unlock/contenu-archives"
print ""
read "?Appuyez sur Entree pour fermer cette fenetre..."
