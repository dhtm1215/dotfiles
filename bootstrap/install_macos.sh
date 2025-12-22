# ~/dotfiles/bootstrap/install_macos.sh 로 "통으로 덮어쓰기"
# (보이지 않는 제어문자 섞이는 문제 방지용으로 cat heredoc 방식 추천)

mkdir -p ~/dotfiles/bootstrap

cat >~/dotfiles/bootstrap/install_macos.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

log() { printf "\n[install_macos] %s\n" "$*"; }
has() { command -v "$1" >/dev/null 2>&1; }

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
ZSH_DIR="$DOTFILES_ROOT/zsh"

if [[ ! -d "$ZSH_DIR" ]]; then
  echo "ERROR: expected $ZSH_DIR to exist (dotfiles/zsh 폴더가 필요함)"
  exit 1
fi

log "Homebrew 확인/설치"
if ! has brew; then
  log "brew 없음 -> 설치"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Apple Silicon 기본 brew 경로 보정
if [[ -d /opt/homebrew/bin ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

log "brew 업데이트"
brew update

log "필수 패키지 설치"
brew install \
  git curl ca-certificates \
  zsh tmux \
  fzf ripgrep fd \
  jq \
  bat eza \
  gh lazygit \
  yazi \
  neovim

log "fzf keybindings/completion 설치(맥)"
# brew fzf는 install 스크립트를 따로 실행해야 ~/.fzf.zsh가 생기는 경우가 많음
"$(brew --prefix)/opt/fzf/install" --all --no-bash --no-fish || true

log "dotfiles 옵션 A 적용 (~/.config/zsh -> dotfiles/zsh, ~/.zshrc -> 로더)"
mkdir -p "$HOME/.config"
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

[[ -d "$HOME/.oh-my-zsh/custom/themes/powerlevel10k" ]] || \
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    "$HOME/.oh-my-zsh/custom/themes/powerlevel10k"

[[ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]] || \
  git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
    "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"

[[ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]] || \
  git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git \
    "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"

log "LazyVim starter 설치 (기존 nvim 설정 백업 후)"
mkdir -p "$HOME/.config"
if [[ -d "$HOME/.config/nvim" ]]; then
  mv "$HOME/.config/nvim" "$HOME/.config/nvim.bak.$ts" || true
fi
if [[ -d "$HOME/.local/share/nvim" ]]; then
  mv "$HOME/.local/share/nvim" "$HOME/.local/share/nvim.bak.$ts" || true
fi

git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"

log "완료"
log "다음: 새 터미널 열거나 'exec zsh'"
log "체크: nvim --version ; lazygit --version ; gh --version ; jq --version ; yazi --version"
EOF

chmod +x ~/dotfiles/bootstrap/install_macos.sh
