# linux-dotfiles-setup

My personal shell configuration for zsh and neovim.

## What's included

- `zshrc` — zsh config with Oh My Zsh (agnoster theme), zoxide, nvim as editor, and pixi on PATH
- `init.vim` — neovim config with vim-plug, gruvbox theme, NERDTree, fzf, airline, and more
- `install.sh` — bootstrap script to set everything up on a fresh machine

## Requirements

- macOS (`brew`), Ubuntu/Debian (`apt`), Fedora/RHEL (`dnf`), or CentOS/older RHEL (`yum`)
- Run as a normal user — the script uses `sudo` internally where needed
- Internet connectivity (checked via `curl`, `wget`, or `ping`)

---

## Setup on a new machine

```bash
git clone https://git.fda.gov/FDA/OC/FORGE/linux-dotfiles-setup ~/linux-dotfiles-setup
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

### Installation Options

**Interactive mode (default):**

```bash
./install.sh
```

The script will prompt you before overwriting existing `.zshrc` or `init.vim` files.

**Non-interactive mode:**
```bash
./install.sh -y

# or
./install.sh --non-interactive
```

Automatically overwrites existing configuration files without prompting (useful for automated deployments).

---

## What the script does

The script will:

1. Check internet connectivity using available tools (`ping`)
2. Install `zsh` via the system package manager (`brew`, `apt`, `dnf`, or `yum`)
3. Install Oh My Zsh
4. Install `pixi`
5. Install all tools via pixi: `neovim`, `python`, `zoxide`, `ffmpeg`, `7zip`, `jq`, `poppler`, `ripgrep`, `fzf`, `resvg`, `imagemagick`, `rsync`, `rclone`, `universal-ctags`, `tmux`, `wget`, `unzip`, `curl`
6. Install `pynvim` via pip (required by UltiSnips)
7. Install MesloLGS Nerd Font (all 4 variants: Regular, Bold, Italic, Bold Italic) on both Linux and macOS
8. Copy `zshrc` to `~/.zshrc` (prompts before overwriting in interactive mode)
9. Copy `init.vim` to `~/.config/nvim/init.vim` (prompts before overwriting in interactive mode)
10. Pre-install all nvim plugins headlessly
11. Set zsh as your default shell

---

## Post-installation

After the script finishes:

1. **Log out and back in** to start using zsh
2. **Set your terminal font** to **MesloLGS NF**
   - The font is already installed by the script
   - Just configure your terminal emulator to use it
   - On macOS, you may need to restart your terminal after installation

---

## Troubleshooting

If something breaks, check `~/dotfiles-install.log` — each failed step prints the manual recovery command.


## Updating

To update your dotfiles:

```bash
cd ~/dotfiles
git pull
./install.sh
```


The script will skip already-installed components and only update changed files (with prompts in interactive mode).