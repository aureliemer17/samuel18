/**
 * Inventorie photos et videos sous ROOT_FOLDER_ID. Le CSV produit est la source
 * d'import locale. Pour appliquer un plan de nettoyage, renseignez PLAN_FILE_ID
 * puis mettez APPLY_PLAN a true : les elements listes sont mis a la corbeille.
 */
const ROOT_FOLDER_ID = "COLLEZ_ICI_L_ID_DU_DOSSIER_RACINE";
const INVENTORY_FILE_NAME = "drive-inventaire-medias.csv";
const PLAN_FILE_ID = "";
const APPLY_PLAN = false;
const MEDIA_MIME_PREFIXES = ["image/", "video/"];

function inventorierMedias() {
  assertRoot();
  const root = DriveApp.getFolderById(ROOT_FOLDER_ID);
  const rows = [["Theme", "Dossier", "Nom exact", "Type", "Taille octets", "ID Google Drive", "Lien Google Drive"]];
  parcourir(root, [], rows);
  remplacerCsv(root, INVENTORY_FILE_NAME, rows);
  Logger.log(`Medias trouves : ${rows.length - 1}`);
}

function appliquerPlanDeCorbeille() {
  assertRoot();
  if (!APPLY_PLAN) throw new Error("Definissez APPLY_PLAN = true apres verification du plan.");
  if (!PLAN_FILE_ID) throw new Error("Renseignez PLAN_FILE_ID.");
  const values = Utilities.parseCsv(DriveApp.getFileById(PLAN_FILE_ID).getBlob().getDataAsString("UTF-8"));
  const header = values.shift();
  const idIndex = header.indexOf("ID Google Drive");
  const actionIndex = header.indexOf("Action");
  if (idIndex < 0 || actionIndex < 0) throw new Error("Le plan doit contenir ID Google Drive et Action.");
  let trashed = 0;
  values.forEach((row) => {
    if (String(row[actionIndex]).toLowerCase() !== "corbeille") return;
    DriveApp.getFileById(row[idIndex]).setTrashed(true);
    trashed += 1;
  });
  Logger.log(`Elements places dans la corbeille : ${trashed}`);
}

function appliquerPlanDeRenommage() {
  assertRoot();
  if (!APPLY_PLAN) throw new Error("Definissez APPLY_PLAN = true apres verification du plan.");
  if (!PLAN_FILE_ID) throw new Error("Renseignez PLAN_FILE_ID.");
  const rows = Utilities.parseCsv(DriveApp.getFileById(PLAN_FILE_ID).getBlob().getDataAsString("UTF-8"));
  rows.shift();
  const root = DriveApp.getFolderById(ROOT_FOLDER_ID);
  let renamed = 0;
  rows.forEach(([type, theme, oldName, newName, action]) => {
    if (type !== "Dossier" || String(action).toLowerCase() !== "renommer") return;
    const themeFolders = root.getFoldersByName(theme);
    if (!themeFolders.hasNext()) throw new Error(`Theme introuvable : ${theme}`);
    const matches = themeFolders.next().getFoldersByName(oldName);
    if (!matches.hasNext()) throw new Error(`Dossier introuvable : ${theme}/${oldName}`);
    matches.next().setName(newName);
    renamed += 1;
  });
  Logger.log(`Dossiers renommes : ${renamed}`);
}

function parcourir(folder, path, rows) {
  const nextPath = path.concat(folder.getName());
  const files = folder.getFiles();
  while (files.hasNext()) {
    const file = files.next();
    const mime = file.getMimeType();
    if (!MEDIA_MIME_PREFIXES.some((prefix) => mime.startsWith(prefix))) continue;
    const relative = nextPath.slice(1);
    rows.push([
      relative[0] || "",
      relative.slice(1).join(" / "),
      file.getName(),
      mime.startsWith("image/") ? "Photo" : "Video",
      file.getSize(),
      file.getId(),
      `https://drive.google.com/file/d/${file.getId()}/view`,
    ]);
  }
  const folders = folder.getFolders();
  while (folders.hasNext()) parcourir(folders.next(), nextPath, rows);
}

function remplacerCsv(folder, name, rows) {
  const existing = folder.getFilesByName(name);
  while (existing.hasNext()) existing.next().setTrashed(true);
  folder.createFile(name, rows.map((row) => row.map(csvCell).join(",")).join("\n"), MimeType.CSV);
}

function csvCell(value) {
  return `"${String(value).replace(/"/g, '""')}"`;
}

function assertRoot() {
  if (ROOT_FOLDER_ID === "COLLEZ_ICI_L_ID_DU_DOSSIER_RACINE") throw new Error("Renseignez ROOT_FOLDER_ID.");
}
