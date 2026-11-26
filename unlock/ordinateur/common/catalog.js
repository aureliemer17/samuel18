window.ORDINATEUR_COMMON = (() => {
  const catalog = () => window.ORDINATEUR_CATALOG;
  const activePuzzles = () => catalog().puzzles.filter((puzzle) => puzzle.enabled && puzzle.admin?.published);
  const puzzleById = (id) => activePuzzles().find((puzzle) => puzzle.id === id);
  const categoryById = (id) => catalog().categories.find((category) => category.id === id);
  return { activePuzzles, puzzleById, categoryById };
})();
