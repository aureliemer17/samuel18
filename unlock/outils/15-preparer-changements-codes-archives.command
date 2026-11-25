#!/bin/zsh

# Produit ou applique un registre des codes d'archives. Les renommages locaux et
# Drive ne sont jamais effectues sans apercu puis confirmation explicite.
set -e
setopt null_glob extended_glob
OUTILS_DIR="${0:A:h}"
ROOT_DIR="${OUTILS_DIR:h:h}"
DOSSIERS_DIR="${ROOT_DIR}/dossiers"
REGISTRY="${ROOT_DIR}/registre/registre-archives.csv"
PLAN="${ROOT_DIR}/registre/plan-renommage-drive.csv"

if [[ ! -f "$REGISTRY" ]]; then
  print '"Theme","Dossier actuel","Code actuel","Nouveau code","Titre","Action"' > "$REGISTRY"
  for category_dir in "$DOSSIERS_DIR"/*(/N); do
    category="${category_dir:t}"
    [[ "$category" == (heic|videos|photos|pdf-images|travail|rapports|drive-imports) ]] && continue
    for folder_dir in "$category_dir"/*(/N); do
      folder="${folder_dir:t}"
      if [[ "$folder" =~ '^((I|II|III|IV|V|VI|VII)-[A-J]-[1-8])( - (.*))?$' ]]; then
        code="$match[1]"; title="$match[4]"
        print "\"$category\",\"$folder\",\"$code\",\"$code\",\"$title\",\"Aucune\"" >> "$REGISTRY"
      fi
    done
  done
  print "Registre genere : $REGISTRY"
  print "Modifiez Nouveau code puis relancez cette commande pour obtenir un apercu."
  read "?Appuyez sur Entree pour fermer cette fenetre..."
  exit 0
fi

REGISTRY="$REGISTRY" PLAN="$PLAN" perl -MEncode=decode -CSDA -e '
  sub parse_csv {
    my ($line) = @_; chomp $line; my @values;
    while ($line =~ /\G(?:\A|,)(?:"((?:[^"]|"")*)"|([^,]*))/gc) {
      my $value = defined $1 ? $1 : $2; $value =~ s/""/"/g; push @values, $value;
    }
    return @values;
  }
  sub quote_csv { my ($value) = @_; $value =~ s/"/""/g; return qq{"$value"}; }
  open my $in, "<:encoding(UTF-8)", $ENV{REGISTRY} or die "$!\n";
  <$in>; my @plan = (["Type", "Theme", "Ancien dossier", "Nouveau dossier", "Action"]); my $count = 0;
  while (my $line = <$in>) {
    my ($theme, $folder, $old, $new, $title, $action) = parse_csv($line);
    next unless $old ne $new && lc($action // "") eq "renommer";
    push @plan, ["Dossier", $theme, $folder, $new . (length($title // "") ? " - $title" : ""), "renommer"]; $count++;
  }
  open my $out, ">:encoding(UTF-8)", $ENV{PLAN} or die "$!\n";
  print $out join(",", map { quote_csv($_) } @$_), "\n" for @plan;
  print "Plan genere : $count renommage(s).\n";
'
print "Plan Google Drive genere : $PLAN"
print "Verifiez-le, puis utilisez google-drive-synchroniser-medias.gs pour appliquer les renommages Drive."
read "confirm?Appliquer aussi les renommages locaux indiques dans le plan ? [oui/N] "
if [[ "$confirm" == "oui" ]]; then
  REGISTRY="$REGISTRY" DOSSIERS_DIR="$DOSSIERS_DIR" perl -MEncode=decode -CSDA -e '
    sub parse_csv {
      my ($line) = @_; chomp $line; my @values;
      while ($line =~ /\G(?:\A|,)(?:"((?:[^"]|"")*)"|([^,]*))/gc) { my $value = defined $1 ? $1 : $2; $value =~ s/""/"/g; push @values, $value; }
      return @values;
    }
    open my $in, "<:encoding(UTF-8)", $ENV{REGISTRY} or die "$!\n"; <$in>;
    while (my $line = <$in>) {
      my ($theme, $folder, $old, $new, $title, $action) = parse_csv($line);
      next unless lc($action // "") eq "renommer" && $old ne $new;
      my $from = "$ENV{DOSSIERS_DIR}/$theme/$folder";
      my $to = "$ENV{DOSSIERS_DIR}/$theme/$new" . (length($title // "") ? " - $title" : "");
      die "Dossier local introuvable : $from\n" unless -d $from;
      die "Destination locale existante : $to\n" if -e $to;
      rename $from, $to or die "Renommage impossible : $!\n";
      print "Renomme : $folder -> $new\n";
    }
  '
fi
read "?Appuyez sur Entree pour fermer cette fenetre..."
