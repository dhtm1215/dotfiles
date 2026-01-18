#!/usr/bin/env bash
set -euo pipefail

# sh로 실행했을 때 [[ not found 터지는 거 방지
if [ -z "${BASH_VERSION:-}" ]; then
  exec /usr/bin/env bash "$0" "$@"
fi

log() { printf "\n[bootstrap] %s\n" "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZSH_SRC_DIR="$(cd "$SCRIPT_DIR/.." && pwd)/zsh"
ZSH_DST_DIR="${HOME}/.config/zsh"

if [ ! -d "$ZSH_SRC_DIR" ]; then
  echo "[ERR] zsh 폴더가 없음: $ZSH_SRC_DIR"
  echo "구조가 이런지 확인: <repo>/install_nyarch.sh 와 <repo>/zsh/"
  exit 1
fi

pacman_install() {
  sudo pacman -Syu --noconfirm
  sudo pacman -S --noconfirm "$@"
}

git_sync_repo() {
  # 있으면 pull, 없으면 clone (멱등)
  local repo="$1"
  local dest="$2"
  if [ -d "$dest/.git" ]; then
    git -C "$dest" pull --ff-only || true
  else
    rm -rf "$dest"
    git clone --depth=1 "$repo" "$dest"
  fi
}

ensure_minimal_zshrc() {
  # zsh-newuser-install 뜨는 거 막는 "최소 로더"를 홈에 항상 둔다
  cat >"${HOME}/.zshrc" <<'EOF'
# minimal bootstrap: load real config if present
for f in "$HOME/.config/zsh/zshrc" "$HOME/.config/zsh/zshrc.zsh" "$HOME/.config/zsh/init.zsh"; do
  [ -f "$f" ] && source "$f" && return
 done
EOF
}

ensure_dotfiles_symlink() {
  log "dotfiles: option A 심링크 적용 (~/.config/zsh -> <repo>/zsh)"

  mkdir -p "${HOME}/.config"

  # 기존 ~/.config/zsh가 "디렉토리(심링크 아님)"이면 백업
  local ts
  ts="$(date +%Y%m%d_%H%M%S)"
  if [ -e "$ZSH_DST_DIR" ] && [ ! -L "$ZSH_DST_DIR" ]; then
    mv "$ZSH_DST_DIR" "${ZSH_DST_DIR}.bak.${ts}"
  fi

  ln -sfn "$ZSH_SRC_DIR" "$ZSH_DST_DIR"

  # 홈의 ~/.zshrc는 항상 최소 로더로 보장 (심링크로 꼬이는 거 방지)
  ensure_minimal_zshrc
}

ensure_ohmyzsh() {
  log "oh-my-zsh 설치/복구"

  # 예전에 custom만 남고 oh-my-zsh.sh 없는 상태가 있었음 -> 그 케이스 복구
  if [ -d "${HOME}/.oh-my-zsh" ] && [ ! -f "${HOME}/.oh-my-zsh/oh-my-zsh.sh" ]; then
    rm -rf "${HOME}/.oh-my-zsh"
  fi

  git_sync_repo https://github.com/ohmyzsh/ohmyzsh.git "${HOME}/.oh-my-zsh"

  if [ ! -f "${HOME}/.oh-my-zsh/oh-my-zsh.sh" ]; then
    echo "[ERR] oh-my-zsh.sh가 없음. 클론이 비정상."
    exit 1
  fi
}

ensure_p10k_and_plugins() {
  log "p10k + zsh plugins 설치/업데이트"

  local zcustom="${ZSH_CUSTOM:-${HOME}/.oh-my-zsh/custom}"
  mkdir -p "$zcustom/themes" "$zcustom/plugins"

  git_sync_repo https://github.com/romkatv/powerlevel10k.git \
    "$zcustom/themes/powerlevel10k"

  git_sync_repo https://github.com/zsh-users/zsh-autosuggestions \
    "$zcustom/plugins/zsh-autosuggestions"

  git_sync_repo https://github.com/zsh-users/zsh-syntax-highlighting.git \
    "$zcustom/plugins/zsh-syntax-highlighting"
}

ensure_neovim_for_lazyvim() {
  log "neovim 설치 (pacman)"

  pacman_install neovim

  if ! have nvim; then
    echo "[ERR] nvim 커맨드가 안 잡힘"
    exit 1
  fi
}

ensure_tools() {
  log "기본 패키지 설치 (pacman)"
  pacman_install git curl unzip tar gzip zsh tmux \
    fzf ripgrep fd jq bat eza \
    gh yazi lazygit
}

ensure_lazyvim_starter() {
  # 이미 너가 세팅한 방식 유지: 기존 nvim config 백업 후 starter clone
  log "LazyVim starter 설치 (기존 nvim 설정 백업 후)"

  local nvim_dir="${HOME}/.config/nvim"
  local ts
  ts="$(date +%Y%m%d_%H%M%S)"

  if [ -d "$nvim_dir" ] && [ ! -L "$nvim_dir" ]; then
    mv "$nvim_dir" "${nvim_dir}.bak.${ts}"
  fi

  if [ ! -d "$nvim_dir/.git" ]; then
    git clone https://github.com/LazyVim/starter "$nvim_dir"
    rm -rf "${nvim_dir}/.git"
  fi
}

main() {
  log "시작: $(whoami) / $(hostname)"
  log "repo: $SCRIPT_DIR"

  ensure_tools
  ensure_dotfiles_symlink
  ensure_ohmyzsh
  ensure_p10k_and_plugins
  ensure_neovim_for_lazyvim
  ensure_lazyvim_starter

  log "완료. 새 터미널 열거나 아래 실행"
  echo "exec zsh"
  echo "확인: nvim --version; lazygit --version; gh --version; jq --version; yazi --version"
}

main "$@"
