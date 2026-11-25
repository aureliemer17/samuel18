#!/bin/zsh

# Prepare les photos et videos nouvelles/modifiees dans une seule arborescence
# a deposer manuellement dans Drive. Les originaux restent intacts.
set -e
setopt null_glob extended_glob
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

OUTILS_DIR="${0:A:h}"
DOSSIERS_DIR="${OUTILS_DIR:h:h}/dossiers"
WORK_DIR="${DOSSIERS_DIR}/travail/drive-a-deposer"
REPORT_DIR="${DOSSIERS_DIR}/rapports"
REPORT_FILE="${REPORT_DIR}/drive-a-deposer.csv"
mkdir -p "$WORK_DIR" "$REPORT_DIR"
print '"Type","Theme","Dossier","Fichier","Action"' > "$REPORT_FILE"

copied=0
for category_dir in "$DOSSIERS_DIR"/*(/N); do
  category="${category_dir:t}"
  [[ "$category" == (heic|videos|photos|pdf-images|travail|rapports|drive-imports) ]] && continue
  for folder_dir in "$category_dir"/*(/N); do
    folder="${folder_dir:t}"
    for media in "$folder_dir"/*.(#i)(jpg|jpeg|png|gif|webp|avif|mp4|mov|m4v|webm|mts)(.N); do
      destination="$WORK_DIR/$category/$folder/${media:t}"
      if [[ ! -f "$destination" || "$media" -nt "$destination" ]]; then
        mkdir -p "${destination:h}"
        cp -p "$media" "$destination"
        extension="${media:e:l}"
        [[ "$extension" == (mp4|mov|m4v|webm|mts) ]] && type="Video" || type="Photo"
        print "\"$type\",\"$category\",\"$folder\",\"${media:t}\",\"A deposer\"" >> "$REPORT_FILE"
        (( copied += 1 ))
      fi
    done
  done
done
print "Medias prepares : $copied"
print "Deposez le contenu de : $WORK_DIR"
print "Rapport : $REPORT_FILE"
read "?Appuyez sur Entree pour fermer cette fenetre..."
