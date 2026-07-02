# ubuntu-setup

Personal Ubuntu dev environment setup for João Pedro Sedrez.

Run once on a fresh Ubuntu install and get everything configured automatically.

## Usage

```bash
git clone git@github.com:JoaoPedroSedrezPX/ubuntu-setup.git && cd ubuntu-setup && bash setup.sh
```

## What gets installed

**Shell & Terminal**
- Zsh + Oh My Zsh + Zinit (syntax highlighting, autosuggestions, completions)
- Starship prompt with Catppuccin Mocha theme
- Kitty terminal with custom config (Catppuccin Mocha, JetBrains Mono, blur)
- FiraCode Nerd Font + JetBrains Mono

**Runtimes & Languages**
- nvm + Node 22 (yarn, bun, pnpm, gemini-cli)
- PHP 8.1 + 8.2 via ondrej/php PPA + Composer
- Java (via Android Studio JBR)

**Dev Tools**
- Docker Desktop
- GitHub CLI (official PPA)
- lazygit, fzf, ripgrep, fd, btop, tldr, xclip
- direnv + zoxide
- Neovim (via [henriquemattia/nvim](https://github.com/henriquemattia/nvim))
- JetBrains Toolbox (install WebStorm, PhpStorm, DataGrip manually after)

**Apps (Snap)**
- VS Code, Android Studio, Discord, Obsidian, Slack, Spotify
- Teams for Linux, Tailscale, Flutter, Bitwarden, Postman, Emote

**Apps (Flatpak)**
- Zen Browser, OBS Studio, Bruno, DBeaver, Flameshot, ZapZap, Stremio

**Other**
- Teleport Connect
- GNOME extensions (blur-my-shell, clipboard-indicator, dash-to-dock, just-perfection, runcat, pomodoro, and more)
- Android/React Native environment (ANDROID_HOME, KVM, watchman)
- inotify limits (permanent)
- Ç keyboard fix (.XCompose)

## After running

1. **Add SSH key to GitHub**: the script will print your public key — add it at https://github.com/settings/keys
2. **Install IDEs via JetBrains Toolbox**: open `jetbrains-toolbox` and install WebStorm, PhpStorm, DataGrip
3. **Import IDE settings**: export settings from your old machine via `File > Manage IDE Settings > Export Settings`, drop the zip into `configs/jetbrains/`, then import on the new machine

## Configs in this repo

| Path | What |
|------|------|
| `configs/kitty/kitty.conf` | Kitty terminal config (Catppuccin Mocha) |
| `configs/jetbrains/` | JetBrains IDE settings exports (add manually) |

## Neovim

Neovim config lives in its own repo: [henriquemattia/nvim](https://github.com/henriquemattia/nvim).  
The setup script clones it and runs its `install.sh` automatically.
