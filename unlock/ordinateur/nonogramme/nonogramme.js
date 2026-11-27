(() => {
  const app = document.querySelector("#app");
  const id = new URLSearchParams(location.search).get("id");
  const common = window.ORDINATEUR_COMMON;
  const progress = window.ORDINATEUR_PROGRESS;
  const puzzle = common.puzzleById(id);
  const params = new URLSearchParams(location.search);
  const fromComputer = params.get("from") === "ordinateur";
  const embedded = params.get("embedded") === "1";
  if (embedded && window.matchMedia("(min-width: 701px)").matches) document.documentElement.classList.add("embedded");
  const backHref = fromComputer ? "../../jeu/ordinateur.html?category=nonogramme" : "../../jeu/ordinateur.html?category=nonogramme";
  if (!puzzle || puzzle.template !== "nonogramme" || !puzzle.data?.solution) { app.innerHTML = `<p>Nonogramme indisponible.</p>`; return; }
  const { rows, cols, solution } = puzzle.data;
  let state = progress.nonogramme(id);
  state.cells ||= {};
  state.history ||= [];
  let mode = "black";
  let helpOpen = false;
  let restartConfirmation = false;
  let dragging = false;
  let draggedCells = new Set();
  const cellKey = (row, col) => `${row}-${col}`;
  const clues = (line) => { const groups = []; let count = 0; line.forEach((value) => { if (value) count += 1; else if (count) { groups.push(count); count = 0; } }); if (count) groups.push(count); return groups.length ? groups : [0]; };
  const rowClues = solution.map(clues);
  const colClues = Array.from({ length:cols }, (_, col) => clues(solution.map((row) => row[col])));
  const maxTop = Math.max(...colClues.map((clue) => clue.length));
  const maxLeft = Math.max(...rowClues.map((clue) => clue.length));
  const save = () => progress.saveNonogramme(id, state);
  const archiveLinks = () => `<div class="archive-links">${puzzle.archiveCodes.map((code) => `<a class="button" href="../../archives/media.html#code=${encodeURIComponent(code)}&from=ordinateur" target="_top">Archive ${code}</a>`).join("")}</div>`;
  const matchesSolution = () => solution.every((row, rowIndex) => row.every((value, colIndex) => (state.cells[cellKey(rowIndex, colIndex)] === "black") === Boolean(value)));
  function render(message = "") {
    const solved = state.status === "solved";
    const boardActions = restartConfirmation ? `<div class="restart-confirmation"><p>Effacer toutes les cases marquées ?</p><div class="restart-actions"><button class="button" id="cancelRestart">Non</button><button class="button" id="confirmRestart">Oui, effacer</button></div></div>` : `<div class="board-actions"><div class="mode-toggle" role="group" aria-label="Marquage des cases"><button class="mode-toggle-button ${mode === "black" ? "active" : ""}" data-mode="black" type="button" aria-label="Marquer en noir" aria-pressed="${mode === "black"}"><span class="mode-icon mode-icon--black" aria-hidden="true"></span></button><button class="mode-toggle-button ${mode === "empty" ? "active" : ""}" data-mode="empty" type="button" aria-label="Marquer barré" aria-pressed="${mode === "empty"}"><span class="mode-icon mode-icon--empty" aria-hidden="true">×</span></button></div><button class="icon-button" id="restart" type="button" aria-label="Recommencer" title="Recommencer">↻</button></div>`;
    let board = "";
    for (let top = 0; top < maxTop; top += 1) { for (let left = 0; left < maxLeft; left += 1) board += `<div class="clue"></div>`; for (let col = 0; col < cols; col += 1) board += `<div class="clue top"><span>${colClues[col][top - (maxTop - colClues[col].length)] || ""}</span></div>`; }
    for (let row = 0; row < rows; row += 1) { for (let left = 0; left < maxLeft; left += 1) board += `<div class="clue left"><span>${rowClues[row][left - (maxLeft - rowClues[row].length)] || ""}</span></div>`; for (let col = 0; col < cols; col += 1) { const value = state.cells[cellKey(row, col)] || ""; const majorRight = (col + 1) % 5 === 0 && col + 1 < cols ? "major-right" : ""; const majorBottom = (row + 1) % 5 === 0 && row + 1 < rows ? "major-bottom" : ""; board += `<button class="cell ${value} ${solved ? "locked" : ""} ${majorRight} ${majorBottom}" data-row="${row}" data-col="${col}" ${solved ? "disabled" : ""}></button>`; } }
    app.innerHTML = `<header class="puzzle-header"><div class="header-row"><p class="puzzle-id">Énigme ${puzzle.id}</p><div class="header-actions"><button class="header-button" id="back" type="button" aria-label="Retour">←</button><button class="header-button header-button--off" id="off" type="button" aria-label="Éteindre">⏻</button></div></div><div class="title-row"><h1>${puzzle.title}</h1><div class="title-actions"><button class="help-button" id="help" type="button" aria-expanded="${helpOpen}" aria-controls="instructions">?</button></div></div></header>${helpOpen ? `<p class="instructions" id="instructions">${puzzle.instructions}</p>` : ""}<div class="layout"><section class="board-panel"><div class="board-scroll"><div class="board" style="--grid-cols:${cols + maxLeft};--grid-rows:${rows + maxTop};--cell:clamp(16px,3.7vw,29px)">${board}</div></div>${boardActions}</section><aside class="controls"><p class="message ${solved ? "success" : ""}">${message || (solved ? `Résolu. Codes obtenus : ${state.archiveCodes.join(" · ")}` : "")}</p>${solved ? archiveLinks() : ""}</aside></div>`;
    app.querySelector("#help").addEventListener("click", () => { helpOpen = !helpOpen; render(); });
    app.querySelector("#back").addEventListener("click", () => window.location.assign(backHref));
    app.querySelector("#off").addEventListener("click", () => { if (window.parent !== window) window.parent.postMessage({ type:"s18-computer-off" }, "*"); else { progress.setPoweredOn(false); window.location.assign("../../jeu/ordinateur.html"); } });
    app.querySelectorAll("[data-mode]").forEach((button) => button.addEventListener("click", () => { mode = button.dataset.mode; dragging = false; draggedCells = new Set(); render(); }));
    app.querySelectorAll(".cell").forEach((cell) => {
      const markCell = () => mark(Number(cell.dataset.row), Number(cell.dataset.col));
      cell.addEventListener("pointerdown", (event) => { event.preventDefault(); dragging = true; draggedCells = new Set(); markCell(); });
      cell.addEventListener("pointerenter", () => { if (dragging) markCell(); });
    });
    app.querySelector("#restart").addEventListener("click", () => { restartConfirmation = true; render(); });
    app.querySelector("#cancelRestart")?.addEventListener("click", () => { restartConfirmation = false; render(); });
    app.querySelector("#confirmRestart")?.addEventListener("click", restart);
  }
  function mark(row, col) { if (state.status === "solved") return; const key = cellKey(row, col); if (draggedCells.has(key)) return; draggedCells.add(key); if (state.cells[key] === mode) delete state.cells[key]; else state.cells[key] = mode; state.status = Object.keys(state.cells).length ? "in_progress" : "not_started"; save(); if (matchesSolution()) solve(); else render(); }
  function restart() { progress.resetNonogramme(id); state = progress.nonogramme(id); state.cells ||= {}; state.history ||= []; restartConfirmation = false; render("Grille recommencée."); }
  function solve() { state.status = "solved"; state.archiveCodes = puzzle.archiveCodes; progress.solve(id, "nonogramme", puzzle.archiveCodes); save(); render(); }
  function returnToComputerLayout() { if (fromComputer && window.matchMedia("(min-width: 701px)").matches) window.location.assign(`../../jeu/ordinateur.html?puzzle=${encodeURIComponent(id)}`); }
  window.addEventListener("resize", returnToComputerLayout);
  window.addEventListener("pointermove", (event) => { if (!dragging) return; event.preventDefault(); const cell = document.elementFromPoint(event.clientX, event.clientY)?.closest(".cell"); if (cell) mark(Number(cell.dataset.row), Number(cell.dataset.col)); }, { passive:false });
  window.addEventListener("pointerup", () => { dragging = false; draggedCells = new Set(); });
  window.addEventListener("pointercancel", () => { dragging = false; draggedCells = new Set(); });
  render();
})();
