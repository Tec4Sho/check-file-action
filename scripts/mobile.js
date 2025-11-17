// Source - https://stackoverflow.com/a
// Posted by vhs, modified by community. See post 'Timeline' for change history
// Retrieved 2025-11-16, License - CC BY-SA 4.0

if (window.matchMedia("(min-width: 400px)").matches) {
  /* the viewport is at least 400 pixels wide */
  return true;
} else {
  /* the viewport is less than 400 pixels wide */
  return false;
}
