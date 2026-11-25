#!/bin/zsh

# Point d'entree unique. Les originaux restent dans ../../dossiers et ne sont
# jamais ajoutes a Git. Les sorties publiees sont verifiees avant publication.
set -e
setopt null_glob extended_glob
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

OUTILS_DIR="${0:A:h}"
UNLOCK_DIR="${OUTILS_DIR:h}"
ROOT_DIR="${UNLOCK_DIR:h}"
DOSSIERS_DIR="${ROOT_DIR}/dossiers"

usage() {
  print ""
  print "GESTION DES ARCHIVES"
  print "1. Regenerer le site local (sans inventaire Google Drive)"
  print "2. Ajouter ou modifier un souvenir"
  print "3. Preparer les medias pour Google Drive"
  print "4. Importer l'inventaire Google Drive"
  print "5. Verifier avant publication Git"
  print "6. Codes et enigmes / codes d'archives"
  print "7. Exporter l'arborescence"
  print "8. Appliquer les dates de prise de vue aux photos"
  print "0. Quitter"
  print ""
}

run_full() {
  print ""
  print "=== REGENERATION DU SITE LOCAL ==="
  print "Les photos Drive ne sont pas mises a jour ici."
  print "Apres un renommage Drive, lancez Apps Script inventorierMedias,"
  print "telechargez le CSV puis choisissez l'action 4."
  print ""
  print "[1/4] Analyse des souvenirs et generation de la configuration..."
  printf '\n' | "$OUTILS_DIR/05-mettre-a-jour-archives.command"
  print ""
  print "[2/4] Generation des liens video..."
  printf '\n' | "$OUTILS_DIR/04-mettre-a-jour-liens-videos.command"
  print ""
  print "[3/4] Publication des anecdotes, instructions et documents..."
  printf '\n' | "$OUTILS_DIR/10-copier-contenu-archives-pour-site.command"
  print ""
  print "[4/4] Preparation des images legeres pour les exports PDF..."
  printf '\n' | "$OUTILS_DIR/06-preparer-images-pour-pdf.command"
  print ""
  print "=== REGENERATION LOCALE TERMINEE ==="
}

add_or_update() {
  print "Dossiers disponibles :"
  select folder in "$DOSSIERS_DIR"/*/*(/N); do
    [[ -n "$folder" ]] || return
    print "Type : 1) photo  2) video  3) titre  4) anecdote  5) instruction  6) document"
    read "choice?Choix : "
    case "$choice" in
      1|2|6)
        read "file?Glissez le fichier ici puis Entree : "
        file="${file#\'}"; file="${file%\'}"
        [[ -f "$file" ]] || { print -u2 "Fichier introuvable."; return 1; }
        cp -p "$file" "$folder/${file:t}"
        ;;
      3) read "title?Nouveau titre : "; print -r -- "$title" > "$folder/titre.txt" ;;
      4) cp "$OUTILS_DIR/99-modele-anecdote.html" "$folder/anecdote.html"; open "$folder/anecdote.html" ;;
      5) print -r -- "" > "$folder/instruction.txt"; open "$folder/instruction.txt" ;;
      *) print -u2 "Choix invalide."; return 1 ;;
    esac
    print "Mise a jour ciblee du souvenir ${folder:t}."
    printf '\n' | "$OUTILS_DIR/05-mettre-a-jour-archives.command"
    printf '\n' | "$OUTILS_DIR/10-copier-contenu-archives-pour-site.command"
    [[ "$choice" == 1 ]] && printf '\n' | "$OUTILS_DIR/06-preparer-images-pour-pdf.command"
    [[ "$choice" == 2 ]] && printf '\n' | "$OUTILS_DIR/11-preparer-medias-pour-google-drive.command"
    return
  done
}

case "${1:-}" in
  regenerer) run_full ;;
  ajouter) add_or_update ;;
  drive-preparer) "$OUTILS_DIR/11-preparer-medias-pour-google-drive.command" ;;
  drive-importer) "$OUTILS_DIR/12-importer-inventaire-google-drive.command" ;;
  verifier) "$OUTILS_DIR/13-verifier-avant-publication.command" ;;
  enigmes) printf '\n' | "$OUTILS_DIR/14-generer-config-enigmes.command"; "$OUTILS_DIR/15-preparer-changements-codes-archives.command" ;;
  arborescence) "$OUTILS_DIR/90-exporter-arborescence-archives.command" ;;
  dates-photos) "$OUTILS_DIR/16-appliquer-dates-de-prise-de-vue.command" ;;
  "")
    usage
    read "action?Action : "
    case "$action" in
      1) run_full ;; 2) add_or_update ;; 3) "$OUTILS_DIR/11-preparer-medias-pour-google-drive.command" ;;
      4) "$OUTILS_DIR/12-importer-inventaire-google-drive.command" ;;
      5) "$OUTILS_DIR/13-verifier-avant-publication.command" ;;
      6) printf '\n' | "$OUTILS_DIR/14-generer-config-enigmes.command"; "$OUTILS_DIR/15-preparer-changements-codes-archives.command" ;;
      7) "$OUTILS_DIR/90-exporter-arborescence-archives.command" ;;
      8) "$OUTILS_DIR/16-appliquer-dates-de-prise-de-vue.command" ;; 0) exit 0 ;;
      *) print -u2 "Action invalide."; exit 1 ;;
    esac
    ;;
  *) print -u2 "Commande inconnue : $1"; exit 1 ;;
esac
