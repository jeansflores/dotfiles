export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="half-life"

plugins=(git zsh-autosuggestions)

source $ZSH/oh-my-zsh.sh

eval "$(~/.local/bin/mise activate zsh)"
