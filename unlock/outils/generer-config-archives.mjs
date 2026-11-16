#!/usr/bin/env node
import { readdir, readFile, stat, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.dirname(fileURLToPath(import.meta.url));
const unlockRoot = path.join(root, "..");
const archiveRoot = path.join(unlockRoot, "..", "dossiers");
const configPath = path.join(unlockRoot, "config", "archive-config.js");
const codePattern = /^(I|II|III|IV|V|VI|VII)-([A-J])-([1-8])$/;
const ignoredNames = new Set([".DS_Store", "README.md", "titre.txt", "titre.html", "titre.htm", "instruction.txt", "instruction.html", "instruction.htm"]);
const imageExtensions = new Set([".avif", ".gif", ".jpeg", ".jpg", ".png", ".webp"]);
const videoExtensions = new Set([".m4v", ".mov", ".mp4", ".webm"]);
const documentExtensions = new Set([".html", ".htm", ".pdf", ".txt"]);

function escapeJavaScript(value) {
  return JSON.stringify(value).replace(/</g, "\\u003c");
}

function stripHtml(value) {
  return value.replace(/<[^>]*>/g, " ").replace(/\s+/g, " ").trim();
}

async function readTitle(folderPath, code) {
  for (const name of ["titre.html", "titre.htm", "titre.txt"]) {
    try {
      const title = stripHtml(await readFile(path.join(folderPath, name), "utf8"));
      if (title) return title;
    } catch {
      // Try the next supported title filename.
    }
  }
  return `Dossier ${code}`;
}

async function findInstruction(folderPath) {
  for (const name of ["instruction.html", "instruction.htm", "instruction.txt"]) {
    try {
      await readFile(path.join(folderPath, name));
      return `../../dossiers/${encodeURIComponent(path.basename(path.dirname(folderPath)))}/${encodeURIComponent(path.basename(folderPath))}/${encodeURIComponent(name)}`;
    } catch {
      // Try the next supported instruction filename.
    }
  }
  return "";
}

async function listMedia(folderPath, code) {
  const entries = await readdir(folderPath, { withFileTypes: true });
  const files = entries
    .filter((entry) => entry.isFile() && !ignoredNames.has(entry.name) && !entry.name.startsWith("."))
    .map((entry) => entry.name)
    .sort((left, right) => left.localeCompare(right, "fr"));
  const items = [];

  for (const name of files) {
    const extension = path.extname(name).toLowerCase();
    if (!imageExtensions.has(extension) && !videoExtensions.has(extension) && !documentExtensions.has(extension)) {
      console.warn(`Ignoré (${code}) : extension non prise en charge pour ${name}`);
      continue;
    }
    const type = imageExtensions.has(extension) ? "image" : videoExtensions.has(extension) ? "video" : "document";
    const mediaItem = {
      title: path.basename(name, extension).replace(/[-_]/g, " "),
      type,
      source: `../../dossiers/${encodeURIComponent(path.basename(path.dirname(folderPath)))}/${encodeURIComponent(code)}/${encodeURIComponent(name)}`,
    };
    if (type === "image" || type === "video") {
      const metadata = await stat(path.join(folderPath, name));
      mediaItem.createdAt = metadata.birthtime.toLocaleDateString("fr-FR", { day: "2-digit", month: "long", year: "numeric" });
    }
    items.push(mediaItem);
  }
  return items;
}

async function scanArchives() {
  const categories = await readdir(archiveRoot, { withFileTypes: true });
  const media = {};
  for (const category of categories.filter((entry) => entry.isDirectory())) {
    const categoryPath = path.join(archiveRoot, category.name);
    const folders = await readdir(categoryPath, { withFileTypes: true });
    for (const folder of folders.filter((entry) => entry.isDirectory())) {
      const match = folder.name.match(codePattern);
      if (!match) {
        console.warn(`Ignoré : ${category.name}/${folder.name} ne respecte pas le format I-A-1.`);
        continue;
      }
      if (match[1] !== category.name.slice(0, match[1].length)) {
        console.warn(`Attention : ${folder.name} ne correspond pas à la catégorie ${category.name}.`);
      }
      const folderPath = path.join(categoryPath, folder.name);
      const items = await listMedia(folderPath, folder.name);
      media[folder.name] = {
        title: await readTitle(folderPath, folder.name),
        instruction: await findInstruction(folderPath),
        items,
      };
    }
  }
  return Object.fromEntries(Object.entries(media).sort(([left], [right]) => left.localeCompare(right, "fr")));
}

function renderMedia(media) {
  const lines = ["    media: {"];
  for (const [code, item] of Object.entries(media)) {
    lines.push(`      ${escapeJavaScript(code)}: {`);
    lines.push(`        title: ${escapeJavaScript(item.title)},`);
    if (item.instruction) lines.push(`        instruction: ${escapeJavaScript(item.instruction)},`);
    lines.push("        items: [");
    for (const mediaItem of item.items) {
      const date = mediaItem.createdAt ? `, createdAt: ${escapeJavaScript(mediaItem.createdAt)}` : "";
      lines.push(`          { title: ${escapeJavaScript(mediaItem.title)}, type: ${escapeJavaScript(mediaItem.type)}, source: ${escapeJavaScript(mediaItem.source)}${date} },`);
    }
    lines.push("        ],");
    lines.push("      },");
  }
  lines.push("    },");
  return lines.join("\n");
}

const media = await scanArchives();
const config = await readFile(configPath, "utf8");
const generatedBlock = /  \/\/ BEGIN GENERATED MEDIA[^\n]*\n[\s\S]*?  \/\/ END GENERATED MEDIA/;
if (!generatedBlock.test(config)) throw new Error("Le bloc généré est introuvable dans archive-config.js.");
const nextConfig = config.replace(generatedBlock, `  // BEGIN GENERATED MEDIA - généré par generer-config-archives.mjs depuis ../dossiers.\n${renderMedia(media).replace(/^    /gm, "  ")}\n  // END GENERATED MEDIA`);
await writeFile(configPath, nextConfig);
console.log(`Configuration générée : ${Object.keys(media).length} dossier(s) d'archive trouvé(s).`);
