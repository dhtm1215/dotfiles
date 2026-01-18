#!/usr/bin/env bash
set -euo pipefail

REPO="dhtm1215"

# OS 판별
OS="$(uname -s)"

if [[ "$OS" == "Darwin" ]]; then
  # brew 없으면 설치
  if ! command -v brew >/dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  brew install git curl chezmoi
  ./bootstrap/mac.sh || true
elif [[ "$OS" == "Linux" ]]; then
  if [ -f /etc/os-release ]; then
    . /etc/os-release
  fi

  if [[ "${ID:-}" == "arch" || "${ID:-}" == "nyarch" || "${ID_LIKE:-}" == *"arch"* ]]; then
    sudo pacman -Syu --noconfirm
    sudo pacman -S --noconfirm git curl
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin
    export PATH="$HOME/.local/bin:$PATH"
    ./bootstrap/install_nyarch.sh || true
  else
    sudo apt update
    sudo apt install -y git curl
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin
    export PATH="$HOME/.local/bin:$PATH"
    ./bootstrap/install_ubuntu.sh || true
  fi
else
  echo "unsupported OS: $OS"
  exit 1
fi

# dotfiles 적용
chezmoi init --apply "$REPO"
echo "done"
