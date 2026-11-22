#!/bin/zsh

# Génère la liste des archives sans Node.js.
# Requiert seulement zsh et perl, fournis avec macOS.
set -e
setopt null_glob extended_glob
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

OUTILS_DIR="${0:A:h}"
UNLOCK_DIR="${OUTILS_DIR:h}"
DOSSIERS_DIR="${UNLOCK_DIR:h}/dossiers"
HEIC_ARCHIVE_DIR="${DOSSIERS_DIR}/heic"
EXAMPLE_CONFIG_FILE="${UNLOCK_DIR}/config/archive-config.example.js"
CONFIG_FILE="${UNLOCK_DIR}/config/archive-config.local.js"
BLOCK_FILE="$(mktemp)"

cleanup() {
  rm -f "$BLOCK_FILE"
}
trap cleanup EXIT

if [[ ! -d "$DOSSIERS_DIR" ]]; then
  print -u2 "Dossier introuvable : $DOSSIERS_DIR"
  exit 1
fi

if [[ ! -f "$EXAMPLE_CONFIG_FILE" ]]; then
  print -u2 "Configuration exemple introuvable : $EXAMPLE_CONFIG_FILE"
  exit 1
fi

if [[ ! -f "$CONFIG_FILE" ]]; then
  cp "$EXAMPLE_CONFIG_FILE" "$CONFIG_FILE"
fi

json() {
  printf '%s' "$1" | perl -MEncode=decode -MJSON::PP=encode_json -0777 -ne 'print encode_json(decode("UTF-8", $_))'
}

clean_title() {
  perl -MEncode=decode,encode -0777 -ne 'print encode("UTF-8", (decode("UTF-8", $_) =~ s/<[^>]*>/ /gr))' "$1" | tr '\n' ' ' | tr -s ' ' | sed 's/^ *//; s/ *$//'
}

french_date() {
  local day month year
  local -a months=(janvier février mars avril mai juin juillet août septembre octobre novembre décembre)
  read -r day month year <<< "$1"
  print "${day} ${months[10#$month]} ${year}"
}

declared_height() {
  perl -0777 -ne 'print $1 if /<meta\s+[^>]*name\s*=\s*["\x27]archive-height["\x27][^>]*content\s*=\s*["\x27](\d+)["\x27][^>]*>/i || /<meta\s+[^>]*content\s*=\s*["\x27](\d+)["\x27][^>]*name\s*=\s*["\x27]archive-height["\x27][^>]*>/i' "$1"
}

source_path() {
  printf '../../dossiers/%s/%s/%s' "$(url_encode "$1")" "$(url_encode "$2")" "$(url_encode "$3")"
}

url_encode() {
  # APFS stores accented filenames in the UTF-8-MAC decomposed form.
  # Preserve that form before percent-encoding it for file:// URLs.
  printf '%s' "$1" | iconv -f UTF-8 -t UTF-8-MAC | perl -0777 -ne '
    $value = $_;
    $value =~ s{([^A-Za-z0-9\-._~/])}{sprintf("%%%02X", ord($1))}ge;
    print $value;
  '
}

print '  // BEGIN GENERATED MEDIA - généré par mettre-a-jour-archives-sans-node.command depuis ../dossiers.' > "$BLOCK_FILE"
print '  media: {' >> "$BLOCK_FILE"

