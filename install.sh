#!/usr/bin/env bash
set -euo pipefail

LOGFILE="$HOME/dotfiles-install.log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check for non-interactive mode
INTERACTIVE=true
CHANGE_SHELL=false
for arg in "$@"; do
  case "$arg" in
    -y|--non-interactive) INTERACTIVE=false ;;
    --change-shell) CHANGE_SHELL=true ;;
    -h|--help)
      echo "Usage: bash install.sh [-y|--non-interactive] [--change-shell]"
      echo "-y accepts config replacement; --change-shell makes zsh the login shell."
      exit 0 ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done
WARNINGS=()
export PATH="${PIXI_HOME:-$HOME/.pixi}/bin:$HOME/.local/bin:$PATH"
trap 'printf "ERROR at line %s. See %s\n" "$LINENO" "$LOGFILE" >&2' ERR

log()  { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOGFILE"; }
die()  { log "ERROR: $*"; log "Check $LOGFILE for details. Exiting."; exit 1; }
warn() { WARNINGS+=("$*"); log "WARNING: $*"; }
skip() { log "    Already installed, skipping"; }

ask_overwrite() {
  local file="$1"
  local prompt="${2:-Do you want to overwrite $file?}"
  
  if [ "$INTERACTIVE" = false ]; then
    return 0  # Always overwrite in non-interactive mode
  fi
  
  while true; do
    if ! read -p "$prompt [y/N] " -n 1 -r; then
      echo; return 1
    fi
    echo
    case $REPLY in
      [Yy]) return 0 ;;
      [Nn]|"") return 1 ;;
      *) echo "Please answer y or n." ;;
    esac
  done
}

log "Starting dotfiles install. Full log at $LOGFILE"

# --- Must not run as root ---
if [ "$EUID" -eq 0 ]; then
  die "Do not run this script as root. Run as your normal user — sudo will be used where needed."
fi

# --- Detect package manager ---
if command -v brew &>/dev/null; then
  PKG_MANAGER="brew"
  PKG_INSTALL=(brew install)
  PKG_UPDATE=(brew update)
elif command -v apt &>/dev/null; then
  PKG_MANAGER="apt"
  PKG_INSTALL=(sudo apt-get install -y)
  PKG_UPDATE=(sudo apt-get update)
elif command -v dnf &>/dev/null; then
  PKG_MANAGER="dnf"
  PKG_INSTALL=(sudo dnf install -y)
  PKG_UPDATE=(sudo dnf makecache)
elif command -v yum &>/dev/null; then
  PKG_MANAGER="yum"
  PKG_INSTALL=(sudo yum install -y)
  PKG_UPDATE=(sudo yum makecache)
else
  die "No supported package manager found (brew, apt, dnf, yum). Install zsh manually then re-run."
fi
log "==> Detected package manager: $PKG_MANAGER"

# Bootstrap dependencies must be present before any remote installer runs.
MISSING=()
for tool in zsh curl git file; do
  command -v "$tool" >/dev/null 2>&1 || MISSING+=("$tool")
done
if [ "${#MISSING[@]}" -gt 0 ]; then
  log "==> Installing bootstrap dependencies: ${MISSING[*]}"
  "${PKG_UPDATE[@]}" >> "$LOGFILE" 2>&1 || die "Package metadata refresh failed."
  "${PKG_INSTALL[@]}" "${MISSING[@]}" >> "$LOGFILE" 2>&1 || die "Bootstrap install failed."
fi
log "==> Checking HTTPS access"
curl -fsSL --connect-timeout 10 --max-time 30 -o /dev/null https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh \
  || die "Cannot reach GitHub over HTTPS; check DNS, proxy, and network access."
TEMP_DIR=$(mktemp -d)
trap 'rm -rf -- "$TEMP_DIR"' EXIT

# --- Ensure zsh is in /etc/shells (required for chsh) ---
ZSH_PATH="$(command -v zsh)"
if [ "$CHANGE_SHELL" = true ] && ! grep -qxF "$ZSH_PATH" /etc/shells; then
  log "==> Adding $ZSH_PATH to /etc/shells"
  echo "$ZSH_PATH" | sudo tee -a /etc/shells >> "$LOGFILE" \
    || warn "Could not add zsh to /etc/shells. Run: echo '$ZSH_PATH' | sudo tee -a /etc/shells"
else
  log "==> $ZSH_PATH shell registration unchanged"
fi

# --- Oh My Zsh ---
log "==> Checking Oh My Zsh"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  log "    Installing Oh My Zsh"
  curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o "$TEMP_DIR/ohmyzsh.sh" \
    || die "Oh My Zsh download failed."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh "$TEMP_DIR/ohmyzsh.sh" >> "$LOGFILE" 2>&1 \
    || die "Oh My Zsh install failed."
else
  skip
fi

