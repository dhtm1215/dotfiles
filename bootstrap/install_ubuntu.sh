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
  echo "구조가 이런지 확인: <repo>/install_ubuntu.sh 와 <repo>/zsh/"
  exit 1
fi

apt_install() {
  sudo apt update -y
  sudo apt install -y "$@"
}

snap_install() {
  local pkg="$1"
  shift || true
  if ! have snap; then
    apt_install snapd
  fi
  sudo snap install "$pkg" "$@" || true
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
  log "neovim 최신 설치 (snap) + apt neovim 제거(있으면)"

  sudo apt remove -y neovim || true
  snap_install nvim --classic

  # /snap/bin/nvim을 nvim으로 쓰기 편하게 링크(환경마다 PATH 다름 대비)
  if [ -x /snap/bin/nvim ]; then
    sudo ln -sfn /snap/bin/nvim /usr/local/bin/nvim
  fi

  if ! have nvim; then
    echo "[ERR] nvim 커맨드가 안 잡힘"
    exit 1
  fi
}

ensure_tools() {
  log "기본 패키지 설치 (apt)"
  apt_install git curl unzip tar gzip zsh tmux \
    fzf ripgrep fd-find jq bat eza \
    gh

  log "yazi 설치 (snap)"
  snap_install yazi --classic
}

install_lazygit_latest() {
  log "lazygit 설치 (GitHub latest redirect 기반, API/jq/grep 없음)"

  # snap 구버전 있으면 제거
  if command -v snap >/dev/null 2>&1; then
    if snap list 2>/dev/null | awk '{print $1}' | grep -qx lazygit; then
      sudo snap remove lazygit || true
    fi
  fi

  local arch tarch ver url workdir
  arch="$(uname -m)"
  case "$arch" in
  x86_64) tarch="Linux_x86_64" ;;
  aarch64 | arm64) tarch="Linux_arm64" ;;
  *)
    log "지원 안 되는 아키텍처: $arch -> skip"
    return 0
    ;;
  esac

  # GitHub latest는 태그로 리다이렉트됨 -> 최종 URL에서 vX.Y.Z만 뽑음
  ver="$(
    curl -fsSL -o /dev/null -w '%{url_effective}' \
      https://github.com/jesseduffield/lazygit/releases/latest |
      awk -F/ '{print $NF}'
  )"

  if [ -z "$ver" ]; then
    echo "[ERR] lazygit 버전 태그를 못 가져옴"
    return 1
  fi

  url="https://github.com/jesseduffield/lazygit/releases/download/${ver}/lazygit_${ver#v}_${tarch}.tar.gz"

  workdir="$HOME/.cache/lazygit-install"
  mkdir -p "$workdir"
  rm -f "$workdir/lazygit.tgz" "$workdir/lazygit"

  curl -fLSo "$workdir/lazygit.tgz" "$url"
  tar -tzf "$workdir/lazygit.tgz" >/dev/null
  tar -xzf "$workdir/lazygit.tgz" -C "$workdir" lazygit
  sudo install -m 0755 "$workdir/lazygit" /usr/local/bin/lazygit

  lazygit --version || true
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

ensure_fd_command() {
  # zsh alias 말고, 실제 실행파일 fd가 존재해야 (eval/sh에서도) 안 터짐
  if command -v fd >/dev/null 2>&1; then
    return 0
  fi

  # ubuntu: 패키지명 fd-find, 바이너리명 fdfind인 경우가 흔함
  if command -v fdfind >/dev/null 2>&1; then
    sudo ln -sfn "$(command -v fdfind)" /usr/local/bin/fd
    return 0
  fi

  # 혹시 환경에 따라 fd-find로 들어오는 경우까지 방어
  if command -v fd-find >/dev/null 2>&1; then
    sudo ln -sfn "$(command -v fd-find)" /usr/local/bin/fd
    return 0
  fi

  echo "[bootstrap][WARN] fd/fdfind 없음: 먼저 fd-find 패키지 설치 필요"
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
  install_lazygit_latest
  ensure_fd_command

  log "완료. 새 터미널 열거나 아래 실행"
  echo "exec zsh"
  echo "확인: nvim --version; lazygit --version; gh --version; jq --version; yazi --version"
}

main "$@"