count=0
for category_dir in "$DOSSIERS_DIR"/*(/); do
  category_name="${category_dir:t}"
  [[ "$category_name" == "heic" ]] && continue
  for folder_dir in "$category_dir"/*(/); do
    folder_name="${folder_dir:t}"
    if [[ "$folder_name" =~ '^((I|II|III|IV|V|VI|VII)-[A-J]-[1-8])( - .+)?$' ]]; then
      code="${match[1]}"
    else
      print "Ignoré : ${category_name}/${folder_name} ne respecte pas le format I-A-1 ou I-A-1 - Description."
      continue
    fi

    folder_title="${folder_name#${code} - }"
    if [[ "$folder_title" == "$folder_name" ]]; then
      folder_title="Dossier ${code}"
    fi

    if [[ ! -f "$folder_dir/titre.html" && ! -f "$folder_dir/titre.htm" && ! -f "$folder_dir/titre.txt" ]]; then
      print -r -- "$folder_title" > "$folder_dir/titre.txt"
      print "Titre créé : ${category_name}/${folder_name}/titre.txt"
    fi

    title=""
    for title_file in "$folder_dir/titre.html" "$folder_dir/titre.htm" "$folder_dir/titre.txt"; do
      if [[ -f "$title_file" ]]; then
        title="$(clean_title "$title_file")"
        break
      fi
    done
    [[ -z "$title" ]] && title="$folder_title"

    # Convert HEIC files before listing media so each photo is referenced once as JPEG.
    # Archive originals outside the scanned tree while preserving their source hierarchy.
    for heic_file in "$folder_dir"/*.(#i)(heic|heif)(.N); do
      converted_file="${heic_file:r}.jpg"
      if [[ ! -f "$converted_file" || "$heic_file" -nt "$converted_file" ]]; then
        print "Conversion HEIC en JPEG : ${heic_file:t}"
        sips -s format jpeg -s formatOptions 85 "$heic_file" --out "$converted_file" >/dev/null
      fi
      SetFile -d "$(stat -f '%SB' -t '%m/%d/%Y %H:%M:%S' "$heic_file")" "$converted_file"
      SetFile -m "$(stat -f '%Sm' -t '%m/%d/%Y %H:%M:%S' "$heic_file")" "$converted_file"
      archive_folder="${HEIC_ARCHIVE_DIR}/${category_name}/${folder_name}"
      mkdir -p "$archive_folder"
      print "Archivage HEIC : ${heic_file:t}"
      mv "$heic_file" "$archive_folder/${heic_file:t}"
    done

    instruction=""
    for instruction_file in "$folder_dir/instruction.html" "$folder_dir/instruction.htm" "$folder_dir/instruction.txt"; do
      if [[ -f "$instruction_file" ]]; then
        instruction="$(source_path "$category_name" "$folder_name" "${instruction_file:t}")"
        break
      fi
    done

    video_links_file="${folder_dir}/video-urls.txt"

    print "    $(json "$code"): {" >> "$BLOCK_FILE"
    print "      title: $(json "$title")," >> "$BLOCK_FILE"
    [[ -n "$instruction" ]] && print "      instruction: $(json "$instruction")," >> "$BLOCK_FILE"
    print '      items: [' >> "$BLOCK_FILE"

    for media_file in "$folder_dir"/*(.N); do
      name="${media_file:t}"
      case "$name" in
        .DS_Store|README.md|titre.txt|titre.html|titre.htm|instruction.txt|instruction.html|instruction.htm|video-urls.txt) continue ;;
      esac

      extension="${name:e:l}"
      case "$extension" in
        jpg|jpeg|png|gif|webp|avif) type="image" ;;
        heic|heif) continue ;;
        mp4|mov|m4v|webm|mts) type="video" ;;
        html|htm|txt|pdf) type="document" ;;
        *) print "Ignoré (${code}) : extension non prise en charge pour ${name}"; continue ;;
      esac

      media_title="${name:r}"
      media_title="${media_title//[-_]/ }"
      source="$(source_path "$category_name" "$folder_name" "$name")"
      line="        { title: $(json "$media_title"), type: $(json "$type"), source: $(json "$source")"
      if [[ "$type" == "video" && -f "$video_links_file" ]]; then
        video_url="$(VIDEO_NAME="$name" perl -ne 'if (/^\Q$ENV{VIDEO_NAME}\E\s*\|\s*(https?:\/\/\S+)/) { print $1; exit }' "$video_links_file")"
        [[ -n "$video_url" ]] && line+=", externalUrl: $(json "$video_url")"
      fi
      if [[ "$type" == "image" ]]; then
        dimensions="$(sips -g pixelWidth -g pixelHeight "$media_file" 2>/dev/null || true)"
        pixel_width="$(printf '%s\n' "$dimensions" | awk '/pixelWidth:/{print $2}')"
        pixel_height="$(printf '%s\n' "$dimensions" | awk '/pixelHeight:/{print $2}')"
        if [[ "$pixel_width" =~ '^[0-9]+$' && "$pixel_height" =~ '^[0-9]+$' ]]; then
          if (( pixel_width > pixel_height )); then orientation="landscape"
          elif (( pixel_width < pixel_height )); then orientation="portrait"
          else orientation="square"
          fi
          line+=", width: ${pixel_width}, height: ${pixel_height}, orientation: $(json "$orientation")"
        fi
      fi
      if [[ "$extension" == "html" || "$extension" == "htm" ]]; then
        height="$(declared_height "$media_file")"
        if [[ "$height" =~ '^[0-9]+$' && "$height" -ge 120 && "$height" -le 2000 ]]; then
          line+=", height: ${height}"
        fi
      fi
      if [[ "$type" == "image" || "$type" == "video" ]]; then
        created="$(french_date "$(stat -f '%SB' -t '%d %m %Y' "$media_file")")"
        created_at_epoch="$(stat -f '%B' "$media_file")"
        line+=", createdAt: $(json "$created"), createdAtEpoch: ${created_at_epoch}"
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
    or die "Bloc généré introuvable dans archive-config.local.js\n";
' "$CONFIG_FILE"

# Each regenerated archive list starts a new local progress session.
perl -0777 -i -pe '
  s/(progressResetKey:\s*")([0-9]+)(")/$1 . ($2 + 1) . $3/e
    or die "progressResetKey introuvable dans archive-config.local.js\n";
' "$CONFIG_FILE"

print ""
print "Configuration locale générée : ${count} dossier(s) d'archive trouvé(s). Suivi réinitialisé."
print ""
read "?Appuyez sur Entree pour fermer cette fenetre..."

# Terminal may be configured to keep completed shells open. Close only the
# window containing this script once the user acknowledges the result.
if [[ "$TERM_PROGRAM" == "Apple_Terminal" && -n "$TTY" ]]; then
  osascript - "$TTY" <<'APPLESCRIPT' >/dev/null 2>&1
on run argv
  set targetTty to item 1 of argv
  tell application "Terminal"
    repeat with terminalWindow in windows
      repeat with terminalTab in tabs of terminalWindow
        if tty of terminalTab is targetTty then
          close terminalWindow
          return
        end if
      end repeat
    end repeat
  end tell
end run
APPLESCRIPT
fi
