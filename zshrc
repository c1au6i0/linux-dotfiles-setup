# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="agnoster"

setopt HIST_IGNORE_SPACE

plugins=(git)

source $ZSH/oh-my-zsh.sh

# PATH
export PATH="$HOME/.pixi/bin:$HOME/.local/bin:$PATH"

# Editor
export EDITOR="nvim"
export SYSTEMD_EDITOR=nvim

# zoxide (smart cd)
eval "$(zoxide init zsh)"

# Auto-Warpify (safe no-op if not using Warp)
[[ "$-" == *i* ]] && printf 'P$f{"hook": "SourcedRcFileForWarp", "value": { "shell": "zsh", "uname": "Linux" }}\x9c'

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
# [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
