# ~/.config/zsh/30-fzf.zsh

has() { command -v "$1" >/dev/null 2>&1; }
has fzf || return 0

# 1) keybindings/completion 로드 (linux/apt)
[[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]] && source /usr/share/doc/fzf/examples/key-bindings.zsh
[[ -f /usr/share/doc/fzf/examples/completion.zsh ]] && source /usr/share/doc/fzf/examples/completion.zsh

# 2) keybindings/completion 로드 (arch/pacman)
[[ -f /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh
[[ -f /usr/share/fzf/completion.zsh ]] && source /usr/share/fzf/completion.zsh

# 3) keybindings/completion 로드 (mac/brew)
if has brew; then
  bp="$(brew --prefix 2>/dev/null)"
  [[ -f "$bp/opt/fzf/shell/key-bindings.zsh" ]] && source "$bp/opt/fzf/shell/key-bindings.zsh"
  [[ -f "$bp/opt/fzf/shell/completion.zsh" ]] && source "$bp/opt/fzf/shell/completion.zsh"
fi

# 4) ~/.fzf.zsh (git 설치 or brew 설치 시 생성될 수도 있음)
[[ -f "$HOME/.fzf.zsh" ]] && source "$HOME/.fzf.zsh"

# 4) 검색 커맨드 (fd/fdfind/fallback)
if has fd; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
elif has fdfind; then
  export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --follow --exclude .git'
else
  export FZF_DEFAULT_COMMAND='find . -type f 2>/dev/null'
fi
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# 5) preview (bat/batcat/fallback)
if has bat; then
  _FZF_PREVIEW="bat --style=numbers --color=always --line-range :500 {}"
elif has batcat; then
  _FZF_PREVIEW="batcat --style=numbers --color=always --line-range :500 {}"
else
  _FZF_PREVIEW="sed -n '1,200p' {}"
fi

export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --preview '$_FZF_PREVIEW'"
unset _FZF_PREVIEW

# 6) 마지막에 강제 바인딩(플러그인 충돌 방지)
bindkey '^R' fzf-history-widget 2>/dev/null || true
bindkey '^T' fzf-file-widget 2>/dev/null || true
