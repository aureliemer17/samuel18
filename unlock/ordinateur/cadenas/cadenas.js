(() => {
  const app = document.querySelector("#app");
  const id = new URLSearchParams(location.search).get("id");
  const puzzle = window.ORDINATEUR_COMMON.puzzleById(id);
  const progress = window.ORDINATEUR_PROGRESS;
  if (!puzzle || puzzle.template !== "cadenas") { app.textContent = "Cadenas indisponible."; return; }

  const data = puzzle.data;
  const colors = [
    ["orange", "Orange", "#ffae00"], ["bleu-fonce", "Bleu foncé", "#2874bb"], ["vert", "Vert", "#04ae7a"],
    ["rouge", "Rouge", "#ff6859"], ["violet", "Violet", "#8b7eef"], ["gris", "Gris", "#bcbcbc"],
    ["bleu-clair", "Bleu clair", "#8bc4ef"], ["jaune", "Jaune", "#fff7bd"]
  ];
  let state = progress.cadenas(id);
  state.values ||= [];
  let helpOpen = false;
  let message = "";

  const save = () => progress.saveCadenas(id, state);
  const isSolved = () => state.status === "solved";
  const isComplete = () => state.values.length === data.length && state.values.every(Boolean);
  const isCorrect = () => data.inputType === "couleurs"
    ? state.values.join("|") === data.answer.join("|")
    : state.values.join("") === data.answer;

  function render() {
    const input = data.inputType === "chiffres"
      ? `<div class="keypad">${[1, 2, 3, 4, 5, 6, 7, 8, 9, 0].map((value) => `<button class="button" data-value="${value}">${value}</button>`).join("")}</div>`
      : data.inputType === "couleurs"
        ? `<div class="palette">${colors.map(([value, label, color]) => `<button class="color-choice" data-value="${value}" style="background:${color}" aria-label="${label}"></button>`).join("")}</div>`
        : `<input class="letter-input" id="letters" inputmode="text" autocomplete="off" autocorrect="off" autocapitalize="characters">`;
    const slots = Array.from({ length:data.length }, (_, index) => {
      const value = state.values[index] || "";
      const color = colors.find(([token]) => token === value);
      return `<button class="slot ${color ? "color" : ""} ${state.activeIndex === index ? "active" : ""}" data-slot="${index}" ${color ? `style="background:${color[2]}"` : ""}>${color ? "" : value}</button>`;
    }).join("");
    const archiveLinks = puzzle.archiveCodes.map((code) => `<a class="button" href="../../archives/media.html#code=${encodeURIComponent(code)}&from=ordinateur">Archive ${code}</a>`).join("");

    app.innerHTML = `<header class="puzzle-header"><div class="header-row"><p class="puzzle-id">Énigme ${puzzle.id}</p><div class="header-actions"><button class="header-button" id="back" type="button" aria-label="Retour">←</button><button class="header-button" id="off" type="button" aria-label="Éteindre">⏻</button></div></div><div class="title-row"><h1>${puzzle.title}</h1><button class="help-button" id="help" type="button" aria-expanded="${helpOpen}">?</button></div></header>${helpOpen ? `<p class="instructions">${puzzle.instructions}</p>` : ""}<div class="layout"><section class="panel game"><img class="puzzle-image" src="${data.image}" alt="Indices du cadenas"><div class="answer">${slots}</div></section><aside class="panel controls">${input}<button class="button restart" id="restart" type="button">↻ Recommencer</button><p class="message ${isSolved() ? "success" : ""}">${message || (isSolved() ? `Cadenas ouvert : ${Array.isArray(data.answer) ? data.answer.join(" / ") : data.answer}` : "")}</p>${isSolved() ? `<div class="archive-links">${archiveLinks}</div>` : ""}</aside></div>`;

    app.querySelector("#help").addEventListener("click", () => { helpOpen = !helpOpen; render(); });
    app.querySelector("#back").addEventListener("click", () => location.assign("../../jeu/ordinateur.html?category=cadenas"));
    app.querySelector("#off").addEventListener("click", () => {
      if (window.parent !== window) window.parent.postMessage({ type:"s18-computer-off" }, "*");
      else location.assign("../../jeu/ordinateur.html");
    });
    app.querySelectorAll("[data-slot]").forEach((slot) => slot.addEventListener("click", () => {
      state.activeIndex = Number(slot.dataset.slot);
      save();
      render();
      if (data.inputType === "lettres" && !isSolved()) app.querySelector("#letters").focus();
    }));
    app.querySelectorAll("[data-value]").forEach((button) => button.addEventListener("click", () => put(button.dataset.value)));
    app.querySelector("#restart").addEventListener("click", () => {
      if (!confirm("Effacer toutes les cases marquées ?")) return;
      progress.resetCadenas(id);
      state = progress.cadenas(id);
      state.values = [];
      message = "";
      render();
    });

    const letters = app.querySelector("#letters");
    if (!letters) return;
    letters.value = state.values.join("");
    letters.addEventListener("focus", () => document.body.classList.add("keyboard-open"));
    letters.addEventListener("blur", () => document.body.classList.remove("keyboard-open"));
    letters.addEventListener("input", () => {
      state.values = [...letters.value.toUpperCase().replace(/[^A-Z]/g, "")].slice(0, data.length);
      state.activeIndex = state.values.length < data.length ? state.values.length : null;
      changed();
    });
  }

  function put(value) {
    let index = state.activeIndex ?? state.values.findIndex((entry) => !entry);
    if (index < 0) index = 0;
    state.values[index] = value;
    state.activeIndex = index + 1 < data.length ? index + 1 : null;
    changed();
  }

  function changed() {
    message = "";
    state.status = state.values.some(Boolean) ? "in_progress" : "not_started";
    if (isComplete()) {
      if (isCorrect()) {
        state.status = "solved";
        state.answer = state.values.join("");
        progress.solve(id, state.answer, puzzle.archiveCodes);
      } else message = "Code incorrect. Réessayez.";
    }
    save();
    render();
  }

  render();
})();
