#!/bin/zsh

# Controle la liste blanche publiee et bloque les medias accidentels sous unlock.
set -e
OUTILS_DIR="${0:A:h}"
ROOT_DIR="${OUTILS_DIR:h:h}"
cd "$ROOT_DIR"
forbidden=("unlock/**/*.(jpg|jpeg|png|gif|webp|avif|mp4|mov|m4v|webm|mts)(N)" )
allowed_assets=("unlock/assets/bureau-majorite.png" "unlock/assets/dossier.png" "unlock/assets/icon-192.png" "unlock/assets/icon-512.png" "unlock/assets/index_background.png" "unlock/assets/index_background_mobile.png" "unlock/assets/indice.png" "unlock/assets/machine.png")
bad=0
for file in unlock/**/*.(jpg|jpeg|png|gif|webp|avif|mp4|mov|m4v|webm|mts)(N); do
  [[ "$file" == unlock/contenu-archives/* ]] && { print -u2 "Interdit : media dans contenu-archives : $file"; bad=1; continue; }
  [[ " ${allowed_assets[*]} " == *" $file "* ]] || { print -u2 "Interdit : media non autorise sous unlock : $file"; bad=1; }
done
print ""
print "Fichiers modifies/versionnables :"
git status --short
(( bad == 0 )) || { print -u2 "Publication bloquee."; exit 1; }
print "Verification reussie : aucun media d'archive n'est publie dans unlock."
