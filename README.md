# A familiar terminal on a new machine

Set up Zsh, Neovim, and Yazi with the same configuration across your computers.
Zsh provides the shell, Neovim the editor, and Yazi a file manager inside the terminal.
The installer also adds tools for search, previews, and backups.

Supports Linux with apt, dnf, or yum, and macOS with Homebrew already installed.
You need internet access and permission to install missing system packages.
Run as your normal user; the script uses `sudo` for system changes when needed.

## Get started

Clone the repository and run the installer:

```bash
git clone https://github.com/c1au6i0/linux-dotfiles-setup.git
cd linux-dotfiles-setup
bash install.sh
```

**Allow several minutes for the first installation.** Downloading Pixi, installing
packages, and fetching editor plugins can take longer on a slow connection.
Some steps may be quiet while they work.

Progress messages appear in the terminal; full installation output is appended
to `~/dotfiles-install.log`. To see that output in the terminal too, use:

```bash
bash install.sh --verbose
```

`-v` is the short form. Combine it with other options, for example
`bash install.sh --verbose --keep-shell`. With no verbose flag, output stays
concise. To watch an installation already running, open another terminal and run:

```bash
tail -f ~/dotfiles-install.log
```

Press Ctrl-C in that second terminal to stop watching; installation continues.

If you extracted the archive, skip the `git clone` line and enter the extracted
folder. Review the prompts before replacing existing configuration. Then run
`zsh` to try the new shell.

**The installer uses Zsh as your default shell for future logins.** It may ask
for your password to update your account. On Linux it uses sudo when available,
so you do not need to run a separate `chsh` command.

To keep your current default shell instead:

```bash
bash install.sh --keep-shell
```

`--use-zsh` explicitly selects the default behavior. The older `--change-shell`
option remains an alias. If both shell options are supplied, the last one wins.
The installer does not replace the shell running in your current terminal;
run `exec zsh` to start using Zsh immediately.
Log out and back in afterward. Select **MesloLGS NF** in your terminal's font
settings for prompt symbols. The installer downloads the font; for SSH, select
it in the terminal on your own computer.

Use `bash install.sh -y` to accept configuration replacements automatically.
Passwords may still be required, including for the default-shell change.

## What you get

| Part | Included tools and purpose |
| --- | --- |
| Shell | Zsh, Oh My Zsh, the agnoster prompt, Git shortcuts, and zoxide for directory navigation. Neofetch displays system details at startup. |
| Editor | Neovim with gruvbox, a file tree, fuzzy search, Git integration, snippets, and session management. |
| File manager | Yazi, plus ffmpeg, 7zip, jq, poppler, fd, ripgrep, fzf, resvg, and ImageMagick for previews, archives, and search. |
| Utilities | rsync, rclone, universal-ctags, tmux, wget, unzip, curl, and Python. |

Existing commands are reused. Missing user tools use **Pixi**, a package manager
the script installs automatically. Zsh, curl, Git, and `file` use your system
package manager. Neovim's Python support uses a separate environment, leaving
system Python alone. Missing Neofetch is downloaded as version 7.1.0.
You do not need a separate apt command for Yazi's whole dependency list.

## Kitty and Ghostty over SSH

The server needs a terminal definition, called **terminfo**, to interpret cursor
movement, editing keys, and screen updates. Missing definitions can make text
appear duplicated or editing behave incorrectly.

The installer detects Kitty (`xterm-kitty`) or Ghostty (`xterm-ghostty`) from
`$TERM`, reuses an existing definition, or tries your system's terminfo packages.
It installs terminal definitions, not the Kitty or Ghostty graphical application.
Use an explicit choice if detection is hidden by tmux or another terminal:

```bash
bash install.sh --terminal kitty
bash install.sh --terminal ghostty
```

`--terminal auto` is the default; `--terminal none` skips this step. These options
do not change `$TERM` or your terminal settings. On older systems the packages
may still lack the required definition; the installer checks and warns afterward.

Alternatively, Kitty's SSH helper transfers its definition automatically. Run
this **on your local computer inside Kitty**, using your own SSH host name:

```bash
kitten ssh your-host
```

