#!/bin/zsh
# install.sh — build & install "Obsidian Opener", set it as the default .md handler,
# and add a right-click "Open in Obsidian" Quick Action. Safe to re-run.
set -euo pipefail

HERE="${0:A:h}"
APP="$HOME/Applications/Obsidian Opener.app"
BUNDLE_ID="io.github.obsidian-opener"
PB=/usr/libexec/PlistBuddy

echo '==> [1/3] Building Obsidian Opener.app'
rm -rf "$APP"
mkdir -p "$HOME/Applications"
/usr/bin/osacompile -l JavaScript -o "$APP" "$HERE/src/opener.js"
P="$APP/Contents/Info.plist"
$PB -c "Set :CFBundleIdentifier $BUNDLE_ID" "$P" 2>/dev/null || $PB -c "Add :CFBundleIdentifier string $BUNDLE_ID" "$P"
$PB -c 'Set :CFBundleName "Obsidian Opener"' "$P" 2>/dev/null || $PB -c 'Add :CFBundleName string "Obsidian Opener"' "$P"
$PB -c 'Add :LSUIElement bool true' "$P" 2>/dev/null || true

# Declare document types: Markdown (by UTI + by extension) and Obsidian canvas/base.
$PB -c 'Delete :CFBundleDocumentTypes' "$P" 2>/dev/null || true
$PB -c 'Add :CFBundleDocumentTypes array' "$P"
$PB -c 'Add :CFBundleDocumentTypes:0 dict' "$P"
$PB -c 'Add :CFBundleDocumentTypes:0:CFBundleTypeName string "Markdown Document"' "$P"
$PB -c 'Add :CFBundleDocumentTypes:0:CFBundleTypeRole string Editor' "$P"
$PB -c 'Add :CFBundleDocumentTypes:0:LSHandlerRank string Default' "$P"
$PB -c 'Add :CFBundleDocumentTypes:0:LSItemContentTypes array' "$P"
$PB -c 'Add :CFBundleDocumentTypes:0:LSItemContentTypes:0 string net.daringfireball.markdown' "$P"
$PB -c 'Add :CFBundleDocumentTypes:1 dict' "$P"
$PB -c 'Add :CFBundleDocumentTypes:1:CFBundleTypeName string "Markdown File"' "$P"
$PB -c 'Add :CFBundleDocumentTypes:1:CFBundleTypeRole string Editor' "$P"
$PB -c 'Add :CFBundleDocumentTypes:1:LSHandlerRank string Default' "$P"
$PB -c 'Add :CFBundleDocumentTypes:1:CFBundleTypeExtensions array' "$P"
$PB -c 'Add :CFBundleDocumentTypes:1:CFBundleTypeExtensions:0 string md' "$P"
$PB -c 'Add :CFBundleDocumentTypes:1:CFBundleTypeExtensions:1 string markdown' "$P"
$PB -c 'Add :CFBundleDocumentTypes:1:CFBundleTypeExtensions:2 string mdown' "$P"
$PB -c 'Add :CFBundleDocumentTypes:1:CFBundleTypeExtensions:3 string mkd' "$P"
$PB -c 'Add :CFBundleDocumentTypes:2 dict' "$P"
$PB -c 'Add :CFBundleDocumentTypes:2:CFBundleTypeName string "Obsidian Canvas or Base"' "$P"
$PB -c 'Add :CFBundleDocumentTypes:2:CFBundleTypeRole string Viewer' "$P"
$PB -c 'Add :CFBundleDocumentTypes:2:LSHandlerRank string Default' "$P"
$PB -c 'Add :CFBundleDocumentTypes:2:CFBundleTypeExtensions array' "$P"
$PB -c 'Add :CFBundleDocumentTypes:2:CFBundleTypeExtensions:0 string canvas' "$P"
$PB -c 'Add :CFBundleDocumentTypes:2:CFBundleTypeExtensions:1 string base' "$P"
/usr/bin/plutil -lint "$P" >/dev/null

# Reuse Obsidian's icon if present (purely cosmetic).
OBS_ICNS="/Applications/Obsidian.app/Contents/Resources/icon.icns"
if [ -f "$OBS_ICNS" ]; then
  ICNS=$(ls "$APP/Contents/Resources/" | grep -m1 '\.icns$' || true)
  [ -n "$ICNS" ] && cp "$OBS_ICNS" "$APP/Contents/Resources/$ICNS"
fi

/usr/bin/codesign --force -s - "$APP" >/dev/null 2>&1 || true
LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
"$LSREGISTER" -f "$APP"

echo '==> [2/3] Setting Obsidian Opener as the default for .md'
if ! command -v duti >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    echo '    installing duti via Homebrew...'; brew install duti
  else
    echo '    NOTE: `duti` not found and Homebrew is not installed. Skipping auto-binding.'
    echo '    Set it manually: Finder → right-click any .md → Get Info → Open with →'
    echo '    Obsidian Opener → Change All.'
  fi
fi
if command -v duti >/dev/null 2>&1; then
  for t in .md net.daringfireball.markdown .markdown .canvas .base; do
    duti -s "$BUNDLE_ID" "$t" all 2>/dev/null || true
  done
fi

echo '==> [3/3] Installing right-click Quick Action ("Open in Obsidian")'
SVC="$HOME/Library/Services/Open in Obsidian.workflow"
rm -rf "$SVC"; mkdir -p "$SVC/Contents"
cp "$HERE/quick-action/Info.plist" "$SVC/Contents/Info.plist"
cp "$HERE/quick-action/document.wflow" "$SVC/Contents/document.wflow"
/System/Library/CoreServices/pbs -update 2>/dev/null || true

echo ''
echo 'Done. Double-click any .md inside an Obsidian vault → it opens in Obsidian.'
echo 'Files outside any vault open in the fallback editor (default: Typora).'
echo 'Tip: run ./register-vaults.sh if a vault created on your phone opens in the wrong app.'
