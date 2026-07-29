#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() { printf '[export] %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

export_brewfile() {
  if ! have brew; then
    log 'skip Brewfile: brew not found'
    return 0
  fi

  log 'writing Brewfile'
  HOMEBREW_NO_AUTO_UPDATE=1 brew bundle dump --file="$ROOT/Brewfile" --force

  if [ -d /Applications/iTerm.app ] && ! grep -q '^cask "iterm2"' "$ROOT/Brewfile"; then
    printf '\n# Terminal emulator\ncask "iterm2"\n' >>"$ROOT/Brewfile"
    log 'adding iTerm2 cask to Brewfile'
  fi
}

export_iterm2() {
  local src="$HOME/Library/Preferences/com.googlecode.iterm2.plist"
  local dst_dir="$ROOT/iterm2/DynamicProfiles"
  local dst="$dst_dir/dotfiles.json"

  if [ ! -f "$src" ]; then
    log 'skip iTerm2: preference plist not found'
    return 0
  fi

  if ! have python3; then
    log 'skip iTerm2: python3 not found'
    return 0
  fi

  mkdir -p "$dst_dir"
  python3 - "$src" "$dst" <<'PY'
import copy
import json
import plistlib
import sys

src, dst = sys.argv[1], sys.argv[2]

with open(src, "rb") as f:
    prefs = plistlib.load(f)

profiles = prefs.get("New Bookmarks", [])

DROP_KEYS = {
    "Guid",
    "Working Directory",
    "Custom Directory",
    "Bound Hosts",
    "Initial Text",
}


def scrub(value):
    if isinstance(value, dict):
        cleaned = {}
        for key, item in value.items():
            if key in DROP_KEYS or key.startswith("NoSync") or key.startswith("NS"):
                continue
            cleaned[key] = scrub(item)
        return cleaned
    if isinstance(value, list):
        return [scrub(item) for item in value]
    if isinstance(value, str):
        return value.replace("/Users/" + __import__("getpass").getuser(), "~")
    return value

portable_profiles = [scrub(copy.deepcopy(profile)) for profile in profiles]

with open(dst, "w", encoding="utf-8") as f:
    json.dump({"Profiles": portable_profiles}, f, ensure_ascii=False, indent=2, sort_keys=True)
    f.write("\n")
PY
  log "writing $dst"
}

export_tmux() {
  local src="$HOME/.tmux.conf"
  local dst="$ROOT/tmux.conf"

  if [ ! -f "$src" ]; then
    log 'skip tmux: ~/.tmux.conf not found'
    return 0
  fi

  if [ -L "$src" ] && [ "$(readlink "$src")" = "$dst" ]; then
    log 'tmux already managed by repo'
    return 0
  fi

  cp "$src" "$dst"
  log 'writing tmux.conf from current ~/.tmux.conf'
}

main() {
  export_brewfile
  export_iterm2
  export_tmux

  log 'done'
  log 'review git diff before committing; secrets such as ~/.ssh and tokens are intentionally not exported'
}

main "$@"
