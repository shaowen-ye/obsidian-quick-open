#!/bin/zsh
# register-vaults.sh
# Register any folder that *is* an Obsidian vault but is not yet known to THIS Mac.
#
# Why this exists: Obsidian's vault registry (obsidian.json) is per-device and is
# NOT synced by iCloud. So a vault you created on your iPhone/iPad lives in iCloud,
# but this Mac has never opened it — double-clicking a note in it falls through to
# the fallback editor. This script scans common locations and registers every
# "is-a-vault-but-unregistered" folder.
#
# Safe: quits Obsidian first (so it can't overwrite the file), backs up, only ADDS
# entries (never edits existing ones), validates JSON. Re-runnable.
set -euo pipefail

CFG="$HOME/Library/Application Support/obsidian/obsidian.json"
[ -f "$CFG" ] || { echo "obsidian.json not found — open Obsidian at least once first."; exit 1; }

echo '==> Quitting Obsidian (so it cannot overwrite the registry)'
osascript -e 'tell application "Obsidian" to quit' 2>/dev/null || true
for i in $(seq 1 20); do pgrep -x Obsidian >/dev/null || break; sleep 0.5; done
if pgrep -x Obsidian >/dev/null; then echo 'Obsidian did not quit; please quit it and retry.'; exit 1; fi

echo '==> Backing up obsidian.json'
cp "$CFG" "$CFG.bak-$(date +%Y%m%d-%H%M%S)"

echo '==> Scanning & registering'
python3 <<'PY'
import json, os, time, secrets

cfg = os.path.expanduser('~/Library/Application Support/obsidian/obsidian.json')
# Locations to scan for vaults. Add your own roots here if needed.
roots = [
    os.path.expanduser('~/Library/Mobile Documents/iCloud~md~obsidian/Documents'),
    os.path.expanduser('~/Obsidian'),
]

d = json.load(open(cfg))
vaults = d.setdefault('vaults', {})
existing = {os.path.normpath(v['path']) for v in vaults.values()}

# A folder that contains a `.obsidian` directory IS a vault.
found = []
for root in roots:
    if not os.path.isdir(root):
        continue
    for name in sorted(os.listdir(root)):
        p = os.path.join(root, name)
        if os.path.isdir(p) and os.path.isdir(os.path.join(p, '.obsidian')):
            found.append(os.path.normpath(p))

ts = int(time.time() * 1000)
added = []
for p in found:
    if p in existing:
        continue
    while True:
        vid = secrets.token_hex(8)
        if vid not in vaults:
            break
    vaults[vid] = {'path': p, 'ts': ts}
    added.append(p)
    print('  + registered:', os.path.basename(p))

if not added:
    print('  Nothing to do — all discovered vaults are already registered.')

with open(cfg, 'w', encoding='utf-8') as f:
    f.write(json.dumps(d, ensure_ascii=False, separators=(',', ':')))

json.load(open(cfg))  # validate
print(f'\nDone. Added {len(added)} vault(s). Existing vaults untouched.')
PY

echo '==> Finished. You can open Obsidian now, or just double-click a note.'
