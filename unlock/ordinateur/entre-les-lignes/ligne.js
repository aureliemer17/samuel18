(() => {
  const app = document.querySelector("#app");
  const id = new URLSearchParams(location.search).get("id");
  const common = window.ORDINATEUR_COMMON;
  const progress = window.ORDINATEUR_PROGRESS;
  const puzzle = common.puzzleById(id);
  const fromComputer = new URLSearchParams(location.search).get("from") === "ordinateur";
  const backHref = fromComputer ? "../../jeu/ordinateur.html" : "index.html";
  const normalize = (value) => value.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toUpperCase();
  const isLetter = (character) => /[A-Za-zÀ-ÖØ-öø-ÿ]/.test(character);
  if (!puzzle || puzzle.template !== "ligne" || !puzzle.data?.image) {
    app.innerHTML = `<p>Énigme indisponible.</p><a class="back" href="${backHref}">← Retour</a>`;
    return;
  }
  const answer = puzzle.acceptedAnswers[0];
  const characters = [...answer];
  const slots = characters.map((character, index) => isLetter(character) ? { index, character, normalized:normalize(character) } : null);
  const counts = slots.filter(Boolean).reduce((result, slot) => ({ ...result, [slot.normalized]:(result[slot.normalized] || 0) + 1 }), {});
  let state = progress.ligne(id);
  state.values ||= {};
  state.activeIndex ??= null;
  let message = "";
  const archiveLinks = () => `<div class="archive-links">${puzzle.archiveCodes.map((code) => `<a class="button" href="../../archives/media.html#code=${encodeURIComponent(code)}&from=ordinateur">Archive ${code}</a>`).join("")}</div>`;
  const available = (letter, target = null) => counts[letter] - Object.entries(state.values).filter(([index, value]) => Number(index) !== target && value === letter).length;
  const emptyIndexes = () => slots.filter((slot) => slot && !state.values[slot.index]).map((slot) => slot.index);
  const nextIndex = (from) => {
    const empty = emptyIndexes();
    return empty.find((index) => index > from) ?? empty[0] ?? null;
  };
  const save = () => progress.saveLigne(id, state);
  function render() {
    const solved = state.status === "solved";
    const expression = [];
    let word = [];
    const flushWord = () => { if (word.length) { expression.push(`<span class="word">${word.join("")}</span>`); word = []; } };
    characters.forEach((character, index) => {
      const slot = slots[index];
      if (!slot) {
        if (/\s/.test(character)) { flushWord(); expression.push(`<span class="separator">${character}</span>`); }
        else word.push(`<span class="separator">${character}</span>`);
        return;
      }
      const value = solved ? slot.character.toUpperCase() : state.values[index] || "";
      word.push(`<button class="letter ${state.activeIndex === index ? "active" : ""} ${solved ? "locked" : ""}" data-slot="${index}" ${solved ? "disabled" : ""}>${value}</button>`);
    });
    flushWord();
    const tiles = Object.keys(counts).sort((left, right) => left.localeCompare(right, "fr")).map((letter) => `<button class="tile ${available(letter, state.activeIndex) ? "" : "exhausted"}" data-letter="${letter}" ${solved ? "disabled" : ""}>${letter}<span class="tile-count">${available(letter, state.activeIndex)}</span></button>`).join("");
    const reset = solved ? "" : `<button class="button" id="reset">Réinitialiser</button>`;
    app.innerHTML = `<a class="back" href="${backHref}">← ${fromComputer ? "Bureau des énigmes" : "Catalogue"}</a><p class="eyebrow">Ordinateur des énigmes / Entre les lignes</p><h1>${puzzle.title}</h1><p>Trouvez l’expression représentée par l’image.</p><div class="game"><section class="panel"><img class="image" src="${puzzle.data.image}" alt="Illustration de l’énigme" /></section><section class="panel"><div class="expression" aria-label="Expression à reconstituer">${expression.join("")}</div><h2>Réserve de lettres</h2><div class="tiles">${tiles}</div><div class="actions"><button class="button" id="erase" ${solved ? "disabled" : ""}>Effacer</button>${reset}</div><p class="message ${solved ? "success" : ""}">${message || (solved ? `Résolu : ${answer}` : "")}</p>${solved ? archiveLinks() : ""}</section></div>`;
    app.querySelectorAll("[data-slot]").forEach((button) => button.addEventListener("click", () => { state.activeIndex = Number(button.dataset.slot); save(); render(); }));
    app.querySelectorAll("[data-letter]").forEach((button) => button.addEventListener("click", () => place(button.dataset.letter)));
    app.querySelector("#erase").addEventListener("click", erase);
    app.querySelector("#reset")?.addEventListener("click", () => { progress.resetLigne(id); state = progress.ligne(id); state.values ||= {}; state.activeIndex = null; message = "Réponse réinitialisée."; render(); });
  }
  function place(letter) {
    const target = state.activeIndex ?? emptyIndexes()[0];
    if (target === undefined || target === null) return;
    if (state.status === "solved" || !available(letter, target)) return;
    state.values[target] = letter;
    state.activeIndex = nextIndex(target);
    state.status = "in_progress";
    message = "";
    save();
    if (emptyIndexes().length === 0) verify(); else render();
  }
  function erase() {
    if (state.status === "solved") return;
    const target = state.activeIndex ?? [...slots].reverse().find((slot) => slot && state.values[slot.index])?.index;
    if (target === undefined || target === null) return;
    delete state.values[target];
    state.activeIndex = target;
    state.status = Object.keys(state.values).length ? "in_progress" : "not_started";
    message = "";
    save();
    render();
  }
  function verify() {
    const submitted = slots.filter(Boolean).map((slot) => state.values[slot.index]).join("");
    const expected = slots.filter(Boolean).map((slot) => slot.normalized).join("");
    if (submitted !== expected) { message = "Expression incorrecte. Modifiez les lettres et réessayez."; render(); return; }
    state.status = "solved";
    state.answer = answer;
    state.archiveCodes = puzzle.archiveCodes;
    progress.solve(id, answer, puzzle.archiveCodes);
    save();
    render();
  }
  window.addEventListener("keydown", (event) => { const letter = normalize(event.key); if (/^[A-Z]$/.test(letter)) place(letter); if (event.key === "Backspace" || event.key === "Delete") erase(); });
  render();
})();
