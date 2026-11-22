# Outils d'archives

Les fichiers sont numérotés dans l'ordre habituel d'utilisation.

## Préparer les vidéos pour Google Drive

1. `00-copier-videos-pour-google-drive.command` : crée des copies des vidéos dans `dossiers/videos/`, prêtes à être glissées dans Google Drive.
2. Dans Google Drive, déposer le contenu de `dossiers/videos/`, puis récupérer les liens de partage des vidéos.
3. `01-configurer-liens-videos.command` : saisir les liens un par un, directement dans le Terminal.

Alternative pratique pour beaucoup de vidéos :

1. `02-verifier-liens-videos.command` : crée `dossiers/rapport-liens-videos.csv` et `dossiers/liens-videos-a-completer.csv`.
2. Compléter la colonne `Lien Google Drive` dans `liens-videos-a-completer.csv`.
3. `03-importer-liens-videos-csv.command` : importe les liens du CSV dans les dossiers d'archives.

## Mettre à jour le livret

4. `04-mettre-a-jour-archives.command` : à lancer après tout ajout ou modification de média, titre, vidéo ou lien Google Drive. Il génère la configuration locale, convertit les HEIC et crée les QR codes des vidéos pour les PDF.

## Outils occasionnels

- `90-exporter-arborescence-archives.command` : exporte l'arborescence des dossiers pour la partager ou la faire analyser.
- `99-modele-anecdote.html` : modèle à copier dans un dossier d'archive pour ajouter une anecdote.

Les fichiers dans `dossiers/` sont locaux et ne sont pas envoyés sur GitHub.
