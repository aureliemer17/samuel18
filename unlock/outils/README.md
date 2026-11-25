# Gestion des archives

## Point d'entrée recommandé

Utilisez `Gestion des archives.command`. Il remplace les séquences de scripts
numérotés par un menu unique et garde les médias originaux hors de Git.

Les actions courantes sont :

1. **Ajouter ou modifier un souvenir** : choisir le souvenir puis ajouter une photo,
   vidéo, anecdote, instruction, titre ou document. La configuration et le contenu
   publié sont mis à jour après l'ajout.
2. **Régénérer le site local** : à utiliser après une opération importante ou pour
    repartir d'une configuration propre. Les HEIC, le contenu publié, les liens vidéo
    et les images PDF sont traités en une seule action. Cette action ne contacte pas
    Google Drive et ne modifie pas les liens photo Drive.
3. **Préparer les médias pour Google Drive** : crée seulement les photos et vidéos
   nouvelles ou modifiées sous `../../dossiers/travail/drive-a-deposer/`, avec la
   même arborescence que les originaux. Déposez ce contenu dans Drive.
4. **Importer l'inventaire Google Drive** : téléchargez `drive-inventaire-medias.csv`
    depuis Drive vers `../../dossiers/drive-imports/`, puis lancez cette action pour
    mettre à jour les liens photo et vidéo du site.

Après un renommage de thèmes ou dossiers dans Drive, exécutez d'abord
`inventorierMedias` dans Apps Script, téléchargez son CSV, puis choisissez l'action 4.
Cette étape régénère `../config/archive-photo-drive-config.js` avec les nouveaux
chemins et IDs ; elle est indispensable pour que les photos en ligne se chargent.
5. **Vérifier avant publication Git** : bloque les médias d'archives placés par erreur
   dans `unlock/` et affiche les fichiers réellement modifiés.
6. **Codes et énigmes** : génère les configurations depuis des registres séparés,
   puis prépare un plan de renommage local et Drive des codes d'archives. Le plan
   n'est appliqué qu'après confirmation ; Drive utilise le même CSV.

## Règles de rangement

- `../../dossiers/` est la source de vérité locale et n'est jamais versionné.
- Google Drive reprend exactement cette arborescence ; il est une copie publiée,
  jamais la source de vérité.
- `../contenu-archives/` ne reçoit que les anecdotes, instructions et documents.
  Les photos et vidéos ne doivent jamais être ajoutées sous `unlock/`.
- Les copies de travail, rapports et CSV téléchargés sont sous `dossiers/travail/`,
  `dossiers/rapports/` et `dossiers/drive-imports/`, tous ignorés par Git.

## Google Drive

`google-drive-synchroniser-medias.gs` inventorie les photos **et** vidéos, y compris
leur taille. Il peut aussi placer dans la corbeille les éléments listés dans un plan
CSV, uniquement après avoir renseigné `PLAN_FILE_ID` et confirmé `APPLY_PLAN = true`.

## Scripts historiques

Les fichiers numérotés restent disponibles pour compatibilité pendant la migration.
Le nouveau menu les orchestre et évite de devoir se souvenir de leur ordre.

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

Pour afficher certaines vidéos dans le déroulé chronologique sans modifier leurs noms ni leurs liens Google Drive, créer `../../dossiers/<Thème>/<Dossier>/video-affichage.txt`. Ajouter une ligne par vidéo : `Nom exact de la vidéo.mov | principale`. Ces vidéos apparaissent avec les photos et les autres vidéos principales par date de création ; celles qui ne sont pas listées restent dans la section finale avec QR codes. Le même fichier peut aussi déclarer `Nom exact de la vidéo.mov | recap`.

## Exporter un PDF complet

6. `06-preparer-images-pour-pdf.command` : crée des copies JPEG imprimables, limitées à 1800 pixels et compressées, dans `../../dossiers/pdf-images/<Thème>/<Dossier>/`. Les originaux restent intacts. Cette commande peut être relancée : seules les photos nouvelles ou modifiées sont traitées.
7. Ouvrir `../archives/decouvertes.html?admin=1`, puis cliquer sur `PDF COMPLET`. L’export emploie automatiquement les images allégées quand elles existent. Si elles n’ont pas été préparées, il utilise les originaux.

## Inventorier les photos pour Google Drive

8. `07-inventorier-photos-pour-google-drive.command` : crée `../../dossiers/photos-google-drive-a-completer.csv`, avec une ligne par photo et son thème, dossier, nom exact, format, taille et date. Ce fichier est uniquement un inventaire à compléter dans Numbers avec les liens Google Drive ; l’outil ne modifie aucun média ni aucune configuration.

## Tester Google Drive pour les photos

9. `08-copier-photos-pour-google-drive.command` : crée `../../dossiers/photos/`, avec les copies des photos rangées comme les archives. Pour un essai, déposer seulement un petit sous-dossier dans Google Drive.
10. `google-drive-inventorier-photos.gs` : créer un projet sur [script.google.com](https://script.google.com), coller le script, renseigner l’ID du dossier Drive test dans `ROOT_FOLDER_ID`, puis exécuter `inventorierPhotos`. Le script crée `photos-google-drive-inventaire.csv` dans ce dossier avec les IDs et les liens de toutes les photos trouvées.
11. Télécharger ce CSV depuis Drive vers `../../dossiers/photos-google-drive-inventaire.csv`, puis lancer `09-importer-liens-photos-google-drive.command`. Il crée `../config/archive-photo-drive-config.js`, qui est versionné par Git. Les archives l’utilisent uniquement quand elles sont ouvertes en ligne, afin que la consultation locale sur Mac et les exports PDF continuent d’utiliser les fichiers locaux.

## Publier les anecdotes et textes

12. `10-copier-contenu-archives-pour-site.command` : copie les anecdotes, instructions et documents HTML/TXT/PDF vers `../contenu-archives/<Thème>/<Dossier>/`. Les photos et vidéos ne sont jamais copiées. Les titres, `video-urls.txt` et `video-affichage.txt` sont exclus. Pour versionner le contenu produit : `git add -A unlock/contenu-archives`.

## Outils occasionnels

- `90-exporter-arborescence-archives.command` : lit `../../dossiers/` et exporte l'arborescence dans `../../dossiers/arborescence-archives.txt` pour la partager ou la faire analyser.
- `99-modele-anecdote.html` : modèle à copier comme `../../dossiers/<Thème>/<Dossier>/anecdote.html` pour ajouter une anecdote.

Les fichiers dans `dossiers/` sont locaux et ne sont pas envoyés sur GitHub.
