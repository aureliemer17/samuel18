OUTILS D'ARCHIVES
=================

Ordre habituel pour les vidéos : 00, puis 01 OU 02 + 03, puis 04.

00-copier-videos-pour-google-drive.command
  Copie les vidéos de ../../dossiers/<Thème>/<Dossier>/ dans le dossier ci-dessous,
  prêtes à déposer dans Google Drive.
  Génère : ../../dossiers/videos/

01-configurer-liens-videos.command
  Permet de saisir les liens Google Drive des vidéos, un par un.
  Nécessite : les vidéos dans ../../dossiers/<Thème>/<Dossier>/
  Génère ou met à jour : ../../dossiers/<Thème>/<Dossier>/video-urls.txt

02-verifier-liens-videos.command
  Crée un rapport CSV des vidéos et un CSV ne contenant que les liens manquants.
  Nécessite : les vidéos dans ../../dossiers/<Thème>/<Dossier>/
  Lit si présent : ../../dossiers/<Thème>/<Dossier>/video-urls.txt
  Génère : ../../dossiers/rapport-liens-videos.csv
  Génère : ../../dossiers/liens-videos-a-completer.csv

03-importer-liens-videos-csv.command
  Importe les liens ajoutés dans le CSV des liens manquants.
  Nécessite : ../../dossiers/liens-videos-a-completer.csv complété
  Génère ou met à jour : ../../dossiers/<Thème>/<Dossier>/video-urls.txt
  Numbers : exporter en CSV, remplacer ce fichier, puis lancer l'outil.
  Un fichier .numbers ne peut pas être importé directement.
  Les accents et apostrophes sont pris en charge ; l'outil vérifie le nom réel
  de chaque vidéo et indique les fichiers disponibles en cas de différence.

04-mettre-a-jour-liens-videos.command
  Mise à jour rapide après avoir ajouté ou modifié des liens Google Drive.
  Ne convertit pas les HEIC et ne modifie pas les photos ou la progression.
  Nécessite : ../../dossiers/<Thème>/<Dossier>/video-urls.txt
  Génère : ../config/archive-video-config.local.js
  Les QR codes sont créés au moment de l'export PDF ; une connexion Internet
  est nécessaire à cet instant, mais aucun outil supplémentaire n'est requis.

05-mettre-a-jour-archives.command
  À lancer après toute modification : actualise le livret, convertit les HEIC
  et actualise toutes les archives. À utiliser après ajout de photos, HEIC,
  documents, titres ou dossiers ; pas nécessaire après un simple lien vidéo.
  Nécessite : ../../dossiers/<Thème>/<Dossier>/
  Génère : ../config/archive-config.local.js
  Convertit : les .heic/.heif en .jpg dans leur dossier d'origine
  Déplace les originaux HEIC : ../../dossiers/heic/<Thème>/<Dossier>/
  Ne génère pas les QR codes : ils sont créés au moment de l'export PDF.
  Vidéo récapitulative : commencer son nom par recap ou récap, par exemple
  recap-anniversaire.mp4. Elle sera affichée avant les photos ; les autres
  vidéos iront à la fin dans une liste spéciale avec QR codes.
  Vidéo principale sans renommage : créer video-affichage.txt avec une ligne
  Nom exact de la vidéo.mov | principale. Elle suivra les photos et vidéos
  principales dans l'ordre chronologique ; les vidéos non listées restent à la fin.

06-preparer-images-pour-pdf.command
  Crée des copies JPEG allégées des photos pour un PDF complet plus rapide
  et plus petit, sans modifier les originaux.
  Nécessite : les photos dans ../../dossiers/<Thème>/<Dossier>/
  Génère : ../../dossiers/pdf-images/<Thème>/<Dossier>/*.jpg
  Puis ouvrir : ../archives/decouvertes.html?admin=1 et cliquer PDF COMPLET.

07-inventorier-photos-pour-google-drive.command
  Crée un inventaire séparé des photos pour préparer leur mise sur Google Drive.
  Nécessite : les photos dans ../../dossiers/<Thème>/<Dossier>/
  Génère : ../../dossiers/photos-google-drive-a-completer.csv
  Ne modifie pas les photos, les vidéos ou les configurations d'archives.

08-copier-photos-pour-google-drive.command
  Copie les photos dans ../../dossiers/photos/ en conservant l'arborescence,
  prêtes à déposer dans Google Drive sans déplacer les originaux.

google-drive-inventorier-photos.gs
  Script Google Apps Script à coller dans script.google.com pour tester
  l'inventaire automatique d'un dossier Drive : photos, IDs et liens.

09-importer-liens-photos-google-drive.command
  Nécessite : télécharger depuis Drive le fichier photos-google-drive-inventaire.csv
  vers ../../dossiers/photos-google-drive-inventaire.csv.
  Génère : ../config/archive-photo-drive-config.js, versionnable dans Git.
  Les liens photo sont utilisés seulement quand les archives sont ouvertes en ligne,
  pas lors de la consultation locale sur Mac.

10-copier-contenu-archives-pour-site.command
  Copie anecdotes, instructions et documents HTML/TXT/PDF vers le site publié.
  Génère ou met à jour : ../contenu-archives/<Thème>/<Dossier>/
  Exclut titres et fichiers de configuration vidéo. Après exécution :
  git add -A unlock/contenu-archives

90-exporter-arborescence-archives.command
  Exporte la liste des dossiers et fichiers d'archives.
  Nécessite : ../../dossiers/
  Génère : ../../dossiers/arborescence-archives.txt

99-modele-anecdote.html
  Modèle à copier dans un dossier pour ajouter une anecdote.
  À copier vers : ../../dossiers/<Thème>/<Dossier>/anecdote.html

README.md
  Version détaillée de ce guide.
