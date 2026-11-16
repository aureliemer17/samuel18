#!/bin/zsh

# Génère la liste des archives sans Node.js.
# Requiert seulement zsh et perl, fournis avec macOS.
set -e
setopt null_glob

OUTILS_DIR="${0:A:h}"
UNLOCK_DIR="${OUTILS_DIR:h}"
DOSSIERS_DIR="${UNLOCK_DIR:h}/dossiers"
CONFIG_FILE="${UNLOCK_DIR}/config/archive-config.js"
BLOCK_FILE="$(mktemp)"

cleanup() {
  rm -f "$BLOCK_FILE"
}
trap cleanup EXIT

if [[ ! -d "$DOSSIERS_DIR" ]]; then
  print -u2 "Dossier introuvable : $DOSSIERS_DIR"
  exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
  print -u2 "Configuration introuvable : $CONFIG_FILE"
  exit 1
fi

json() {
  printf '%s' "$1" | perl -MJSON::PP=encode_json -0777 -ne 'print encode_json($_)'
}

clean_title() {
  perl -pe 's/<[^>]*>/ /g' "$1" | tr '\n' ' ' | tr -s ' ' | sed 's/^ *//; s/ *$//'
}

source_path() {
  printf '../../dossiers/%s/%s/%s' "$1" "$2" "$3"
}

print '  // BEGIN GENERATED MEDIA - généré par mettre-a-jour-archives-sans-node.command depuis ../dossiers.' > "$BLOCK_FILE"
print '  media: {' >> "$BLOCK_FILE"

count=0
for category_dir in "$DOSSIERS_DIR"/*(/); do
  category_name="${category_dir:t}"
  for folder_dir in "$category_dir"/*(/); do
    code="${folder_dir:t}"
    if [[ ! "$code" =~ '^(I|II|III|IV|V|VI|VII)-[A-J]-[1-8]$' ]]; then
      print "Ignoré : ${category_name}/${code} ne respecte pas le format I-A-1."
      continue
    fi

    title=""
    for title_file in "$folder_dir/titre.html" "$folder_dir/titre.htm" "$folder_dir/titre.txt"; do
      if [[ -f "$title_file" ]]; then
        title="$(clean_title "$title_file")"
        break
      fi
    done
    [[ -z "$title" ]] && title="Dossier $code"

    instruction=""
    for instruction_file in "$folder_dir/instruction.html" "$folder_dir/instruction.htm" "$folder_dir/instruction.txt"; do
      if [[ -f "$instruction_file" ]]; then
        instruction="$(source_path "$category_name" "$code" "${instruction_file:t}")"
        break
      fi
    done

    print "    $(json "$code"): {" >> "$BLOCK_FILE"
    print "      title: $(json "$title")," >> "$BLOCK_FILE"
    [[ -n "$instruction" ]] && print "      instruction: $(json "$instruction")," >> "$BLOCK_FILE"
    print '      items: [' >> "$BLOCK_FILE"

    for media_file in "$folder_dir"/*(.N); do
      name="${media_file:t}"
      case "$name" in
        .DS_Store|README.md|titre.txt|titre.html|titre.htm|instruction.txt|instruction.html|instruction.htm) continue ;;
      esac

      extension="${name:e:l}"
      case "$extension" in
        jpg|jpeg|png|gif|webp|avif) type="image" ;;
        mp4|mov|m4v|webm) type="video" ;;
        html|htm|txt|pdf) type="document" ;;
        *) print "Ignoré (${code}) : extension non prise en charge pour ${name}"; continue ;;
      esac

      media_title="${name:r}"
      media_title="${media_title//[-_]/ }"
      source="$(source_path "$category_name" "$code" "$name")"
      line="        { title: $(json "$media_title"), type: $(json "$type"), source: $(json "$source")"
      if [[ "$type" == "image" || "$type" == "video" ]]; then
        created="$(LC_ALL=fr_FR.UTF-8 stat -f '%SB' -t '%d %B %Y' "$media_file")"
        line+=", createdAt: $(json "$created")"
      fi
      print "${line} }," >> "$BLOCK_FILE"
    done

    print '      ],' >> "$BLOCK_FILE"
    print '    },' >> "$BLOCK_FILE"
    (( count += 1 ))
  done
done

print '  },' >> "$BLOCK_FILE"
print '  // END GENERATED MEDIA' >> "$BLOCK_FILE"

BLOCK_FILE="$BLOCK_FILE" perl -0777 -i -pe '
  BEGIN {
    open my $fh, "<", $ENV{BLOCK_FILE} or die "Impossible de lire le bloc généré: $!";
    local $/;
    $replacement = <$fh>;
  }
  s{  // BEGIN GENERATED MEDIA[^\n]*\n[\s\S]*?  // END GENERATED MEDIA}{$replacement}s
    or die "Bloc généré introuvable dans archive-config.js\n";
' "$CONFIG_FILE"

print ""
print "Configuration générée : ${count} dossier(s) d'archive trouvé(s)."
print ""
read "?Appuyez sur Entree pour fermer cette fenetre..."
