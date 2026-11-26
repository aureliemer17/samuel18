#!/bin/zsh

# Reconstruit les video-urls.txt depuis le rapport CSV. Les noms macOS, les
# apostrophes et les underscores sont rapproches avant toute ecriture.
set -e
setopt null_glob extendedglob
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

OUTILS_DIR="${0:A:h}"
DOSSIERS_DIR="${OUTILS_DIR:h:h}/dossiers"
CSV_FILE="${DOSSIERS_DIR}/rapport-liens-videos.csv"
PLAN_FILE="${DOSSIERS_DIR}/plan-restauration-liens-videos.csv"
PLAN_TSV="$(mktemp)"
trap 'rm -f "$PLAN_TSV"' EXIT

[[ -d "$DOSSIERS_DIR" ]] || { print -u2 "Dossier introuvable : $DOSSIERS_DIR"; exit 1; }
[[ -f "$CSV_FILE" ]] || { print -u2 "CSV introuvable : $CSV_FILE"; exit 1; }

normalise() {
  printf '%s' "$1" | perl -MUnicode::Normalize=NFD -CSDA -0777 -pe '
    s/^\x{FEFF}//; s/\r$//; s/^\s+|\s+$//g; s/\x{00A0}/ /g; $_ = NFD($_);
    s/[\x{2018}\x{2019}\x{02BC}_'"'"']//g; s/\s+/ /g; $_ = lc($_);
  '
}

resolve_directory() {
  local parent="$1" expected="$2" candidate wanted="$(normalise "$2")"
  for candidate in "$parent"/*(/N); do
    [[ "$(normalise "${candidate:t}")" == "$wanted" ]] && { print -r -- "$candidate"; return 0; }
  done
  return 1
}

resolve_video() {
  local folder="$1" expected="$2" candidate wanted="$(normalise "$2")"
  for candidate in "$folder"/*.(#i)(mp4|mov|m4v|webm|mts)(.N); do
    [[ "$(normalise "${candidate:t}")" == "$wanted" ]] && { print -r -- "$candidate"; return 0; }
  done
  return 1
}

csv_escape() { local value="${1//\"/\"\"}"; print -r -- "\"${value}\""; }
separator="$(perl -MEncode=decode -ne 'if ($. == 1) { $line = $_; $line =~ s/^\x{FEFF}//; print(index($line, ";") > index($line, ",") ? ";" : ","); exit }' "$CSV_FILE")"

matched=0
missing=0
print '"Thème","Dossier CSV","Vidéo CSV","Vidéo locale retenue","Lien Google Drive","État"' > "$PLAN_FILE"

while IFS=$'\t' read -r category folder video url; do
  [[ -n "$url" && "$url" =~ '^https?://' ]] || continue
  category_dir="$(resolve_directory "$DOSSIERS_DIR" "$category" 2>/dev/null)" || {
    print "$(csv_escape "$category"),$(csv_escape "$folder"),$(csv_escape "$video"),""","$(csv_escape "$url"),"Thème introuvable"" >> "$PLAN_FILE"
    (( missing += 1 )); continue
  }
  folder_dir="$(resolve_directory "$category_dir" "$folder" 2>/dev/null)" || {
    print "$(csv_escape "$category"),$(csv_escape "$folder"),$(csv_escape "$video"),""","$(csv_escape "$url"),"Dossier introuvable"" >> "$PLAN_FILE"
    (( missing += 1 )); continue
  }
  video_file="$(resolve_video "$folder_dir" "$video" 2>/dev/null)" || {
    print "$(csv_escape "$category"),$(csv_escape "$folder"),$(csv_escape "$video"),""","$(csv_escape "$url"),"Vidéo introuvable"" >> "$PLAN_FILE"
    (( missing += 1 )); continue
  }
  print -r -- "${folder_dir}"$'\t'"${video_file:t}"$'\t'"${url}" >> "$PLAN_TSV"
  print "$(csv_escape "$category"),$(csv_escape "$folder"),$(csv_escape "$video"),$(csv_escape "${video_file:t}"),$(csv_escape "$url"),"Prêt à restaurer"" >> "$PLAN_FILE"
  (( matched += 1 ))
done < <(SEPARATOR="$separator" perl -MEncode=decode -ne '
  next if $. == 1; $line = $_; $line =~ s/\r?\n$//; next if $line =~ /^\s*$/;
  my $separator = $ENV{SEPARATOR}; my @fields;
  while ($line =~ /\G(?:\A|\Q$separator\E)(?:"((?:[^"]|"")*)"|([^\Q$separator\E]*))/gc) {
    my $value = defined $1 ? $1 : $2; $value =~ s/""/"/g; $value =~ s/^\s+|\s+$//g; push @fields, $value;
  }
  next unless @fields >= 4; print join("\t", @fields[0..3]), "\n";
' "$CSV_FILE")

print ""
print "Plan créé : $PLAN_FILE"
print "Liens prêts à restaurer : $matched | Éléments non rapprochés : $missing"
print "Le plan indique les fichiers locaux retenus, y compris les rapprochements apostrophe/underscore."
(( matched > 0 )) || { read "?Appuyez sur Entree pour fermer cette fenêtre..."; exit 0; }
read "confirm?Remplacer les video-urls.txt concernés avec ce plan ? [oui/N] "
[[ "$confirm" == "oui" ]] || { print "Aucun fichier modifié."; exit 0; }

typeset -A temporary_files
while IFS=$'\t' read -r folder_dir video_name url; do
  target="${folder_dir}/video-urls.txt"
  if [[ -z "${temporary_files[$target]-}" ]]; then temporary_files[$target]="$(mktemp "${folder_dir}/.video-urls.XXXXXX")"; fi
  print -r -- "${video_name} | ${url}" >> "${temporary_files[$target]}"
done < "$PLAN_TSV"

for target temporary in ${(kv)temporary_files}; do
  mv "$temporary" "$target"
  print "Restauré : $target"
done

print ""
print "Restauration terminée. Lancez ensuite 04-mettre-a-jour-liens-videos.command pour régénérer archive-video-config.local.js."
read "?Appuyez sur Entree pour fermer cette fenêtre..."
