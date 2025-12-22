# ~/dotfiles/ubuntu_bootstrap.sh
#!/usr/bin/env bash
set -euo pipefail

log() { printf "\n[bootstrap] %s\n" "$*"; }

# dotfiles root = 이 스크립트가 있는 폴더
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ZSH_DIR="$SCRIPT_DIR/zsh"

if [[ ! -d "$ZSH_DIR" ]]; then
  echo "ERROR: expected $ZSH_DIR to exist (dotfiles/zsh 폴더가 필요함)"
  exit 1
fi

log "sudo 권한 확인"
sudo -v

log "apt 업데이트 + 기본 패키지 설치"
sudo apt update
sudo apt install -y \
  git curl ca-certificates unzip \
  zsh tmux \
  fzf ripgrep fd-find \
  jq \
  bat eza \
  openssh-server

log "ssh 서버 enable"
sudo systemctl enable --now ssh || true

log "snap 설치 준비"
sudo apt install -y snapd || true
sudo systemctl enable --now snapd || true
sudo systemctl enable --now snapd.socket || true

log "yazi 설치(snap)"
if ! command -v yazi >/dev/null 2>&1; then
  sudo snap install yazi --classic
fi

log "neovim 최신 설치(snap) + apt neovim 제거(있으면)"
if dpkg -s neovim >/dev/null 2>&1; then
  sudo apt remove -y neovim || true
fi
if ! command -v nvim >/dev/null 2>&1; then
  sudo snap install nvim --classic
fi

log "GitHub CLI(gh) / lazygit 설치(apt)"
# (이미 설치돼 있으면 skip)
sudo apt install -y gh lazygit || true

log "dotfiles: option A 심링크 적용 (~/.config/zsh -> dotfiles/zsh)"
mkdir -p "$HOME/.config"

# 기존 설정 백업(있으면)
ts="$(date +%Y%m%d_%H%M%S)"
if [[ -e "$HOME/.config/zsh" && ! -L "$HOME/.config/zsh" ]]; then
  mv "$HOME/.config/zsh" "$HOME/.config/zsh.bak.$ts"
fi
if [[ -e "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]]; then
  cp -a "$HOME/.zshrc" "$HOME/.zshrc.bak.$ts" || true
fi

ln -sfn "$ZSH_DIR" "$HOME/.config/zsh"
ln -sfn "$HOME/.config/zsh/zshrc" "$HOME/.zshrc"

log "oh-my-zsh 설치(없으면)"
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

log "p10k + zsh plugins 설치"
mkdir -p "$HOME/.oh-my-zsh/custom/themes" "$HOME/.oh-my-zsh/custom/plugins"

if [[ ! -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"
fi

if [[ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]]; then
  git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
    "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
fi

if [[ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]]; then
  git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting \
    "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
fi

log "LazyVim starter 설치(기존 nvim 설정 백업 후)"
mkdir -p "$HOME/.config"
if [[ -d "$HOME/.config/nvim" ]]; then
  mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak.$ts" || true
fi
if [[ -d "$HOME/.local/share/nvim" ]]; then
  mv "$HOME/.local/share/nvim" "$HOME/.local/share/nvim.bak.$ts" || true
fi

if [[ ! -d "$HOME/.config/nvim" ]]; then
  git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
fi

log "완료. 터미널 새로 열거나 'exec zsh' 하면 설정 적용됨."
log "확인 커맨드: nvim --version ; lazygit ; gh --version ; jq --version ; yazi --version"