For Ghostty, copy the definition **from your local computer** to the server:

```bash
infocmp -x xterm-ghostty | ssh epsi-jon 'tic -x -o ~/.terminfo -'
```

The server needs `tic` (`ncurses-bin` on Debian/Ubuntu). If your Mac's bundled
`infocmp` is too old, use the version from Homebrew's ncurses package instead.
Verify **on the server** with `infocmp "$TERM" >/dev/null`; no error means the
current terminal is recognized. Definitions stored in `~/.terminfo` can be
removed individually to undo a manual copy.

See the official [Kitty SSH guide](https://sw.kovidgoyal.net/kitty/kittens/ssh/)
and [Ghostty terminfo guide](https://ghostty.org/docs/help/terminfo).
This compatibility setup does not diagnose intermittent SSH or input lag.

## Local Linux console

When you log in directly on the server's text console (`TERM=linux`), Zsh uses
a simple prompt with the machine name and current folder, such as
`epsi-jon [linux-dotfiles-setup] >`. At home it shows `epsi-jon [heverz] >`,
without a tilde. It avoids decorative symbols that console fonts may not display.
You still use Zsh, zoxide, and the other shell features.

Kitty and Ghostty sessions keep the agnoster prompt; select MesloLGS NF in your
local terminal for its symbols. Detection happens each time Zsh starts, so you
can use the same configuration locally and over SSH. Personal prompt settings
in `~/.zshrc.local` can override either default.

## Everyday use

```bash
y             # Browse files; quit with q to keep the selected directory
z projects    # Jump to a matching directory you have visited before
nvim notes.md # Open or create a file
```

In Neovim, `F3` toggles the file tree and `,e` opens the file picker.
The comma is the prefix for custom shortcuts.

Put personal shell settings in `~/.zshrc.local`; installation leaves it alone.
To hide Neofetch at startup, add this there:

```zsh
export DOTFILES_NO_NEOFETCH=1
```

For Neovim, use `local_init.vim` for settings and `local_bundles.vim` for extra
plugins inside `~/.config/nvim` (or `$XDG_CONFIG_HOME/nvim` if set).

## Changes, updates, and undo

The script writes `~/.zshrc` and Neovim's `init.vim`. Before replacing a different
existing file, it asks and saves a unique `.bak.*` copy beside it. It also installs
tools, plugins, and fonts. Unless you use `--keep-shell`, it sets Zsh as your
default login shell and may add it to `/etc/shells`.

Rerun `bash install.sh` to apply configuration updates or retry missing tools.
Identical configuration is skipped. Existing tools are not automatically
upgraded, and editor plugins are not pinned to fixed versions.

To restore a configuration, copy the desired `.bak.*` file over its original.
To restore your previous shell, use `chsh -s /path/to/previous-shell`
(often `/bin/bash` on Linux). Tools, plugins, and fonts must be removed
separately; there is no complete uninstall command.

## If something fails

Check `~/dotfiles-install.log`. Missing required tools stop installation.
Optional failures are summarized with exit status 1; earlier steps may already
have completed. Fix the reported issue and rerun the installer; completed tools
are reused. If an older installer stopped with "Required tool nvim is missing,"
update this repository and rerun: the corrected installer installs the editor
from the conda-forge `nvim` package (the `neovim` package is a Python client).

- **Existing Neovim `init.lua`:** installation stops at Neovim configuration.
  Reconcile it with this setup before rerunning.
- **Default shell did not change:** read the reported authentication error.
  On Linux, retry with `sudo chsh -s /path/to/zsh your-username`, using the path
  and username printed by the installer. Then log out and reconnect.
- **Missing editor plugins:** run `:PlugInstall` inside Neovim.
- **Missing Yazi previews:** run `yazi --debug` and check the relevant helper.
  Reused tools may need upgrading for compatibility.
- **Clipboard trouble:** on Linux desktops, install `wl-clipboard` for Wayland
  or `xclip` for X11. Clipboard and image previews over SSH depend on your terminal.

See Yazi's [quick start](https://yazi-rs.github.io/docs/quick-start/) for more.
Contributor guidance lives in [AGENTS.md](AGENTS.md).



