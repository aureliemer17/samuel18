#!/bin/zsh

# Associe les videos locales aux liens de partage Google Drive.
# Les liens sont stockes dans video-urls.txt, un lien par ligne :
# nom-du-fichier.mp4 | https://drive.google.com/...
set -e
setopt null_glob extended_glob
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

OUTILS_DIR="${0:A:h}"
DOSSIERS_DIR="${OUTILS_DIR:h:h}/dossiers"

if [[ ! -d "$DOSSIERS_DIR" ]]; then
  osascript -e 'display alert "Dossier introuvable" message "Le dossier ../dossiers est introuvable." as critical'
  exit 1
fi

video_files=()
for category_dir in "$DOSSIERS_DIR"/*(/); do
  [[ "${category_dir:t}" == "heic" || "${category_dir:t}" == "videos" ]] && continue
  for folder_dir in "$category_dir"/*(/); do
    print "Recherche de vidéos dans : $folder_dir"
    for video_file in "$folder_dir"/*.(#i)(mp4|mov|m4v|webm|mts)(.N); do
      print "  Vidéo trouvée : ${video_file:t}"
      video_files+=("$video_file")
    done
  done
done

if (( ${#video_files} == 0 )); then
  osascript -e 'display alert "Aucune video" message "Aucune video MP4, MOV, M4V, WEBM ou MTS n’a ete trouvee."'
  exit 0
fi

for video_file in "${video_files[@]}"; do
  folder_dir="${video_file:h}"
  video_name="${video_file:t}"
  links_file="${folder_dir}/video-urls.txt"
  existing_url=""
  if [[ -f "$links_file" ]]; then
    existing_url="$(VIDEO_NAME="$video_name" perl -ne 'if (/^\Q$ENV{VIDEO_NAME}\E\s*\|\s*(\S+)/) { print $1; exit }' "$links_file")"
  fi

  prompt="${folder_dir:t}\n\nVideo : ${video_name}\n\nCollez le lien Google Drive. Laissez vide pour ne rien associer."
  if [[ -n "$existing_url" ]]; then prompt+="\n\nLien actuel : ${existing_url}"; fi
  answer="$(osascript - "$prompt" "$existing_url" <<'APPLESCRIPT'
on run argv
  set response to display dialog (item 1 of argv) default answer (item 2 of argv) buttons {"Ignorer", "Enregistrer"} default button "Enregistrer" with title "Lien video Google Drive"
  if button returned of response is "Ignorer" then return ""
  return text returned of response
end run
APPLESCRIPT
)"

  [[ -z "$answer" ]] && continue
  if [[ ! "$answer" =~ '^https?://' ]]; then
    osascript -e 'display alert "Lien invalide" message "Le lien doit commencer par https:// ou http://." as warning'
    continue
  fi

  temp_file="$(mktemp)"
  if [[ -f "$links_file" ]]; then
    VIDEO_NAME="$video_name" perl -ne 'print unless /^\Q$ENV{VIDEO_NAME}\E\s*\|/' "$links_file" > "$temp_file"
  fi
  print -r -- "${video_name} | ${answer}" >> "$temp_file"
  mv "$temp_file" "$links_file"
done

osascript -e 'display notification "Les liens ont ete enregistres. Lancez ensuite Mettre a jour les archives." with title "Liens video"'
