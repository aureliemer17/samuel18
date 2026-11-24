/**
 * Crée dans Google Drive un CSV des photos sous un dossier racine.
 *
 * TEST : créez d'abord un petit dossier Drive contenant seulement un thème,
 * un dossier d'archive et quelques photos. Collez son ID dans ROOT_FOLDER_ID.
 * L'ID se trouve dans l'URL : drive.google.com/drive/folders/<ID>
 */
const ROOT_FOLDER_ID = "COLLEZ_ICI_L_ID_DU_DOSSIER_TEST";
const OUTPUT_FILE_NAME = "photos-google-drive-inventaire.csv";
const PHOTO_MIME_TYPES = new Set([
  "image/jpeg",
  "image/png",
  "image/gif",
  "image/webp",
  "image/avif",
]);

function inventorierPhotos() {
  if (ROOT_FOLDER_ID === "COLLEZ_ICI_L_ID_DU_DOSSIER_TEST") {
    throw new Error("Remplacez ROOT_FOLDER_ID par l'ID du dossier Google Drive à inventorier.");
  }

  const root = DriveApp.getFolderById(ROOT_FOLDER_ID);
  const rows = [["Thème", "Dossier", "Nom exact de la photo", "ID Google Drive", "Lien Google Drive"]];
  parcourirDossier(root, [], rows);

  const csv = rows.map((row) => row.map(csvCell).join(",")).join("\n");
  const existing = root.getFilesByName(OUTPUT_FILE_NAME);
  while (existing.hasNext()) existing.next().setTrashed(true);
  const report = root.createFile(OUTPUT_FILE_NAME, csv, MimeType.CSV);

  Logger.log(`Photos trouvées : ${rows.length - 1}`);
  Logger.log(`Rapport : ${report.getUrl()}`);
}

function parcourirDossier(folder, path, rows) {
  const nextPath = path.concat(folder.getName());
  const files = folder.getFiles();
  while (files.hasNext()) {
    const file = files.next();
    if (!PHOTO_MIME_TYPES.has(file.getMimeType())) continue;
    const relativePath = nextPath.slice(1);
    rows.push([
      relativePath[0] || "",
      relativePath.slice(1).join(" / "),
      file.getName(),
      file.getId(),
      `https://drive.google.com/file/d/${file.getId()}/view`,
    ]);
  }

  const folders = folder.getFolders();
  while (folders.hasNext()) parcourirDossier(folders.next(), nextPath, rows);
}

function csvCell(value) {
  return `"${String(value).replace(/"/g, '""')}"`;
}
