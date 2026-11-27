(() => {
  const currentVersion = new URLSearchParams(document.currentScript.src.split("?")[1]).get("v");
  let checking = false;

  async function checkForUpdate() {
    if (checking) return;
    checking = true;
    try {
      const response = await fetch(new URL("version.js", document.currentScript.src), { cache:"no-store" });
      const source = await response.text();
      const match = source.match(/SITE_VERSION\s*=\s*["']([^"']+)/);
      const remoteVersion = match?.[1];
      if (remoteVersion && remoteVersion !== currentVersion) {
        const url = new URL(location.href);
        url.searchParams.set("v", remoteVersion);
        location.replace(url);
      }
    } catch {
      // The app remains available offline or when the version check fails.
    } finally {
      checking = false;
    }
  }

  checkForUpdate();
  document.addEventListener("visibilitychange", () => { if (!document.hidden) checkForUpdate(); });
})();