# --- pixi ---
log "==> Checking pixi"
if ! command -v pixi &>/dev/null; then
  log "    Installing pixi"
  curl -fsSL https://pixi.sh/install.sh -o "$TEMP_DIR/pixi.sh" || die "Pixi download failed."
  PIXI_NO_PATH_UPDATE=1 bash "$TEMP_DIR/pixi.sh" >> "$LOGFILE" 2>&1 || die "Pixi install failed."
else
  skip
fi
# Always ensure pixi is on PATH for the rest of this session
export PATH="${PIXI_HOME:-$HOME/.pixi}/bin:$PATH"
command -v pixi &>/dev/null || die "pixi not found on PATH. Open a new terminal and re-run the script."

# --- Tools via pixi ---
log "==> Checking tools via pixi"
PIXI_TOOLS=(
  nvim
  yazi
  fd-find
  zoxide
  ffmpeg
  7zip
  jq
  poppler
  ripgrep
  fzf
  resvg
  imagemagick
  rsync
  rclone
  universal-ctags
  tmux
  wget
  unzip
  curl
  python
)

# Package names can differ from executable names. Check runnable commands,
# so an existing system installation (including zoxide) is reused.
for tool in "${PIXI_TOOLS[@]}"; do
  executable="$tool"
  case "$tool" in
    fd-find) executable=fd ;;
    ripgrep) executable=rg ;;
    poppler) executable=pdftoppm ;;
    universal-ctags) executable=ctags ;;
    imagemagick) executable=magick ;;
    7zip) executable=7zz ;;
  esac
  if command -v "$executable" >/dev/null 2>&1; then
    log "    $tool already available, skipping"
  else
    log "    Installing $tool"
    pixi global install --channel conda-forge "$tool" >> "$LOGFILE" 2>&1 \
      || warn "$tool failed: run pixi global install --channel conda-forge $tool"
  fi
done
for tool in zsh nvim yazi; do
  command -v "$tool" >/dev/null 2>&1 || die "Required tool $tool is missing. Fix installation and rerun."
done

# Keep the editor's Python provider in its own environment, with a unique shim.
if ! command -v nvim-python >/dev/null 2>&1 || ! nvim-python -c 'import pynvim' >> "$LOGFILE" 2>&1; then
  pixi global install --channel conda-forge --environment dotfiles-nvim-python \
    --expose nvim-python=python python pynvim >> "$LOGFILE" 2>&1 \
    || warn "Neovim Python provider failed to install; snippets may not work."
fi
if [[ "$(uname)" == Linux ]]; then
  if ! command -v wl-copy >/dev/null 2>&1 && ! command -v xclip >/dev/null 2>&1 && ! command -v xsel >/dev/null 2>&1; then
    log "    Optional clipboard: install wl-clipboard for Wayland or xclip for X11. SSH clipboard depends on your terminal."
  fi
fi

# Neofetch is a Bash script; install a tagged upstream release into user space.
if ! command -v neofetch >/dev/null 2>&1; then
  log "==> Installing Neofetch 7.1.0"
  if curl -fsSL --connect-timeout 10 --max-time 60 \
    https://raw.githubusercontent.com/dylanaraps/neofetch/7.1.0/neofetch -o "$TEMP_DIR/neofetch"; then
    mkdir -p "$HOME/.local/bin"
    install -m 755 "$TEMP_DIR/neofetch" "$HOME/.local/bin/neofetch" \
      || warn "Could not install Neofetch."
  else
    warn "Neofetch download failed; shell startup will skip it."
  fi
fi

# --- Font (non-fatal) ---
log "==> Checking MesloLGS Nerd Font"
FONT_DIR="$HOME/.local/share/fonts"
FONT_BASE_URL="https://github.com/romkatv/powerlevel10k-media/raw/master"

if [[ "$(uname)" == "Darwin" ]]; then
  FONT_DIR="$HOME/Library/Fonts"
fi

FONT_VARIANTS=(
  "MesloLGS%20NF%20Regular.ttf"
  "MesloLGS%20NF%20Bold.ttf"
  "MesloLGS%20NF%20Italic.ttf"
  "MesloLGS%20NF%20Bold%20Italic.ttf"
)

FONTS_INSTALLED=0
FONTS_NEEDED=0

for font in "${FONT_VARIANTS[@]}"; do
  FONT_NAME="${font//%20/ }"
  FONT_PATH="$FONT_DIR/$FONT_NAME"
  
  if [ -f "$FONT_PATH" ]; then
    FONTS_INSTALLED=$((FONTS_INSTALLED + 1))
  else
    FONTS_NEEDED=$((FONTS_NEEDED + 1))
  fi
done

if [ $FONTS_NEEDED -eq 0 ]; then
  log "    All variants already installed, skipping"
