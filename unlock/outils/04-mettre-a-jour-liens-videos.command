#!/bin/zsh

# Met à jour seulement les liens Google Drive des vidéos. Aucun média n'est
# converti, déplacé ou réanalysé : cette commande est rapide et sans Swift.
set -e
setopt null_glob extended_glob
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

OUTILS_DIR="${0:A:h}"
UNLOCK_DIR="${OUTILS_DIR:h}"
DOSSIERS_DIR="${UNLOCK_DIR:h}/dossiers"
CONFIG_FILE="${UNLOCK_DIR}/config/archive-video-config.local.js"
TEMP_FILE="$(mktemp)"

cleanup() {
  rm -f "$TEMP_FILE"
}
trap cleanup EXIT

if [[ ! -d "$DOSSIERS_DIR" ]]; then
  print -u2 "Dossier introuvable : $DOSSIERS_DIR"
  exit 1
fi

url_encode() {
  printf '%s' "$1" | iconv -f UTF-8 -t UTF-8-MAC | perl -0777 -ne '
    $value = $_;
    $value =~ s{([^A-Za-z0-9\-._~/])}{sprintf("%%%02X", ord($1))}ge;
    print $value;
  '
}

source_path() {
  printf '../../dossiers/%s/%s/%s' "$(url_encode "$1")" "$(url_encode "$2")" "$(url_encode "$3")"
}

json() {
  printf '%s' "$1" | perl -MEncode=decode -MJSON::PP=encode_json -0777 -ne 'print encode_json(decode("UTF-8", $_))'
}

print '// Généré par 04-mettre-a-jour-liens-videos.command depuis ../dossiers.' > "$TEMP_FILE"
print 'window.ARCHIVE_VIDEO_LINKS = {' >> "$TEMP_FILE"
count=0

for category_dir in "$DOSSIERS_DIR"/*(/N); do
  category_name="${category_dir:t}"
  [[ "$category_name" == "heic" || "$category_name" == "videos" ]] && continue
  for folder_dir in "$category_dir"/*(/N); do
    folder_name="${folder_dir:t}"
    links_file="${folder_dir}/video-urls.txt"
    [[ -f "$links_file" ]] || continue
    for video_file in "$folder_dir"/*.(#i)(mp4|mov|m4v|webm|mts)(.N); do
      video_name="${video_file:t}"
      video_url="$(VIDEO_NAME="$video_name" perl -ne 'if (/^\Q$ENV{VIDEO_NAME}\E\s*\|\s*(https?:\/\/\S+)/) { print $1; exit }' "$links_file")"
      [[ -z "$video_url" ]] && continue
      print "  $(json "$(source_path "$category_name" "$folder_name" "$video_name")"): $(json "$video_url")," >> "$TEMP_FILE"
      print "Lien mis à jour : ${category_name}/${folder_name}/${video_name}"
      (( count += 1 ))
    done
  done
done

print '};' >> "$TEMP_FILE"
mv "$TEMP_FILE" "$CONFIG_FILE"

print ""
print "Configuration vidéo générée : ${count} lien(s)."
print "Fichier mis à jour : ${CONFIG_FILE}"
print "Les liens seront cliquables dans le livret et les PDF numériques."
print ""
read "?Appuyez sur Entree pour fermer cette fenetre..."
