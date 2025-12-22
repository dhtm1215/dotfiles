# ~/.config/zsh/10-p10k-ohmyzsh.zsh

# p10k (있을 때만)
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
[[ -f "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"

# oh-my-zsh (있을 때만)
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

[[ -f "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"
