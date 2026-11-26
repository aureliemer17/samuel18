(() => {
  const app = document.querySelector("#app");
  const id = new URLSearchParams(location.search).get("id");
  const common = window.ORDINATEUR_COMMON;
  const progress = window.ORDINATEUR_PROGRESS;
  const puzzle = common.puzzleById(id);
  if (!puzzle || puzzle.template !== "sudoku" || !puzzle.data?.initialGrid) {
    app.innerHTML = `<p>Sudoku indisponible.</p><a class="back" href="index.html">← Catalogue Sudoku</a>`;
    return;
  }
  const { size, boxRows, boxCols, initialGrid, solution } = puzzle.data;
  let state = progress.sudoku(id);
  state.values ||= {};
  state.notes ||= {};
  state.history ||= [];
  let selected = null;
  let notesMode = false;
  let helpOpen = false;
  let restartConfirmation = false;
  const key = (row, col) => `${row}-${col}`;
  const valueAt = (row, col) => initialGrid[row][col] || state.values[key(row, col)] || "";
  const save = () => progress.saveSudoku(id, state);
  const fromComputer = new URLSearchParams(location.search).get("from") === "ordinateur";
  const backHref = fromComputer ? "../../jeu/ordinateur.html" : "index.html";
  const archiveLinks = () => `<div class="archive-links">${puzzle.archiveCodes.map((code) => `<a class="button" href="../../archives/media.html#code=${encodeURIComponent(code)}&from=ordinateur">Archive ${code}</a>`).join("")}</div>`;
  function render(message = "") {
    const solved = state.status === "solved";
    const cells = [];
    for (let row = 0; row < size; row += 1) for (let col = 0; col < size; col += 1) {
      const cellKey = key(row, col);
      const value = valueAt(row, col);
      const classes = ["cell", initialGrid[row][col] ? "fixed" : "", selected?.[0] === row && selected?.[1] === col ? "selected" : "", !value && state.notes[cellKey]?.length ? "note" : ""].filter(Boolean).join(" ");
      const border = `${(col + 1) % boxCols === 0 && col + 1 < size ? "border-right:3px solid #315e35;" : ""}${(row + 1) % boxRows === 0 && row + 1 < size ? "border-bottom:3px solid #315e35;" : ""}`;
      cells.push(`<button class="${classes}" data-row="${row}" data-col="${col}" data-notes="${(state.notes[cellKey] || []).join(" ")}" style="${border}" ${initialGrid[row][col] || solved ? "disabled" : ""}>${value}</button>`);
    }
    const restartControls = restartConfirmation ? `<div class="restart-confirmation"><p>Effacer toutes les cases et notes ?</p><button class="button" id="cancelRestart">Annuler</button><button class="button danger" id="confirmRestart">Effacer la grille</button></div>` : `<button class="button" id="restart" ${solved ? "disabled" : ""}>Recommencer</button>`;
    app.innerHTML = `<a class="back" href="${backHref}">← ${fromComputer ? "Bureau des énigmes" : "Catalogue Sudoku"}</a><p class="eyebrow">Ordinateur des énigmes / Sudoku</p><div class="title-row"><h1>${puzzle.title}</h1><button class="help-button" id="help" type="button" aria-expanded="${helpOpen}" aria-controls="instructions">?</button></div>${helpOpen ? `<p class="instructions" id="instructions">${puzzle.instructions}</p>` : ""}<div class="layout"><section class="panel"><div class="grid" style="--size:${size};--box-cols:${boxCols}">${cells.join("")}</div></section><aside class="panel controls"><div class="keypad" id="keypad" style="--keypad-cols:${Math.min(size, 6)}">${Array.from({ length:size }, (_, index) => `<button class="button" data-value="${index + 1}">${index + 1}</button>`).join("")}</div><div class="entry-actions"><button class="button" data-action="erase" id="erase">Effacer</button><button class="button ${notesMode ? "active" : ""}" id="notes">Notes : ${notesMode ? "actives" : "inactives"}</button></div><button class="button" id="undo" ${state.history.length ? "" : "disabled"}>Annuler</button>${restartControls}<button class="button" id="verify" ${solved ? "disabled" : ""}>Vérifier la grille</button><p class="message ${solved ? "success" : ""}">${message || (solved ? `Résolu. Codes obtenus : ${state.archiveCodes.join(" · ")}` : "")}</p>${solved ? archiveLinks() : ""}</aside></div>`;
    app.querySelectorAll(".cell:not(.fixed)").forEach((cell) => cell.addEventListener("click", () => { selected = [Number(cell.dataset.row), Number(cell.dataset.col)]; render(); }));
    app.querySelector("#help").addEventListener("click", () => { helpOpen = !helpOpen; render(); });
    app.querySelector("#notes").addEventListener("click", () => { notesMode = !notesMode; render(); });
    app.querySelector("#keypad").addEventListener("click", (event) => apply(event.target.dataset.value, event.target.dataset.action));
    app.querySelector("#erase").addEventListener("click", (event) => apply(event.target.dataset.value, event.target.dataset.action));
    app.querySelector("#undo").addEventListener("click", undo);
    app.querySelector("#restart")?.addEventListener("click", () => { restartConfirmation = true; render(); });
    app.querySelector("#cancelRestart")?.addEventListener("click", () => { restartConfirmation = false; render(); });
    app.querySelector("#confirmRestart")?.addEventListener("click", restart);
    app.querySelector("#verify").addEventListener("click", verify);
  }
  function apply(value, action) {
    if (!selected || state.status === "solved") return;
    const cellKey = key(...selected);
    state.history.push({ values:{ ...state.values }, notes:JSON.parse(JSON.stringify(state.notes)) });
    if (action === "erase") { delete state.values[cellKey]; delete state.notes[cellKey]; }
    else if (notesMode) { const notes = new Set(state.notes[cellKey] || []); notes.has(value) ? notes.delete(value) : notes.add(value); state.notes[cellKey] = [...notes].sort(); }
    else { state.values[cellKey] = Number(value); delete state.notes[cellKey]; }
    state.status = "in_progress";
    save();
    if (!notesMode && !action && isComplete()) return verify();
    render();
  }
  function undo() { const previous = state.history.pop(); if (!previous) return; state.values = previous.values; state.notes = previous.notes; state.status = Object.keys(state.values).length ? "in_progress" : "not_started"; save(); render(); }
  function restart() { progress.resetSudoku(id); state = progress.sudoku(id); state.values ||= {}; state.notes ||= {}; state.history ||= []; selected = null; restartConfirmation = false; render("Grille recommencée."); }
  function isComplete() { return Array.from({ length:size }, (_, row) => Array.from({ length:size }, (_, col) => valueAt(row, col))).every((row) => row.every(Boolean)); }
  function verify() { const values = Array.from({ length:size }, (_, row) => Array.from({ length:size }, (_, col) => Number(valueAt(row, col)))); if (values.some((row) => row.some((value) => !value))) return render("La grille est incomplète."); if (values.some((row, r) => row.some((value, c) => value !== solution[r][c]))) return render("Cette grille n’est pas correcte. Réessayez."); state.status = "solved"; state.notes = {}; state.archiveCodes = puzzle.archiveCodes; progress.solve(id, values.map((row) => row.join("")).join("/"), puzzle.archiveCodes); save(); render(); }
  window.addEventListener("keydown", (event) => { if (event.key >= "1" && event.key <= String(size)) apply(event.key); if (event.key === "Backspace" || event.key === "Delete") apply(null, "erase"); });
  render();
})();
