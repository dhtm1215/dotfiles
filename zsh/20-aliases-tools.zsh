# ~/.config/zsh/20-aliases-tools.zsh

has() { command -v "$1" >/dev/null 2>&1; }

# git aliases
alias gc='git commit -m'
alias ga='git add .'
alias gps='git push'
alias gpl='git pull'
alias gpm='git push origin main'
alias gcm='git checkout main'

# cat -> bat (linux는 batcat일 수 있음)
if has bat; then
  alias cat="bat"
  export BAT_THEME="Dracula"
elif has batcat; then
  alias cat="batcat"
  export BAT_THEME="Dracula"
fi

# eza aliases
if has eza; then
  alias ls="eza --icons --git --header"
  alias ll="eza -l --icons --git --header --time-style=long-iso"
  alias lt="eza --tree --level=2 --icons"
fi

# fd 이름 차이
if ! has fd && has fdfind; then
  alias fd="fdfind"
fi

# yazi wrapper (yazi 없으면 메시지)
y() {
  if ! has yazi; then
    echo "yazi not installed"
    return 127
  fi
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
  yazi "$@" --cwd-file="$tmp"
  local cwd
  cwd="$(command cat -- "$tmp" 2>/dev/null)"
  if [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

export GLOW_STYLE="dark"
