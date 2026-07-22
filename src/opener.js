// Obsidian Opener — a smart Markdown opener for Finder on macOS.
//
//   * A file inside a *registered* Obsidian vault  → opens in Obsidian, in the
//     correct vault, via the `obsidian://open?path=` URL scheme.
//   * A Markdown file *outside* any vault           → opens in a fallback editor
//     (default: Typora).
//   * `.canvas` / `.base` (Obsidian-only formats)   → always routed to Obsidian.
//
// The vault list is read live from Obsidian's own registry on every launch, so
// newly created vaults are picked up automatically. See README for build/usage.
ObjC.import('Foundation');

const FALLBACK_APP = 'Typora';            // editor for Markdown files not in any vault
const OBSIDIAN_EXTS = ['canvas', 'base']; // Obsidian-only formats: always route to Obsidian

function sa() {
  const a = Application.currentApplication();
  a.includeStandardAdditions = true;
  return a;
}

function resolvePath(p) {
  if (!p) return null;
  let s = ObjC.unwrap($(p).stringByResolvingSymlinksInPath);
  if (s.length > 1 && s.endsWith('/')) s = s.slice(0, -1);
  return s;
}

function readVaultPaths() {
  const cfg = ObjC.unwrap($.NSHomeDirectory()) +
    '/Library/Application Support/obsidian/obsidian.json';
  const raw = $.NSString.stringWithContentsOfFileEncodingError(
    cfg, $.NSUTF8StringEncoding, null);
  if (raw.isNil()) return [];
  const json = JSON.parse(ObjC.unwrap(raw));
  return Object.values(json.vaults || {})
    .map(v => resolvePath(v.path))
    .filter(Boolean)
    .sort((a, b) => b.length - a.length); // longest path first → longest-prefix match wins
}

function shQuote(s) { return "'" + s.replace(/'/g, "'\\''") + "'"; }

function openOne(doc, vaults) {
  const p = resolvePath(doc.toString());
  const ext = (p.split('.').pop() || '').toLowerCase();
  const inVault = vaults.some(v => p === v || p.startsWith(v + '/'));
  if (inVault || OBSIDIAN_EXTS.includes(ext)) {
    sa().openLocation('obsidian://open?path=' + encodeURIComponent(p));
  } else {
    sa().doShellScript('open -a ' + shQuote(FALLBACK_APP) + ' ' + shQuote(p));
  }
}

function openDocuments(docs) {
  let vaults = [];
  try { vaults = readVaultPaths(); } catch (e) {}
  for (const d of docs) {
    try { openOne(d, vaults); } catch (e) {
      // Never fall back to a bare `open <file>` here: this app is registered as the
      // default handler, so that would create an infinite loop. Just notify instead.
      try {
        sa().displayNotification(String(d), { withTitle: 'Obsidian Opener failed to open' });
      } catch (_) {}
    }
  }
}

function run() { // double-clicking the app itself → just launch / activate Obsidian
  sa().doShellScript('open -a Obsidian');
}