else
  mkdir -p "$FONT_DIR"
  log "    Installing $FONTS_NEEDED font variant(s)"
  
  for font in "${FONT_VARIANTS[@]}"; do
    FONT_NAME="${font//%20/ }"
    FONT_PATH="$FONT_DIR/$FONT_NAME"
    
    if [ ! -f "$FONT_PATH" ]; then
      if curl -fL --connect-timeout 10 --max-time 60 -o "$TEMP_DIR/font.ttf" "$FONT_BASE_URL/$font" >> "$LOGFILE" 2>&1; then
        mv "$TEMP_DIR/font.ttf" "$FONT_PATH"
        log "      ✓ $FONT_NAME"
      else
        warn "Failed to download $FONT_NAME"
      fi
    fi
  done
  
  # Refresh font cache
  if [[ "$(uname)" != "Darwin" ]]; then
    fc-cache -fv >> "$LOGFILE" 2>&1 && log "    Font cache updated" || warn "fc-cache failed — run 'fc-cache -fv' manually"
  else
    log "    Fonts installed to ~/Library/Fonts (restart terminal to use)"
  fi
fi

# --- zshrc ---
log "==> Checking zshrc"
if diff -q "$SCRIPT_DIR/zshrc" "$HOME/.zshrc" &>/dev/null; then
  log "    Already up to date, skipping"
elif [ -f "$HOME/.zshrc" ]; then
  if ask_overwrite "$HOME/.zshrc" "Existing .zshrc found. Overwrite?"; then
    backup=$(mktemp "$HOME/.zshrc.bak.XXXXXXXX")
    cp -p "$HOME/.zshrc" "$backup"
    log "    Existing .zshrc backed up to $backup"
    cp "$SCRIPT_DIR/zshrc" "$HOME/.zshrc" \
      || die "Could not copy zshrc to $HOME/.zshrc. Check permissions."
    log "    Written to $HOME/.zshrc"
  else
    log "    Skipping .zshrc (user chose not to overwrite)"
  fi
else
  cp "$SCRIPT_DIR/zshrc" "$HOME/.zshrc" \
    || die "Could not copy zshrc to $HOME/.zshrc. Check permissions."
  log "    Written to $HOME/.zshrc"
fi

# --- nvim config ---
log "==> Checking init.vim"
NVIM_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/nvim/init.vim"
if [ -f "${NVIM_CONFIG%/*}/init.lua" ]; then
  die "An init.lua already exists; resolve the Neovim config conflict before installing."
fi
INSTALL_NVIM_CONFIG=false

if [ ! -f "$NVIM_CONFIG" ]; then
  INSTALL_NVIM_CONFIG=true
elif diff -q "$SCRIPT_DIR/init.vim" "$NVIM_CONFIG" &>/dev/null; then
  log "    Already up to date, skipping"
elif ask_overwrite "$NVIM_CONFIG" "Different init.vim exists. Overwrite?"; then
  backup=$(mktemp "${NVIM_CONFIG}.bak.XXXXXXXX")
  cp -p "$NVIM_CONFIG" "$backup"
  log "    Existing init.vim backed up to $backup"
  INSTALL_NVIM_CONFIG=true
else
  log "    Skipping init.vim (user chose not to overwrite)"
fi

if [ "$INSTALL_NVIM_CONFIG" = true ]; then
  mkdir -p "${NVIM_CONFIG%/*}"
  cp "$SCRIPT_DIR/init.vim" "$NVIM_CONFIG" \
    || die "Could not copy init.vim to $NVIM_CONFIG. Check permissions."
  log "    Written to $NVIM_CONFIG"
  
fi

if diff -q "$SCRIPT_DIR/init.vim" "$NVIM_CONFIG" >/dev/null 2>&1; then
  log "==> Installing missing nvim plugins (this may take a moment)"
  NVIM_BIN="${PIXI_HOME:-$HOME/.pixi}/bin/nvim"
  NVIM=$(command -v "$NVIM_BIN" 2>/dev/null || command -v nvim 2>/dev/null || true)
  if [ -n "$NVIM" ]; then
    "$NVIM" --headless "+PlugInstall --sync" +qall >> "$LOGFILE" 2>&1 \
      && log "    Plugins installed" \
      || warn "Headless plugin install failed. Run ':PlugInstall' manually inside nvim."
  else
    warn "nvim not found on PATH yet. Run ':PlugInstall' manually on first nvim launch."
  fi
fi

# --- Default shell ---
log "==> Checking default shell"
if [ "$CHANGE_SHELL" != true ]; then
  log "    Unchanged. Use --change-shell to make zsh your login shell."
elif [ "${SHELL:-}" = "$ZSH_PATH" ]; then
  log "    Already set to zsh, skipping"
else
  chsh -s "$ZSH_PATH" \
    || warn "chsh failed. Run 'chsh -s $ZSH_PATH' manually, or ask your sysadmin."
fi

log ""
log "Setup finished. Start zsh with: zsh"
if [ "${#WARNINGS[@]}" -gt 0 ]; then
  log "Completed with ${#WARNINGS[@]} warning(s):"
  for message in "${WARNINGS[@]}"; do log "  - $message"; done
  exit 1
fi
log "Don't forget to set MesloLGS NF as your terminal font."
