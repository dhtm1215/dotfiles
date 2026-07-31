#!/usr/bin/env bash
set -euo pipefail

if [ -z "${BASH_VERSION:-}" ]; then
  exec /usr/bin/env bash "$0" "$@"
fi

DRY_RUN=0
SKIP_PACKAGES=0

usage() {
  cat <<'EOF'
Usage: ./install.sh [--dry-run] [--skip-packages]

Options:
  --dry-run        Print what would be done without changing files.
  --skip-packages  Only link dotfiles; do not install packages.
  -h, --help       Show this help.
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

log() { printf '\n[dotfiles] %s\n' "$*"; }
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

backup_path() {
  local target="$1"
  if [ -e "$target" ] || [ -L "$target" ]; then
    local ts backup
    ts="$(date +%Y%m%d_%H%M%S)"
    backup="${target}.bak.${ts}"
    run mv "$target" "$backup"
    log "backup: $target -> $backup"
  fi
}

link_path() {
  local src="$1"
  local dst="$2"

  if [ ! -e "$src" ]; then
    log "skip missing: $src"
    return 0
  fi

  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    log "already linked: $dst -> $src"
    return 0
  fi

  if [ -e "$dst" ] || [ -L "$dst" ]; then
    backup_path "$dst"
  fi

  run mkdir -p "$(dirname "$dst")"
  run ln -sfn "$src" "$dst"
  log "link: $dst -> $src"
}

install_homebrew() {
  load_homebrew_env
  if have brew; then
    return 0
  fi

  log "Homebrew not found"
  if [ "$DRY_RUN" -eq 1 ]; then
    log "would install Homebrew"
    return 0
  fi

  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  load_homebrew_env
}

install_packages_macos() {
  install_homebrew
  if ! have brew; then
    log "skip packages: brew unavailable; restart shell or add Homebrew to PATH, then rerun ./install.sh"
    return 0
  fi

  local packages=(
    git
    curl
    zsh
    neovim
    tmux
    fzf
    ripgrep
    fd
    eza
    bat
    yazi
    starship
    jq
    gh
    lazygit
    git-delta
  )

  for package in "${packages[@]}"; do
    if brew list "$package" >/dev/null 2>&1; then
      log "already installed: $package"
    else
      run brew install "$package"
    fi
  done

  local fzf_install
  fzf_install="$(brew --prefix 2>/dev/null)/opt/fzf/install"
  if [ -x "$fzf_install" ]; then
    run "$fzf_install" --key-bindings --completion --no-update-rc
  fi
}

install_packages_arch() {
  local packages=(git curl unzip tar gzip zsh neovim tmux fzf ripgrep fd jq bat eza yazi starship lazygit git-delta)

  if pacman -Si gh >/dev/null 2>&1; then
    packages+=(gh)
  elif pacman -Si github-cli >/dev/null 2>&1; then
    packages+=(github-cli)
  fi

  run sudo pacman -Syu --noconfirm
  run sudo pacman -S --needed --noconfirm "${packages[@]}"
}

install_packages_ubuntu() {
  run sudo apt update
  run sudo apt install -y git curl unzip tar gzip zsh neovim tmux fzf ripgrep fd-find jq bat eza gh

  if ! have fd && have fdfind; then
    run sudo ln -sfn "$(command -v fdfind)" /usr/local/bin/fd
  fi

  if ! have yazi; then
    log "yazi is not available from this installer on Ubuntu; install it manually if needed"
  fi
  if ! have starship; then
    log "starship is not available from this installer on Ubuntu; install it manually if needed"
  fi
}

install_packages() {
  if [ "$SKIP_PACKAGES" -eq 1 ]; then
    log "skip package install"
    return 0
  fi

  case "$OS" in
  Darwin) install_packages_macos ;;
  Linux)
    if [ -r /etc/os-release ]; then
      . /etc/os-release
    fi

    if [[ "${ID:-}" == "arch" || "${ID:-}" == "nyarch" || "${ID_LIKE:-}" == *arch* ]]; then
      install_packages_arch
    else
      install_packages_ubuntu
    fi
    ;;
  *)
    log "unsupported OS for packages: $OS"
    ;;
  esac
}

install_oh_my_zsh() {
  local zsh_dir="$HOME/.oh-my-zsh"
  if [ -f "$zsh_dir/oh-my-zsh.sh" ]; then
    log "already installed: oh-my-zsh"
    return 0
  fi

  if [ -e "$zsh_dir" ]; then
    backup_path "$zsh_dir"
  fi

  run git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$zsh_dir"
}

sync_repo() {
  local repo="$1"
  local dst="$2"

  if [ -d "$dst/.git" ]; then
    run git -C "$dst" pull --ff-only
  else
    if [ -e "$dst" ]; then
      backup_path "$dst"
    fi
    run git clone --depth=1 "$repo" "$dst"
  fi
}

install_zsh_plugins() {
  local zcustom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  run mkdir -p "$zcustom/themes" "$zcustom/plugins"

  sync_repo https://github.com/romkatv/powerlevel10k.git "$zcustom/themes/powerlevel10k"
  sync_repo https://github.com/zsh-users/zsh-autosuggestions.git "$zcustom/plugins/zsh-autosuggestions"
  sync_repo https://github.com/zsh-users/zsh-syntax-highlighting.git "$zcustom/plugins/zsh-syntax-highlighting"
}

install_tmux_plugins() {
  sync_repo https://github.com/tmux-plugins/tpm.git "$HOME/.tmux/plugins/tpm"

  local installer="$HOME/.tmux/plugins/tpm/bin/install_plugins"
  if [ -x "$installer" ]; then
    run "$installer"
  fi
}

link_dotfiles() {
  link_path "$SCRIPT_DIR/zsh" "$HOME/.config/zsh"
  link_path "$SCRIPT_DIR/zsh/zshrc" "$HOME/.zshrc"
  link_path "$SCRIPT_DIR/p10k.zsh" "$HOME/.p10k.zsh"
  link_path "$SCRIPT_DIR/nvim" "$HOME/.config/nvim"
  link_path "$SCRIPT_DIR/tmux.conf" "$HOME/.tmux.conf"
  link_path "$SCRIPT_DIR/.gitconfig" "$HOME/.gitconfig"
  link_path "$SCRIPT_DIR/starship.toml" "$HOME/.config/starship.toml"
}

set_default_shell() {
  if ! have zsh || ! have chsh; then
    return 0
  fi

  local zsh_path
  zsh_path="$(command -v zsh)"
  if [ "${SHELL:-}" = "$zsh_path" ]; then
    return 0
  fi

  log "set default shell to zsh"
  run chsh -s "$zsh_path"
}

main() {
  log "repo: $SCRIPT_DIR"
  log "os: $OS"

  install_packages
  link_dotfiles
  install_oh_my_zsh
  install_zsh_plugins
  install_tmux_plugins
  set_default_shell

  log "done"
  log "next: exec zsh"
  log "check: nvim --version; tmux -V; yazi --version; starship --version"
}

main "$@"
