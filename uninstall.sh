#!/bin/zsh
# uninstall.sh — remove Obsidian Opener, its default-app bindings, and the Quick Action.
set -euo pipefail

echo '==> Removing app and Quick Action'
rm -rf "$HOME/Applications/Obsidian Opener.app"
rm -rf "$HOME/Library/Services/Open in Obsidian.workflow"

echo '==> Rebuilding Launch Services & Services menu'
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain user >/dev/null 2>&1 || true
/System/Library/CoreServices/pbs -update 2>/dev/null || true

echo ''
echo 'Removed. macOS will fall back to your previous default Markdown app.'
echo 'If .md now has no default, set one via Finder → Get Info → Open with → Change All.'
echo 'Vaults added by register-vaults.sh stay in Obsidian; remove them from the vault list if unwanted.'
