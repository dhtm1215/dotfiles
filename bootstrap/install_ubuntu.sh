#!/usr/bin/env bash
set -euo pipefail

DOT="${HOME}/dotfiles"

# 1) 패키지 설치 (nvim/lazyvim 최소 의존성 + 너 도구들)
sudo apt update
sudo apt install -y \
  git curl unzip gzip tar \
  zsh tmux fzf ripgrep vim \
  fd-find \
  python3 python3-venv python3-pip

# 2) fd 이름 맞추기 (ubuntu: fdfind -> fd)
if ! command -v fd >/dev/null 2>&1; then
  if command -v fdfind >/dev/null 2>&1; then
    sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd
  fi
fi

# 3) Neovim 설치 (Ubuntu 버전에 따라 apt nvim이 너무 구릴 수 있음)
# 일단 apt로 시도 → 부족하면 나중에 AppImage/릴리즈로 업그레이드
if ! command -v nvim >/dev/null 2>&1; then
  sudo apt install -y neovim || true
fi

# 4) starship 설치 (바이너리)
if ! command -v starship >/dev/null 2>&1; then
  curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# 5) dotfiles 링크 생성 (절대경로 금지, HOME 기준)
mkdir -p "${HOME}/.config"

ln -sfn "${DOT}/nvim" "${HOME}/.config/nvim"
ln -sfn "${DOT}/starship.toml" "${HOME}/.config/starship.toml"
ln -sfn "${DOT}/.zshrc" "${HOME}/.zshrc"
ln -sfn "${DOT}/tmux.conf" "${HOME}/.tmux.conf"

# 6) 기본 쉘을 zsh로 변경(선택)
if [ "${SHELL}" != "$(command -v zsh)" ]; then
  chsh -s "$(command -v zsh)" || true
fi

echo "done. reopen shell or 'exec zsh' and run: tmux new -A -s main"
