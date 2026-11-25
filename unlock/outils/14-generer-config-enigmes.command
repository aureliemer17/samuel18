#!/bin/zsh

# Valide les registres separes et genere les configurations du jeu.
set -e
OUTILS_DIR="${0:A:h}"
ROOT_DIR="${OUTILS_DIR:h:h}"
REGISTRE_DIR="${ROOT_DIR}/registre"
for file in registre-machines.csv registre-pages.csv registre-indices.csv; do
  [[ -f "$REGISTRE_DIR/$file" ]] || { print -u2 "Registre introuvable : $file"; exit 1; }
done
REGISTRE_DIR="$REGISTRE_DIR" CONFIG_DIR="$ROOT_DIR/unlock/config" perl -MJSON::PP=encode_json -MEncode=decode -CSDA -e '
  use strict; use warnings;
  my $registry = $ENV{REGISTRE_DIR};
  my $config = $ENV{CONFIG_DIR};
  sub rows {
    my ($name) = @_;
    open my $fh, "<:encoding(UTF-8)", "$registry/$name" or die "Impossible de lire $name: $!\n";
    my $header = <$fh>; chomp $header;
    my @keys = split /;/, $header, -1;
    my @rows;
    while (my $line = <$fh>) {
      chomp $line; next unless length $line;
      my @values = split /;/, $line, -1;
      my %row; @row{@keys} = @values;
      push @rows, \%row if lc($row{Actif} // "") eq "oui";
    }
    return @rows;
  }
  my @machines = rows("registre-machines.csv");
  my @pages = rows("registre-pages.csv");
  my @hints = rows("registre-indices.csv");
  my (%machines, %pages, %hints);
  for my $row (@machines) { die "Code machine duplique: $row->{Code}\n" if exists $machines{$row->{Code}}; $machines{$row->{Code}} = $row->{Destination}; }
  for my $row (@pages) {
    my %entry;
    $entry{entryCode} = $row->{"Code entree"} if length($row->{"Code entree"} // "");
    $entry{unlockCode} = $row->{"Code devoile"} if length($row->{"Code devoile"} // "");
    $pages{$row->{Identifiant}} = \%entry;
  }
  for my $row (@hints) {
    my $entry = ($hints{$row->{Carte}} //= { hints => [] });
    $entry->{hints}[($row->{Position} // 1) - 1] = $row->{Texte};
    $entry->{solution} = 0 + $row->{Position} if lc($row->{Solution} // "") eq "oui";
  }
  for my $entry (values %hints) { $entry->{hints} = [ grep { defined } @{$entry->{hints}} ]; }
  open my $puzzle, ">:encoding(UTF-8)", "$config/config.js" or die $!;
  print $puzzle "// Genere depuis registre/registre-machines.csv et registre/registre-pages.csv.\nwindow.PUZZLE_CONFIG = ", JSON::PP->new->canonical->pretty->encode({ machines => \%machines, pages => \%pages }), ";\n";
  open my $hint_file, ">:encoding(UTF-8)", "$config/hints-config.js" or die $!;
  print $hint_file "// Genere depuis registre/registre-indices.csv.\nwindow.HINTS_CONFIG = ", JSON::PP->new->canonical->pretty->encode(\%hints), ";\n";
  print "Configurations generees : ", scalar(@machines), " machine(s), ", scalar(@pages), " page(s), ", scalar(@hints), " indice(s).\n";
'
read "?Appuyez sur Entree pour fermer cette fenetre..."
