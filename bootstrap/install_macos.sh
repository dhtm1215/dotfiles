#!/usr/bin/env bash
set -euo pipefail

# sh로 실행했을 때 bash 기능([[, BASH_SOURCE 등) 깨지는 것 방지
if [ -z "${BASH_VERSION:-}" ]; then
  exec /usr/bin/env bash "$0" "$@"
fi

log() { printf "\n[bootstrap] %s\n" "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# repo 구조(너가 올린 install_ubuntu.sh 기준) 맞춰서 경로 잡음
ZSH_SRC_DIR="${REPO_ROOT}/zsh"
NVIM_SRC_DIR="${REPO_ROOT}/nvim"
TMUX_SRC_FILE="${REPO_ROOT}/tmux.conf"    # 없으면 자동 스킵
GITCONF_SRC_FILE="${REPO_ROOT}/gitconfig" # 없으면 자동 스킵

# 설치/배치 위치
ZSH_DST_DIR="${HOME}/.config/zsh"
NVIM_DST_DIR="${HOME}/.config/nvim"
TMUX_DST_FILE="${HOME}/.tmux.conf"
GITCONF_DST_FILE="${HOME}/.gitconfig"

# backup 유틸
backup_if_exists() {
  local target="$1"
  if [ -e "$target" ] || [ -L "$target" ]; then
    local ts
    ts="$(date +"%Y%m%d_%H%M%S")"
    mv "$target" "${target}.bak.${ts}"
    log "backup: $target -> ${target}.bak.${ts}"
  fi
}

ensure_dir() {
  local d="$1"
  mkdir -p "$d"
}

symlink_dir() {
  local src="$1"
  local dst="$2"
  if [ ! -d "$src" ]; then
    log "skip (missing dir): $src"
    return 0
  fi
  backup_if_exists "$dst"
  ensure_dir "$(dirname "$dst")"
  ln -snf "$src" "$dst"
  log "link: $dst -> $src"
}

symlink_file() {
  local src="$1"
  local dst="$2"
  if [ ! -f "$src" ]; then
    log "skip (missing file): $src"
    return 0
  fi
  backup_if_exists "$dst"
  ln -snf "$src" "$dst"
  log "link: $dst -> $src"
}

# brew 설치(없으면 안내만)
install_brew_if_needed() {
  if have brew; then
    return 0
  fi
  log "Homebrew가 없음. 아래 중 하나를 선택해라:"
  log "1) 직접 설치 후 다시 실행"
  log '   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  log "2) brew 없이 링크만 걸고 끝내도 됨(설치는 너가 수동으로)"
}

brew_bundle() {
  if ! have brew; then
    return 0
  fi

  log "brew update"
  brew update

  # 너 워크플로우 기준으로 실사용 큰 것만(없어도 되는 건 설치 실패해도 진행)
  local pkgs=(
    git
    neovim
    tmux
    zsh
    fzf
    ripgrep
    fd
    eza
    bat
    yazi
  )

  log "brew install packages"
  for p in "${pkgs[@]}"; do
    if brew list "$p" >/dev/null 2>&1; then
      log "already: $p"
    else
      brew install "$p" || log "warn: failed to install $p (continue)"
    fi
  done

  # fzf install (키바인딩/완성)
  if have "$(brew --prefix)/opt/fzf/install"; then
    log "fzf post-install (no changes if already done)"
    "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc >/dev/null 2>&1 || true
  fi
}

main() {
  log "repo root: $REPO_ROOT"

  # 0) brew 준비/설치
  install_brew_if_needed
  brew_bundle

  # 1) config 디렉토리 기본 생성
  ensure_dir "${HOME}/.config"

  # 2) zsh / nvim 링크
  symlink_dir "$ZSH_SRC_DIR" "$ZSH_DST_DIR"
  symlink_dir "$NVIM_SRC_DIR" "$NVIM_DST_DIR"

  # 3) tmux / gitconfig (있으면)
  symlink_file "$TMUX_SRC_FILE" "$TMUX_DST_FILE"
  symlink_file "$GITCONF_SRC_FILE" "$GITCONF_DST_FILE"

  # 4) zsh 기본 셸 설정(실패해도 진행)
  if have chsh && have zsh; then
    if [ "${SHELL:-}" != "$(command -v zsh)" ]; then
      log "set default shell to zsh (password may be required)"
      chsh -s "$(command -v zsh)" || log "warn: chsh failed (continue)"
    fi
  fi

  log "done"
  log "다음:"
  log "  1) 새 터미널 열거나: exec zsh"
  log "  2) tmux 쓰는 중이면: tmux source-file ~/.tmux.conf"
  log "  3) nvim 첫 실행하면 플러그인 자동 설치 뜰 수 있음"
}

main "$@"
