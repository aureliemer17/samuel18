// Progression locale par navigateur de la machine 46.
window.MACHINE46_PROGRESS = (() => {
  const key = "unlock-machine-46-progress-v1";
  const empty = () => ({ discovered: false, authenticated: false, puzzles: {} });

  function read() {
    try {
      const value = JSON.parse(localStorage.getItem(key) || "null");
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
  function authenticate() { return update((value) => { value.discovered = true; value.authenticated = true; }); }
  function solve(id, submittedAnswer, archiveCodes) {
    return update((value) => {
      value.puzzles[id] ||= { solved: true, submittedAnswer, archiveCodes, solvedAt: new Date().toISOString() };
    });
  }

  return { read, discover, authenticate, solve };
})();
