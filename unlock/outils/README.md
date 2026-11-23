# Outils d'archives

Les fichiers sont numérotés dans l'ordre habituel d'utilisation.

## Préparer les vidéos pour Google Drive

1. `00-copier-videos-pour-google-drive.command` : crée des copies des vidéos dans `../../dossiers/videos/`, prêtes à être glissées dans Google Drive.
2. Dans Google Drive, déposer le contenu de `../../dossiers/videos/`, puis récupérer les liens de partage des vidéos.
3. `01-configurer-liens-videos.command` : saisir les liens un par un, directement dans le Terminal. Il lit les vidéos dans `../../dossiers/<Thème>/<Dossier>/` et crée ou met à jour `../../dossiers/<Thème>/<Dossier>/video-urls.txt`.

Alternative pratique pour beaucoup de vidéos :

1. `02-verifier-liens-videos.command` : lit les vidéos dans `../../dossiers/<Thème>/<Dossier>/`, ainsi que les éventuels `video-urls.txt`, puis crée `../../dossiers/rapport-liens-videos.csv` et `../../dossiers/liens-videos-a-completer.csv`.
2. Compléter la colonne `Lien Google Drive` dans `../../dossiers/liens-videos-a-completer.csv`.
3. `03-importer-liens-videos-csv.command` : lit `../../dossiers/liens-videos-a-completer.csv` et importe les liens dans `../../dossiers/<Thème>/<Dossier>/video-urls.txt`. Depuis Numbers, exporter d'abord en CSV et remplacer ce fichier ; un fichier `.numbers` ne peut pas être importé directement.

## Mettre à jour le livret

4. `04-mettre-a-jour-archives.command` : à lancer après tout ajout ou modification de média, titre, vidéo ou lien Google Drive. Il lit `../../dossiers/<Thème>/<Dossier>/`, génère `../config/archive-config.local.js`, convertit les HEIC en JPEG, archive les originaux dans `../../dossiers/heic/<Thème>/<Dossier>/` et crée les QR codes vidéo dans `../../dossiers/<Thème>/<Dossier>/qrcodes/`.

## Outils occasionnels

- `90-exporter-arborescence-archives.command` : lit `../../dossiers/` et exporte l'arborescence dans `../../dossiers/arborescence-archives.txt` pour la partager ou la faire analyser.
- `99-modele-anecdote.html` : modèle à copier comme `../../dossiers/<Thème>/<Dossier>/anecdote.html` pour ajouter une anecdote.

Les fichiers dans `dossiers/` sont locaux et ne sont pas envoyés sur GitHub.
