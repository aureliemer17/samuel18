#!/bin/zsh

# Exporte l'arborescence exacte des archives pour la transmettre à une IA.
# Le résultat est enregistré dans ../dossiers/arborescence-archives.txt
# et copié dans le presse-papiers macOS.
set -e
setopt null_glob extended_glob
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

OUTILS_DIR="${0:A:h}"
DOSSIERS_DIR="${OUTILS_DIR:h:h}/dossiers"
OUTPUT_FILE="${DOSSIERS_DIR}/arborescence-archives.txt"

if [[ ! -d "$DOSSIERS_DIR" ]]; then
  print -u2 "Dossier introuvable : $DOSSIERS_DIR"
  exit 1
fi

{
  print "ARBORESCENCE DES ARCHIVES"
  print "Racine locale : ${DOSSIERS_DIR}"
  print ""
  print "Les noms de répertoires ci-dessous doivent être utilisés exactement."
  print "Les dossiers d'archives suivent le format : ROMAIN-LETTRE-CHIFFRE - Titre."
  print ""
  print "dossiers/"

  for category_dir in "$DOSSIERS_DIR"/*(/N); do
    [[ "${category_dir:t}" == "heic" || "${category_dir:t}" == "videos" || "${category_dir:t}" == "pdf-images" ]] && continue
    print "├── ${category_dir:t}/"
    for folder_dir in "$category_dir"/*(/N); do
      print "│   ├── ${folder_dir:t}/"
      files=("$folder_dir"/**/*(.N))
      if (( ${#files} == 0 )); then
        print "│   │   └── (vide)"
        continue
      fi
      for archive_file in "${files[@]}"; do
        relative_path="${archive_file#$folder_dir/}"
        print "│   │   ├── ${relative_path}"
      done
    done
  done
} > "$OUTPUT_FILE"

print ""
print "Arborescence enregistrée : $OUTPUT_FILE"
print "L'arborescence est aussi copiée dans le presse-papiers."
print ""
read "?Appuyez sur Entree pour fermer cette fenetre..."
