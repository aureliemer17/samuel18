// Configuration unique de l'énigme.
// Modifiez uniquement les valeurs de ce fichier pour ajouter des machines ou changer les codes affichés.
window.PUZZLE_CONFIG = {
  machines: {
    10: "ascenseur.html",
    11: "cle.html",
    37: "archive.html",
  },
  archives: {
    categories: {
      I: "Disparitions mystérieuses",
      II: "Un esprit scientifique",
      III: "Le monde selon Samuel",
      IV: "Sport",
      V: "Archives audiovisuelles",
      VI: "Liens indéfectibles",
      VII: "Affaires non classées",
    },
    // Ce bloc est généré par generer-config-archives.mjs depuis archive/dossiers.
    media: {
      "I-A-1": {
        title: "Le Kart- une grande histoire",
        instruction: "dossiers/I%20-%20Disparitions%20myste%CC%81rieuses/I-A-1/instruction.txt",
        items: [
          { title: "anecdote kart", type: "document", source: "dossiers/I%20-%20Disparitions%20myste%CC%81rieuses/I-A-1/anecdote-kart.html" },
          { title: "Copie de PICT0016", type: "image", source: "dossiers/I%20-%20Disparitions%20myste%CC%81rieuses/I-A-1/Copie%20de%20PICT0016.jpg", createdAt: "07 août 2005" },
          { title: "Copie de PICT0020", type: "image", source: "dossiers/I%20-%20Disparitions%20myste%CC%81rieuses/I-A-1/Copie%20de%20PICT0020.jpg", createdAt: "07 août 2005" },
        ],
      },
      "I-C-8": {
        title: "L'hivers est fou",
        items: [
          { title: "Winter Party 2   The Fire Challenge", type: "video", source: "dossiers/I%20-%20Disparitions%20myste%CC%81rieuses/I-C-8/Winter%20Party%202%20-%20The%20Fire%20Challenge.mov", createdAt: "03 mars 2025" },
        ],
      },
      "II-B-3": {
        title: "Ceci est un test, oui Monsieur",
        instruction: "dossiers/II%20-%20Un%20esprit%20scientifique/II-B-3/instruction.html",
        items: [
          { title: "Enregistrement de l’écran 2026 09 06 à 07.04.11", type: "video", source: "dossiers/II%20-%20Un%20esprit%20scientifique/II-B-3/Enregistrement%20de%20l%E2%80%99e%CC%81cran%202026-09-06%20a%CC%80%2007.04.11.mov", createdAt: "06 septembre 2026" },
          { title: "samuel le scientifique", type: "document", source: "dossiers/II%20-%20Un%20esprit%20scientifique/II-B-3/samuel-le-scientifique.txt" },
        ],
      },
    },
  },
  pages: {
    ascenseur: {
      unlockCode: "15",
    },
    boiteACle: {
      entryCode: "519223",
      unlockCode: "22",
    },
  },
};
