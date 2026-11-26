// Progression locale par navigateur de l'ordinateur.
window.ORDINATEUR_PROGRESS = (() => {
  const key = "unlock-ordinateur-progress-v1";
  const legacyKey = "unlock-machine-46-progress-v1";
  const empty = () => ({ discovered: false, authenticated: false, poweredOn: false, view: { name: "login" }, puzzles: {} });

  function read() {
    try {
      const value = JSON.parse(localStorage.getItem(key) || localStorage.getItem(legacyKey) || "null");
      return value && typeof value === "object" ? { ...empty(), ...value, puzzles: value.puzzles || {} } : empty();
    } catch {
      return empty();
    }
  }

  function write(value) {
    try { localStorage.setItem(key, JSON.stringify(value)); } catch { /* Progress remains optional. */ }
    return value;
  }

  function update(change) {
    const value = read();
    change(value);
    return write(value);
  }

  function discover() { return update((value) => { value.discovered = true; }); }
  function setPoweredOn(poweredOn) { return update((value) => { value.poweredOn = poweredOn; }); }
  function setView(view) { return update((value) => { value.view = view; }); }
  function authenticate() { return update((value) => { value.discovered = true; value.authenticated = true; }); }
  function solve(id, submittedAnswer, archiveCodes) {
    return update((value) => {
      value.puzzles[id] ||= { solved: true, submittedAnswer, archiveCodes, solvedAt: new Date().toISOString() };
    });
  }

  function sudoku(id) {
    return read().sudoku?.[id] || { status: "not_started", values: {}, notes: {}, history: [] };
  }

  function saveSudoku(id, entry) {
    return update((value) => {
      value.sudoku ||= {};
      value.sudoku[id] = { ...entry, lastUpdated: new Date().toISOString() };
    });
  }

  function resetSudoku(id) {
    return update((value) => { if (value.sudoku?.[id]?.status !== "solved") delete value.sudoku[id]; });
  }

  function reset() {
    try { localStorage.removeItem(key); localStorage.removeItem(legacyKey); } catch { /* Progress remains optional. */ }
  }

  return { read, discover, setPoweredOn, setView, authenticate, solve, sudoku, saveSudoku, resetSudoku, reset };
})();
