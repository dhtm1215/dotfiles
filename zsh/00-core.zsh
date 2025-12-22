# ~/.config/zsh/00-core.zsh

# helper
has() { command -v "$1" >/dev/null 2>&1; }

# history
setopt hist_ignore_dups
setopt share_history
HISTSIZE=50000
SAVEHIST=50000
HISTFILE="$HOME/.zsh_history"

# common PATH (나중에 os 파일에서 보강)
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# nvm (있을 때만)
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"

# pyenv (있을 때만)
export PYENV_ROOT="$HOME/.pyenv"
if [[ -d "$PYENV_ROOT" ]]; then
  export PATH="$PYENV_ROOT/bin:$PATH"
  has pyenv && eval "$(pyenv init -)"
fi

# GCP(필요하면 유지. 싫으면 .zshrc.local로 빼)
export GOOGLE_CLOUD_PROJECT="norse-ego-458401-k7"
