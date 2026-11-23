# Outils d'archives

Les fichiers sont numérotés dans l'ordre habituel d'utilisation.

## Préparer les vidéos pour Google Drive

1. `00-copier-videos-pour-google-drive.command` : crée des copies des vidéos dans `../../dossiers/videos/`, prêtes à être glissées dans Google Drive.
2. Dans Google Drive, déposer le contenu de `../../dossiers/videos/`, puis récupérer les liens de partage des vidéos.
3. `01-configurer-liens-videos.command` : saisir les liens un par un, directement dans le Terminal. Il lit les vidéos dans `../../dossiers/<Thème>/<Dossier>/` et crée ou met à jour `../../dossiers/<Thème>/<Dossier>/video-urls.txt`.

Alternative pratique pour beaucoup de vidéos :

1. `02-verifier-liens-videos.command` : lit les vidéos dans `../../dossiers/<Thème>/<Dossier>/`, ainsi que les éventuels `video-urls.txt`, puis crée `../../dossiers/rapport-liens-videos.csv` et `../../dossiers/liens-videos-a-completer.csv`.
2. Compléter la colonne `Lien Google Drive` dans `../../dossiers/liens-videos-a-completer.csv`.
3. `03-importer-liens-videos-csv.command` : lit `../../dossiers/liens-videos-a-completer.csv` et importe les liens dans `../../dossiers/<Thème>/<Dossier>/video-urls.txt`. Depuis Numbers, exporter d'abord en CSV et remplacer ce fichier ; un fichier `.numbers` ne peut pas être importé directement. Les accents et apostrophes sont normalisés et l’outil signale les vidéos introuvables avec la liste des noms réellement présents.

## Mettre à jour les liens vidéo

4. `04-mettre-a-jour-liens-videos.command` : à lancer après un ajout ou une modification de lien Google Drive. Il lit seulement les `../../dossiers/<Thème>/<Dossier>/video-urls.txt` et génère `../config/archive-video-config.local.js`. Il ne convertit aucune photo, ne traite aucun HEIC et ne réinitialise pas la progression. Les QR codes sont créés au moment de l'export PDF, avec une connexion Internet, sans installer d'outil sur le Mac.

## Mettre à jour tout le livret

5. `05-mettre-a-jour-archives.command` : à lancer après un ajout ou une modification de photo, HEIC, document, titre ou dossier. Il lit `../../dossiers/<Thème>/<Dossier>/`, génère `../config/archive-config.local.js`, convertit les HEIC en JPEG et archive les originaux dans `../../dossiers/heic/<Thème>/<Dossier>/`. Il n'est pas nécessaire après un simple lien vidéo. Les QR codes sont créés au moment de l'export PDF.

Pour un dossier comprenant une vidéo récapitulative, commencer son nom par `recap` ou `récap`, par exemple `recap-anniversaire.mp4`. Après la mise à jour complète, cette vidéo est placée en premier, les photos suivent, puis les autres vidéos sont regroupées à la fin dans une section spéciale avec leurs QR codes.

## Exporter un PDF complet

6. `06-preparer-images-pour-pdf.command` : crée des copies JPEG imprimables, limitées à 1800 pixels et compressées, dans `../../dossiers/pdf-images/<Thème>/<Dossier>/`. Les originaux restent intacts. Cette commande peut être relancée : seules les photos nouvelles ou modifiées sont traitées.
7. Ouvrir `../archives/decouvertes.html?admin=1`, puis cliquer sur `PDF COMPLET`. L’export emploie automatiquement les images allégées quand elles existent. Si elles n’ont pas été préparées, il utilise les originaux.

## Outils occasionnels

- `90-exporter-arborescence-archives.command` : lit `../../dossiers/` et exporte l'arborescence dans `../../dossiers/arborescence-archives.txt` pour la partager ou la faire analyser.
- `99-modele-anecdote.html` : modèle à copier comme `../../dossiers/<Thème>/<Dossier>/anecdote.html` pour ajouter une anecdote.

Les fichiers dans `dossiers/` sont locaux et ne sont pas envoyés sur GitHub.
