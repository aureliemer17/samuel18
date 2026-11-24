#!/bin/zsh

# Importe le CSV créé par google-drive-inventorier-photos.gs. Il génère une
# configuration versionnable pour afficher les photos depuis Drive sur téléphone.
set -e
setopt null_glob extended_glob
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

OUTILS_DIR="${0:A:h}"
UNLOCK_DIR="${OUTILS_DIR:h}"
DOSSIERS_DIR="${UNLOCK_DIR:h}/dossiers"
CSV_FILE="${DOSSIERS_DIR}/photos-google-drive-inventaire.csv"
CONFIG_FILE="${UNLOCK_DIR}/config/archive-photo-drive-config.js"
TEMP_FILE="$(mktemp)"

cleanup() {
  rm -f "$TEMP_FILE"
}
trap cleanup EXIT

if [[ ! -f "$CSV_FILE" ]]; then
  print -u2 "CSV Google Drive introuvable : $CSV_FILE"
  print -u2 "Téléchargez photos-google-drive-inventaire.csv depuis le dossier Drive test et placez-le ici."
  exit 1
fi

url_encode() {
  # APFS uses decomposed UTF-8 names; match the URL form generated locally.
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

rows=()
detected=0
blank=0
malformed=0
separator="$(perl -MEncode=decode -ne 'if ($. == 1) { $line = $_; $line =~ s/^\x{FEFF}//; print(index($line, ";") > index($line, ",") ? ";" : ","); exit }' "$CSV_FILE")"

while IFS=$'\t' read -r row_type category_name folder_name photo_name drive_id drive_link; do
  case "$row_type" in
    DATA)
      rows+=("${category_name}"$'\t'"${folder_name}"$'\t'"${photo_name}"$'\t'"${drive_id}"$'\t'"${drive_link}")
      (( detected += 1 ))
      ;;
    BLANK) (( blank += 1 )) ;;
    MALFORMED) (( malformed += 1 )) ;;
  esac
done < <(SEPARATOR="$separator" perl -MEncode=decode -ne '
  next if $. == 1;
  $line = $_;
  $line =~ s/\r?\n$//;
  if ($line =~ /^\s*$/) { print "BLANK\n"; next; }
  $separator = $ENV{SEPARATOR};
  my @fields;
  while ($line =~ /\G(?:\A|\Q$separator\E)(?:"((?:[^"]|"")*)"|([^\Q$separator\E]*))/gc) {
    my $value = defined $1 ? $1 : $2;
    $value =~ s/""/"/g;
    $value =~ s/^\s+|\s+$//g;
    push @fields, $value;
  }
  if (@fields < 5) { print "MALFORMED\n"; next; }
  print "DATA\t", join("\t", @fields[0, 1, 2, 3, 4]), "\n";
' "$CSV_FILE")

print "CSV trouvé : ${CSV_FILE}"
print "Séparateur détecté : ${separator} | Photos lues : ${detected} | Lignes vides : ${blank} | Mal formées : ${malformed}"

if (( detected == 0 )); then
  print -u2 "Aucune photo importable. Vérifiez que le CSV téléchargé vient bien du script Google Drive."
  exit 1
fi

print '// Généré par 09-importer-liens-photos-google-drive.command.' > "$TEMP_FILE"
print 'window.ARCHIVE_PHOTO_DRIVE_LINKS = {' >> "$TEMP_FILE"
imported=0
skipped=0
for row in "${rows[@]}"; do
  IFS=$'\t' read -r category_name folder_name photo_name drive_id drive_link <<< "$row"
  if [[ ! "$drive_id" =~ '^[A-Za-z0-9_-]+$' ]]; then
    print "Ignoré (ID Drive invalide) : ${category_name}/${folder_name}/${photo_name}"
    (( skipped += 1 ))
    continue
  fi
  source="$(source_path "$category_name" "$folder_name" "$photo_name")"
  # This URL serves an image file rather than Drive's HTML preview page.
  image_url="https://drive.google.com/thumbnail?id=${drive_id}&sz=w2000"
  print "  $(json "$source"): $(json "$image_url")," >> "$TEMP_FILE"
  (( imported += 1 ))
done
print '};' >> "$TEMP_FILE"
mv "$TEMP_FILE" "$CONFIG_FILE"

print ""
print "Configuration photos créée : ${CONFIG_FILE}"
print "Photos importées : ${imported} | Ignorées : ${skipped}"
print "Avant le test sur téléphone, vérifiez que les photos Drive sont partagées avec toute personne disposant du lien."
print ""
read "?Appuyez sur Entree pour fermer cette fenetre..."
