// Suivi local des dossiers consultés. Les données restent dans ce navigateur.
window.ARCHIVE_PROGRESS = (() => {
  const viewedKey = "unlock-archive-viewed";
  const resetKey = "unlock-archive-progress-reset-key";

  function resetIfNeeded() {
    try {
      const configuredKey = window.ARCHIVE_CONFIG.progressResetKey;
      if (localStorage.getItem(resetKey) !== configuredKey) {
        localStorage.removeItem(viewedKey);
        localStorage.setItem(resetKey, configuredKey);
      }
    } catch {
      // Progress is optional if the browser blocks local storage for file:// pages.
    }
  }

  function viewedCodes() {
    resetIfNeeded();
    try {
      return new Set(JSON.parse(localStorage.getItem(viewedKey) || "[]"));
    } catch {
      return new Set();
    }
  }

  function markViewed(code) {
    const codes = viewedCodes();
    codes.add(code);
    try {
      localStorage.setItem(viewedKey, JSON.stringify([...codes]));
    } catch {
      // The archive remains usable without progress persistence.
    }
  }

  function reset() {
    try {
      localStorage.removeItem(viewedKey);
      localStorage.setItem(resetKey, window.ARCHIVE_CONFIG.progressResetKey);
    } catch {
      // The archive remains usable without progress persistence.
    }
  }

  return { markViewed, reset, viewedCodes };
})();
