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

04-mettre-a-jour-archives.command
  À lancer après toute modification : actualise le livret, convertit les HEIC
  et génère les QR codes vidéo pour les exports PDF.
  Nécessite : ../../dossiers/<Thème>/<Dossier>/ et, pour les QR codes,
  ../../dossiers/<Thème>/<Dossier>/video-urls.txt
  Génère : ../config/archive-config.local.js
  Génère : ../../dossiers/<Thème>/<Dossier>/qrcodes/qr-<identifiant>.png
  Convertit : les .heic/.heif en .jpg dans leur dossier d'origine
  Déplace les originaux HEIC : ../../dossiers/heic/<Thème>/<Dossier>/

90-exporter-arborescence-archives.command
  Exporte la liste des dossiers et fichiers d'archives.
  Nécessite : ../../dossiers/
  Génère : ../../dossiers/arborescence-archives.txt

99-modele-anecdote.html
  Modèle à copier dans un dossier pour ajouter une anecdote.
  À copier vers : ../../dossiers/<Thème>/<Dossier>/anecdote.html

README.md
  Version détaillée de ce guide.
