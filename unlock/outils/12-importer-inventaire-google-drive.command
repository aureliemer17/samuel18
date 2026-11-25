#!/bin/zsh

# Importe l'inventaire unifie Drive. Les liens photo et video sont extraits
# vers les formats de compatibilite actuels, puis leurs configurations sont regenerees.
set -e
OUTILS_DIR="${0:A:h}"
DOSSIERS_DIR="${OUTILS_DIR:h:h}/dossiers"
IMPORT_DIR="${DOSSIERS_DIR}/drive-imports"
INPUT="${IMPORT_DIR}/drive-inventaire-medias.csv"
[[ -f "$INPUT" ]] || { print -u2 "Placez le CSV Drive ici : $INPUT"; exit 1; }
mkdir -p "$IMPORT_DIR"
PHOTO_CSV="${DOSSIERS_DIR}/photos-google-drive-inventaire.csv"
VIDEO_CSV="${DOSSIERS_DIR}/liens-videos-a-completer.csv"
INPUT="$INPUT" PHOTO_CSV="$PHOTO_CSV" VIDEO_CSV="$VIDEO_CSV" perl -MEncode=decode -CSDA -e '
  sub parse_csv {
    my ($line) = @_; chomp $line; my @values;
    while ($line =~ /\G(?:\A|,)(?:"((?:[^"]|"")*)"|([^,]*))/gc) { my $value = defined $1 ? $1 : $2; $value =~ s/""/"/g; push @values, $value; }
    return @values;
  }
  sub quote_csv { my ($value) = @_; $value =~ s/"/""/g; return qq{"$value"}; }
  open my $in, "<:encoding(UTF-8)", $ENV{INPUT} or die "$!\n";
  open my $photos, ">:encoding(UTF-8)", $ENV{PHOTO_CSV} or die "$!\n";
  open my $videos, ">:encoding(UTF-8)", $ENV{VIDEO_CSV} or die "$!\n";
  print $photos join(",", map { quote_csv($_) } ("Thème", "Dossier", "Nom exact de la photo", "ID Google Drive", "Lien Google Drive")), "\n";
  print $videos join(",", map { quote_csv($_) } ("Thème", "Dossier", "Nom exact de la vidéo", "Lien Google Drive")), "\n";
  <$in>; my ($photo_count, $video_count) = (0, 0);
  while (my $line = <$in>) {
    my ($theme, $folder, $name, $type, $size, $id, $link) = parse_csv($line);
    next unless $theme && $folder && $name && $id && $link;
    if ($type eq "Photo") { print $photos join(",", map { quote_csv($_) } ($theme, $folder, $name, $id, $link)), "\n"; $photo_count++; }
    if ($type eq "Video") { print $videos join(",", map { quote_csv($_) } ($theme, $folder, $name, $link)), "\n"; $video_count++; }
  }
  print "Photos importables : $photo_count | Videos importables : $video_count\n";
'
printf '\n' | "$OUTILS_DIR/09-importer-liens-photos-google-drive.command"
printf '\n' | "$OUTILS_DIR/03-importer-liens-videos-csv.command"
printf '\n' | "$OUTILS_DIR/04-mettre-a-jour-liens-videos.command"
