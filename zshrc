# Tools installed by Pixi, plus user scripts.
export PATH="${PIXI_HOME:-$HOME/.pixi}/bin:$HOME/.local/bin:$PATH"
export ZSH="$HOME/.oh-my-zsh"
# Linux virtual consoles use console fonts, without Nerd Font symbols.
if [[ "${TERM:-}" == linux ]]; then
  ZSH_THEME=""
else
  ZSH_THEME="agnoster"
fi
setopt HIST_IGNORE_SPACE
plugins=(git)
[[ ! -r "$ZSH/oh-my-zsh.sh" ]] || source "$ZSH/oh-my-zsh.sh"
if [[ "${TERM:-}" == linux ]]; then
  PROMPT='%m [%1/] > '
  RPROMPT=''
fi
if command -v nvim >/dev/null 2>&1; then
  export EDITOR=nvim
  export SYSTEMD_EDITOR=nvim
fi
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# Launch Yazi and return to the directory selected when quitting with q.
function y() {
  local tmp cwd result=0
  tmp=$(mktemp -t yazi-cwd.XXXXXX) || return 1
  command yazi "$@" --cwd-file="$tmp" || result=$?
  IFS= read -r -d '' cwd < "$tmp" || true
  [[ -z "$cwd" || "$cwd" == "$PWD" || ! -d "$cwd" ]] || builtin cd -- "$cwd"
  command rm -f -- "$tmp"
  return "$result"
}

# Machine-specific additions survive installer updates.
[[ ! -r "$HOME/.zshrc.local" ]] || source "$HOME/.zshrc.local"

# Show system details only in an interactive terminal. Set to 1 locally to disable.
if [[ -o interactive && -t 1 && "${DOTFILES_NO_NEOFETCH:-0}" != 1 ]] && command -v neofetch >/dev/null 2>&1; then
  neofetch
fi
