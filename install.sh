#!/usr/bin/env bash
set -euo pipefail

LOGFILE="$HOME/dotfiles-install.log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check for non-interactive mode
INTERACTIVE=true
if [[ "${1:-}" == "--non-interactive" ]] || [[ "${1:-}" == "-y" ]]; then
  INTERACTIVE=false
fi

log()  { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOGFILE"; }
die()  { log "ERROR: $*"; log "Check $LOGFILE for details. Exiting."; exit 1; }
warn() { log "WARNING: $*"; }
skip() { log "    Already installed, skipping"; }

ask_overwrite() {
  local file="$1"
  local prompt="${2:-Do you want to overwrite $file?}"
  
  if [ "$INTERACTIVE" = false ]; then
    return 0  # Always overwrite in non-interactive mode
  fi
  
  while true; do
    read -p "$prompt [y/N] " -n 1 -r
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

# --- Internet check ---
log "==> Checking internet connectivity"
if ping -c 1 -W 2 8.8.8.8 > /dev/null 2>&1 || ping -c 1 -W 2 1.1.1.1 > /dev/null 2>&1; then
  log "    OK"
else
  die "No internet connection detected. Please connect and re-run."
fi

# --- Detect package manager ---
if command -v brew &>/dev/null; then
  PKG_MANAGER="brew"
  PKG_INSTALL="brew install"
  PKG_UPDATE="brew update"
elif command -v apt &>/dev/null; then
  PKG_MANAGER="apt"
  PKG_INSTALL="sudo apt install -y"
  PKG_UPDATE="sudo apt update"
elif command -v dnf &>/dev/null; then
  PKG_MANAGER="dnf"
  PKG_INSTALL="sudo dnf install -y"
  PKG_UPDATE="sudo dnf check-update || true"
elif command -v yum &>/dev/null; then
  PKG_MANAGER="yum"
  PKG_INSTALL="sudo yum install -y"
  PKG_UPDATE="sudo yum check-update || true"
else
  die "No supported package manager found (brew, apt, dnf, yum). Install zsh manually then re-run."
fi
log "==> Detected package manager: $PKG_MANAGER"

# --- zsh (system package, required for chsh) ---
log "==> Checking zsh"
if command -v zsh &>/dev/null; then
  skip
else
  $PKG_UPDATE >> "$LOGFILE" 2>&1
  $PKG_INSTALL zsh >> "$LOGFILE" 2>&1 \
    || die "zsh install failed. Try '$PKG_INSTALL zsh' manually."
fi

# --- Ensure zsh is in /etc/shells (required for chsh) ---
ZSH_PATH="$(which zsh)"
if ! grep -qF "$ZSH_PATH" /etc/shells; then
  log "==> Adding $ZSH_PATH to /etc/shells"
  echo "$ZSH_PATH" | sudo tee -a /etc/shells >> "$LOGFILE" \
    || warn "Could not add zsh to /etc/shells. Run: echo '$ZSH_PATH' | sudo tee -a /etc/shells"
else
  log "==> $ZSH_PATH already in /etc/shells, skipping"
fi

# --- Oh My Zsh ---
log "==> Checking Oh My Zsh"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  log "    Installing Oh My Zsh"
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" >> "$LOGFILE" 2>&1 \
    || die "Oh My Zsh install failed. See $LOGFILE or install manually: https://ohmyz.sh/#install"
else
  skip
fi

# --- pixi ---
log "==> Checking pixi"
if ! command -v pixi &>/dev/null; then
  log "    Installing pixi"
  curl -fsSL https://pixi.sh/install.sh | bash >> "$LOGFILE" 2>&1 \
    || die "pixi install failed. See $LOGFILE or install manually: https://pixi.sh"
else
  skip
fi
# Always ensure pixi is on PATH for the rest of this session
export PATH="$HOME/.pixi/bin:$PATH"
command -v pixi &>/dev/null || die "pixi not found on PATH. Open a new terminal and re-run the script."

# --- Tools via pixi ---
log "==> Checking tools via pixi"
PIXI_TOOLS=(
  neovim
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
  pynvim
)

for tool in "${PIXI_TOOLS[@]}"; do
  if pixi global list 2>/dev/null | grep -qF "$tool"; then
    log "    $tool already installed, skipping"
  else
    log "    installing $tool"
    pixi global install "$tool" >> "$LOGFILE" 2>&1 \
      || warn "$tool failed to install. Try 'pixi global install $tool' manually."
  fi
done

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
      if curl -fLo "$FONT_PATH" "$FONT_BASE_URL/$font" >> "$LOGFILE" 2>&1; then
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
    cp "$HOME/.zshrc" "$HOME/.zshrc.bak"
    log "    Existing .zshrc backed up to ~/.zshrc.bak"
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
NVIM_CONFIG="$HOME/.config/nvim/init.vim"
INSTALL_NVIM_CONFIG=false

if [ ! -f "$NVIM_CONFIG" ]; then
  INSTALL_NVIM_CONFIG=true
elif diff -q "$SCRIPT_DIR/init.vim" "$NVIM_CONFIG" &>/dev/null; then
  log "    Already up to date, skipping"
elif ask_overwrite "$NVIM_CONFIG" "Different init.vim exists. Overwrite?"; then
  cp "$NVIM_CONFIG" "${NVIM_CONFIG}.bak"
  log "    Existing init.vim backed up to ${NVIM_CONFIG}.bak"
  INSTALL_NVIM_CONFIG=true
else
  log "    Skipping init.vim (user chose not to overwrite)"
fi

if [ "$INSTALL_NVIM_CONFIG" = true ]; then
  mkdir -p "$HOME/.config/nvim"
  cp "$SCRIPT_DIR/init.vim" "$NVIM_CONFIG" \
    || die "Could not copy init.vim to $NVIM_CONFIG. Check permissions."
  log "    Written to $NVIM_CONFIG"
  
  log "==> Installing nvim plugins (this may take a moment)"
  NVIM_BIN="$HOME/.pixi/bin/nvim"
  NVIM=$(command -v "$NVIM_BIN" 2>/dev/null || command -v nvim 2>/dev/null || true)
  if [ -n "$NVIM" ]; then
    "$NVIM" --headless +PlugInstall +qall >> "$LOGFILE" 2>&1 \
      && log "    Plugins installed" \
      || warn "Headless plugin install failed. Run ':PlugInstall' manually inside nvim."
  else
    warn "nvim not found on PATH yet. Run ':PlugInstall' manually on first nvim launch."
  fi
fi

# --- Default shell ---
log "==> Checking default shell"
if [ "$SHELL" = "$ZSH_PATH" ]; then
  log "    Already set to zsh, skipping"
else
  chsh -s "$ZSH_PATH" \
    || warn "chsh failed. Run 'chsh -s $ZSH_PATH' manually, or ask your sysadmin."
fi

log ""
log "All done! Log out and back in to start using zsh."
log "Don't forget to set MesloLGS NF as your terminal font."
