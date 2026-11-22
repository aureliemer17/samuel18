#!/bin/zsh

# Importe les liens Google Drive renseignés dans
# ../dossiers/liens-videos-a-completer.csv.
# Chaque ligne non vide est écrite dans le video-urls.txt du bon dossier.
set -e
setopt null_glob
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

OUTILS_DIR="${0:A:h}"
DOSSIERS_DIR="${OUTILS_DIR:h:h}/dossiers"
CSV_FILE="${DOSSIERS_DIR}/liens-videos-a-completer.csv"

if [[ ! -f "$CSV_FILE" ]]; then
  print -u2 "Tableau introuvable : $CSV_FILE"
  print -u2 "Lancez d'abord 02-verifier-liens-videos.command."
  exit 1
fi

imported=0
skipped=0

while IFS=$'\t' read -r category_name folder_name video_name link; do
  [[ -z "$link" ]] && { (( skipped += 1 )); continue; }
  if [[ ! "$link" =~ '^https?://' ]]; then
    print "Ignoré (lien invalide) : ${category_name}/${folder_name}/${video_name}"
    (( skipped += 1 ))
    continue
  fi
  folder_dir="${DOSSIERS_DIR}/${category_name}/${folder_name}"
  if [[ ! -d "$folder_dir" ]]; then
    print "Ignoré (dossier introuvable) : ${folder_dir}"
    (( skipped += 1 ))
    continue
  fi
  links_file="${folder_dir}/video-urls.txt"
  temp_file="$(mktemp)"
  if [[ -f "$links_file" ]]; then
    VIDEO_NAME="$video_name" perl -ne 'print unless /^\Q$ENV{VIDEO_NAME}\E\s*\|/' "$links_file" > "$temp_file"
  fi
  print -r -- "${video_name} | ${link}" >> "$temp_file"
  mv "$temp_file" "$links_file"
  print "Importé : ${category_name}/${folder_name}/${video_name}"
  (( imported += 1 ))
done < <(perl -MEncode=decode -ne '
  next if $. == 1;
  my @fields;
  while (/\G(?:\A|,)(?:"((?:[^"]|"")*)"|([^,]*))/gc) {
    my $value = defined $1 ? $1 : $2;
    $value =~ s/""/"/g;
    push @fields, $value;
  }
  print join("\t", @fields[0..3]), "\n" if @fields >= 4;
' "$CSV_FILE")

print ""
print "Liens importés : ${imported} | Lignes ignorées : ${skipped}"
print "Lancez ensuite 04-mettre-a-jour-archives.command."
print ""
read "?Appuyez sur Entree pour fermer cette fenetre..."
