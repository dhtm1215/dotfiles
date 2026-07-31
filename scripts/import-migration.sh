#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=0
SKIP_PACKAGES=0

usage() {
  cat <<'EOF'
Usage: ./scripts/import-migration.sh [--dry-run] [--skip-packages]

Restores non-secret machine migration data tracked in this repo:
  - Brewfile packages and casks on macOS
  - iTerm2 dynamic profiles and appearance preferences

Run ./install.sh first for shell, nvim, tmux, git, and starship symlinks.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
  --dry-run) DRY_RUN=1 ;;
  --skip-packages) SKIP_PACKAGES=1 ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    echo "unknown option: $1" >&2
    usage >&2
    exit 1
    ;;
  esac
  shift
done

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() { printf '[import] %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

load_homebrew_env() {
  local brew_bin=""

  if have brew; then
    brew_bin="$(command -v brew)"
  elif [ -x /opt/homebrew/bin/brew ]; then
    brew_bin=/opt/homebrew/bin/brew
  elif [ -x /usr/local/bin/brew ]; then
    brew_bin=/usr/local/bin/brew
  fi

  if [ -n "$brew_bin" ]; then
    eval "$("$brew_bin" shellenv)"
  fi
}

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    printf '[dry-run]'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

backup_path() {
  local target="$1"
  if [ -e "$target" ] || [ -L "$target" ]; then
    local backup
    backup="${target}.bak.$(date +%Y%m%d_%H%M%S)"
    run mv "$target" "$backup"
    log "backup: $target -> $backup"
  fi
}

restore_brewfile() {
  local brewfile="$ROOT/Brewfile"
  if [ "$SKIP_PACKAGES" -eq 1 ] || [ "$(uname -s)" != 'Darwin' ] || [ ! -f "$brewfile" ]; then
    log 'skip Brewfile restore'
    return 0
  fi

  load_homebrew_env
  if ! have brew; then
    log 'skip Brewfile restore: brew not found; run ./install.sh first'
    return 0
  fi

  run brew bundle --file="$brewfile"
}

restore_iterm2() {
  local src_dir="$ROOT/iterm2/DynamicProfiles"
  local dst_dir="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
  local src dst

  if [ "$(uname -s)" != 'Darwin' ] || [ ! -d "$src_dir" ]; then
    log 'skip iTerm2 restore'
    return 0
  fi

  run mkdir -p "$dst_dir"
  for src in "$src_dir"/*.json; do
    [ -f "$src" ] || continue
    dst="$dst_dir/$(basename "$src")"
    backup_path "$dst"
    run cp "$src" "$dst"
  done

  run defaults write com.googlecode.iterm2 TabStyleWithAutomaticOption -int 5
  run defaults write com.googlecode.iterm2 TabViewType -int 0
  run defaults write com.googlecode.iterm2 HideTab -bool false
  run defaults write com.googlecode.iterm2 'Default Bookmark Guid' -string 'B450D62C-C781-4DBA-91DD-C721063BAF88'
  log 'iTerm2 Catppuccin Mocha profile and Minimal appearance restored; restart iTerm2'
}

main() {
  restore_brewfile
  restore_iterm2
  log 'done'
}

main "$@"
