function menuImagePath(name) {
  if (!name) return null;
  return `assets/${String(name).trim()}.png`;
}

module.exports = {
  menuImagePath,
};
