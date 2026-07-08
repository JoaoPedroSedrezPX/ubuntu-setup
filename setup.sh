#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Colors & Logging ──────────────────────────────────────────────────────────
step()  { echo -e "\n\033[1;34m▶ $*\033[0m"; }
ok()    { echo -e "\033[0;32m✓ $*\033[0m"; }
skip()  { echo -e "\033[1;33m⏭  $*\033[0m"; }
warn()  { echo -e "\033[1;33m⚠  $*\033[0m"; }
info()  { echo -e "\033[0;36m  $*\033[0m"; }

zshrc_append() {
  local guard="$1"
  local content="$2"
  grep -q "$guard" ~/.zshrc 2>/dev/null || echo "$content" >> ~/.zshrc
}

# ─── Banner ────────────────────────────────────────────────────────────────────
banner() {
  echo -e "\033[1;35m"
  echo "  ╔══════════════════════════════════════════════╗"
  echo "  ║       Ubuntu Dev Setup — JP Sedrez           ║"
  echo "  ╚══════════════════════════════════════════════╝"
  echo -e "\033[0m"
}

# ─── Prompts ───────────────────────────────────────────────────────────────────
collect_prompts() {
  echo ""
  read -rp "  Git name  [João Pedro Sedrez]: " GIT_NAME
  GIT_NAME="${GIT_NAME:-João Pedro Sedrez}"

  read -rp "  Git email [joao.sedrez@px.center]: " GIT_EMAIL
  GIT_EMAIL="${GIT_EMAIL:-joao.sedrez@px.center}"

  read -rp "  Swap size in GB (0 to skip) [0]: " SWAP_GB
  SWAP_GB="${SWAP_GB:-0}"
  echo ""
}

# ─── 1. System Update & Essentials ─────────────────────────────────────────────
setup_system() {
  step "System update & essentials"
  sudo apt update && sudo apt upgrade -y
  sudo apt install -y \
    git curl wget unzip fontconfig python3 \
    xclip direnv zoxide fzf ripgrep fd-find btop tealdeer \
    lsof fastfetch
  fastfetch
  ok "System packages installed"
}

# ─── 2. Git Config ─────────────────────────────────────────────────────────────
setup_git() {
  step "Git config"
  git config --global user.name "$GIT_NAME"
  git config --global user.email "$GIT_EMAIL"
  ok "Git configured: $GIT_NAME <$GIT_EMAIL>"
}

# ─── 3. SSH Key ────────────────────────────────────────────────────────────────
setup_ssh() {
  step "SSH key"
  if [[ -f ~/.ssh/id_ed25519 ]]; then
    skip "SSH key already exists at ~/.ssh/id_ed25519"
  else
    ssh-keygen -t ed25519 -C "$GIT_EMAIL" -N "" -f ~/.ssh/id_ed25519
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_ed25519
    ok "SSH key generated"
  fi
  echo ""
  warn "Add this public key to GitHub → https://github.com/settings/keys"
  echo ""
  cat ~/.ssh/id_ed25519.pub
  echo ""
  info "Testing GitHub connection (may fail if key not yet added)..."
  ssh -T git@github.com 2>&1 || true
  ssh -T git@bitbucket.org 2>&1 || true
}

# ─── 4. Zsh + Oh My Zsh + Zinit ───────────────────────────────────────────────
setup_zsh() {
  step "Zsh + Oh My Zsh + Zinit"

  if ! command -v zsh &>/dev/null; then
    sudo apt install -y zsh
    ok "Zsh installed"
  else
    skip "Zsh already installed"
  fi

  if [[ ! -d ~/.oh-my-zsh ]]; then
    yes | sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || true
    ok "Oh My Zsh installed"
  else
    skip "Oh My Zsh already installed"
  fi

  if [[ ! -d ~/.local/share/zinit ]]; then
    yes | bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)" || true
    ok "Zinit installed"
  else
    skip "Zinit already installed"
  fi

  zshrc_append 'zinit light zdharma' '
### >>> ZINIT PLUGINS <<<
zinit light zdharma-continuum/fast-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions
### <<< ZINIT PLUGINS >>>'

  chsh -s "$(which zsh)" || true
  ok "Zsh set as default shell"
}

# ─── 5. Starship + Catppuccin ──────────────────────────────────────────────────
setup_starship() {
  step "Starship + Catppuccin"

  if ! command -v starship &>/dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    ok "Starship installed"
  else
    skip "Starship already installed"
  fi

  mkdir -p ~/.config
  curl -fsSL https://raw.githubusercontent.com/catppuccin/starship/refs/heads/main/starship.toml \
    -o ~/.config/starship.toml
  ok "Catppuccin starship.toml downloaded"

  curl -L https://raw.githubusercontent.com/catppuccin/gnome-terminal/v1.0.0/install.py \
    | python3 - 2>/dev/null || true
  ok "Catppuccin GNOME Terminal theme applied"

  zshrc_append 'starship init zsh' 'eval "$(starship init zsh)"'
}

# ─── 6. Fonts ──────────────────────────────────────────────────────────────────
setup_fonts() {
  step "Fonts (FiraCode Nerd Font + JetBrains Mono)"
  mkdir -p ~/.local/share/fonts

  if fc-list | grep -qi "FiraCode"; then
    skip "FiraCode Nerd Font already installed"
  else
    wget -q -O /tmp/firacode.zip \
      https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraCode.zip
    unzip -o /tmp/firacode.zip -d ~/.local/share/fonts/FiraCodeNerdFont
    rm /tmp/firacode.zip
    ok "FiraCode Nerd Font installed"
  fi

  if fc-list | grep -qi "JetBrains"; then
    skip "JetBrains Mono already installed"
  else
    wget -q -O /tmp/jetbrainsmono.zip \
      https://download.jetbrains.com/fonts/JetBrainsMono-2.304.zip
    unzip -o /tmp/jetbrainsmono.zip -d ~/.local/share/fonts/JetBrainsMono
    rm /tmp/jetbrainsmono.zip
    ok "JetBrains Mono installed"
  fi

  fc-cache -fv &>/dev/null
  ok "Font cache updated"
}

# ─── 7. nvm + Node ─────────────────────────────────────────────────────────────
setup_nvm_node() {
  step "nvm + Node 22"

  if [[ -d ~/.nvm ]]; then
    skip "nvm already installed"
  else
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
    ok "nvm installed"
  fi

  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

  if node --version &>/dev/null; then
    skip "Node $(node -v) already active"
  else
    nvm install 22
    nvm alias default 22
    ok "Node $(node -v) installed"
  fi

  zshrc_append 'NVM_DIR' '
### >>> NVM <<<
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
### <<< NVM >>>'

  for pkg in yarn bun pnpm @google/gemini-cli; do
    npm install -g "$pkg" --quiet 2>/dev/null || true
  done
  ok "Global npm packages: yarn bun pnpm gemini-cli"
}

# ─── 8. PHP ────────────────────────────────────────────────────────────────────
setup_php() {
  step "PHP 8.1 + 8.2 + Composer"

  # remove leftover ppa:ondrej/php from older runs (discontinued on newer Ubuntu releases)
  if ls /etc/apt/sources.list.d/*ondrej*php* &>/dev/null; then
    sudo rm -f /etc/apt/sources.list.d/*ondrej*php*
    warn "Removed leftover ppa:ondrej/php source"
  fi

  if [[ ! -f /etc/apt/sources.list.d/php.list ]]; then
    sudo apt install -y apt-transport-https lsb-release ca-certificates curl
    sudo mkdir -p /etc/apt/keyrings
    sudo curl -sSLo /etc/apt/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg
    echo "deb [signed-by=/etc/apt/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" \
      | sudo tee /etc/apt/sources.list.d/php.list > /dev/null
    ok "Sury PHP repository added"
  else
    skip "Sury PHP repository already added"
  fi
  sudo apt update

  local COMMON_EXTS="cli common mbstring opcache readline xml curl zip gd bcmath intl"

  for ver in 8.1 8.2; do
    if dpkg -l "php${ver}" &>/dev/null 2>&1; then
      skip "PHP ${ver} already installed"
    else
      local pkgs=""
      for ext in $COMMON_EXTS; do
        pkgs="$pkgs php${ver}-${ext}"
      done
      pkgs="$pkgs php${ver}-mysql"
      [[ "$ver" == "8.2" ]] && pkgs="$pkgs php${ver}-pgsql"
      # shellcheck disable=SC2086
      sudo apt install -y $pkgs
      ok "PHP ${ver} installed"
    fi
  done

  if command -v composer &>/dev/null; then
    skip "Composer already installed ($(composer --version --no-ansi 2>/dev/null | head -1))"
  else
    curl -sS https://getcomposer.org/installer | php
    sudo mv composer.phar /usr/local/bin/composer
    ok "Composer installed"
  fi
}

# ─── 9. Google Chrome ──────────────────────────────────────────────────────────
setup_chrome() {
  step "Google Chrome"
  if command -v google-chrome &>/dev/null; then
    skip "Google Chrome already installed"
    return
  fi
  wget -q -O /tmp/google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  sudo dpkg -i /tmp/google-chrome.deb 2>/dev/null || sudo apt -f install -y
  rm /tmp/google-chrome.deb
  ok "Google Chrome installed"
}

# ─── 10. Zed Editor ────────────────────────────────────────────────────────────
setup_zed() {
  step "Zed editor"
  if command -v zed &>/dev/null; then
    skip "Zed already installed"
    return
  fi
  curl -f https://zed.dev/install.sh | sh
  ok "Zed installed"
}

# ─── (old 9) GitHub CLI ────────────────────────────────────────────────────────
setup_github_cli() {
  step "GitHub CLI (official)"

  if command -v gh &>/dev/null && gh --version 2>/dev/null | grep -qv "2\.4\."; then
    skip "gh already installed ($(gh --version | head -1))"
    return
  fi

  sudo mkdir -p -m 755 /etc/apt/keyrings
  wget -nv -O /tmp/githubcli-keyring.gpg https://cli.github.com/packages/githubcli-archive-keyring.gpg
  cat /tmp/githubcli-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
  sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt update
  sudo apt install -y gh
  ok "GitHub CLI installed ($(gh --version | head -1))"
}

# ─── 10. Docker Desktop ────────────────────────────────────────────────────────
setup_docker() {
  step "Docker Desktop"

  if command -v docker &>/dev/null; then
    skip "Docker already installed ($(docker --version))"
    return
  fi

  sudo apt install -y gnome-terminal

  if [[ ! -f /etc/apt/sources.list.d/docker.list ]]; then
    sudo apt install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
      | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    ok "Docker CE repository added (provides docker-ce-cli for Docker Desktop)"
  else
    skip "Docker CE repository already added"
  fi

  wget -q --show-progress \
    https://desktop.docker.com/linux/main/amd64/docker-desktop-amd64.deb \
    -O /tmp/docker-desktop.deb
  sudo apt install -y /tmp/docker-desktop.deb
  rm /tmp/docker-desktop.deb
  systemctl --user enable docker-desktop 2>/dev/null || true
  ok "Docker Desktop installed"
}

# ─── 11. Kitty Terminal ────────────────────────────────────────────────────────
setup_kitty() {
  step "Kitty terminal"

  if [[ -f ~/.local/kitty.app/bin/kitty ]]; then
    skip "Kitty already installed"
  else
    curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
    ok "Kitty installed"
  fi

  mkdir -p ~/.config/kitty
  cp "$SCRIPT_DIR/configs/kitty/kitty.conf" ~/.config/kitty/kitty.conf
  ok "kitty.conf restored from repo"

  zshrc_append 'kitty.app/bin' 'export PATH="$HOME/.local/kitty.app/bin:$PATH"'

  # Register desktop launcher (kitty.app ships its .desktop files inside
  # ~/.local/kitty.app/share/applications, which desktop launchers don't scan)
  mkdir -p ~/.local/share/applications ~/.local/share/icons/hicolor/256x256/apps
  cp ~/.local/kitty.app/share/applications/kitty.desktop ~/.local/kitty.app/share/applications/kitty-open.desktop ~/.local/share/applications/
  cp ~/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png ~/.local/share/icons/hicolor/256x256/apps/
  sed -i "s|Icon=kitty|Icon=$HOME/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g; s|Exec=kitty|Exec=$HOME/.local/kitty.app/bin/kitty|g" ~/.local/share/applications/kitty*.desktop
  update-desktop-database ~/.local/share/applications 2>/dev/null || true
  ok "kitty desktop launcher registered"
}

# ─── 12. Neovim ────────────────────────────────────────────────────────────────
setup_neovim() {
  step "Neovim (henriquemattia/nvim)"

  if command -v nvim &>/dev/null && [[ -d ~/.config/nvim/.git ]]; then
    skip "Neovim already installed and configured"
    return
  fi

  local tmpdir
  tmpdir=$(mktemp -d)
  git clone git@github.com:henriquemattia/nvim.git "$tmpdir/nvim"
  bash "$tmpdir/nvim/install.sh"
  rm -rf "$tmpdir"
  ok "Neovim installed and configured"
}

# ─── 13. JetBrains Toolbox ─────────────────────────────────────────────────────
setup_jetbrains_toolbox() {
  step "JetBrains Toolbox"
  local toolbox_bin="$HOME/.local/share/JetBrains/Toolbox/bin/jetbrains-toolbox"

  if [[ -f "$toolbox_bin" ]]; then
    skip "JetBrains Toolbox already installed"
  else
    local url
    url=$(curl -s 'https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release' \
      | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['TBA'][0]['downloads']['linux']['link'])")

    wget -q --show-progress -O /tmp/jetbrains-toolbox.tar.gz "$url"
    local extracted
    extracted=$(basename "$url" .tar.gz)
    tar -xzf /tmp/jetbrains-toolbox.tar.gz -C /tmp/
    mkdir -p "$(dirname "$toolbox_bin")"
    # the archive now nests the binary (and its .so libs) under bin/, so copy the whole dir
    cp -r "/tmp/${extracted}/bin/." "$(dirname "$toolbox_bin")/"
    chmod +x "$toolbox_bin"
    rm -rf "/tmp/${extracted}" /tmp/jetbrains-toolbox.tar.gz
    ok "JetBrains Toolbox installed at $toolbox_bin"
  fi

  zshrc_append 'JetBrains/Toolbox/bin' \
    'export PATH="$HOME/.local/share/JetBrains/Toolbox/bin:$PATH"'

  warn "Open jetbrains-toolbox and install: WebStorm, PhpStorm, DataGrip"

  if [[ -n "$(ls -A "$SCRIPT_DIR/configs/jetbrains/" 2>/dev/null)" ]]; then
    warn "IDE configs found → import via File > Manage IDE Settings > Import Settings"
  fi
}

# ─── 14. Snap Packages ─────────────────────────────────────────────────────────
setup_snaps() {
  step "Snap packages"
  sudo apt install -y snapd

  declare -A SNAPS=(
    [code]="--classic"
    [android-studio]="--classic"
    [discord]=""
    [obsidian]="--classic"
    [slack]="--classic"
    [spotify]=""
    [teams-for-linux]=""
    [tailscale]=""
    [flutter]="--classic"
    [bitwarden]=""
    [postman]=""
    [emote]=""
  )

  for pkg in "${!SNAPS[@]}"; do
    if snap list "$pkg" &>/dev/null 2>&1; then
      skip "snap: $pkg already installed"
    else
      # shellcheck disable=SC2086
      sudo snap install "$pkg" ${SNAPS[$pkg]}
      ok "snap: $pkg installed"
    fi
  done
}

# ─── 15. Flatpak Packages ──────────────────────────────────────────────────────
setup_flatpaks() {
  step "Flatpak packages"
  sudo apt install -y flatpak gnome-software-plugin-flatpak
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

  declare -A FLATPAKS=(
    [app.zen_browser.zen]="Zen Browser"
    [com.obsproject.Studio]="OBS Studio"
    [com.usebruno.Bruno]="Bruno"
    [io.dbeaver.DBeaverCommunity]="DBeaver"
    [org.flameshot.Flameshot]="Flameshot"
    [com.rtosta.zapzap]="ZapZap"
    [com.stremio.Stremio]="Stremio"
    [org.onlyoffice.desktopeditors]="OnlyOffice"
  )

  local installed
  installed=$(flatpak list --columns=application 2>/dev/null)

  for app_id in "${!FLATPAKS[@]}"; do
    if echo "$installed" | grep -q "^${app_id}$"; then
      skip "flatpak: ${FLATPAKS[$app_id]} already installed"
    else
      flatpak install flathub -y --noninteractive "$app_id"
      ok "flatpak: ${FLATPAKS[$app_id]} installed"
    fi
  done

  # flatpak exports its .desktop files under /var/lib/flatpak/exports/share, which
  # is only added to XDG_DATA_DIRS by a fresh login shell — export it here so
  # xdg-settings can find Zen Browser's desktop entry in this same script run
  export XDG_DATA_DIRS="/var/lib/flatpak/exports/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
  xdg-settings set default-web-browser app.zen_browser.zen.desktop
  ok "Zen Browser set as default web browser"
}

# ─── 16. Teleport Connect ──────────────────────────────────────────────────────
setup_teleport() {
  step "Teleport Connect"

  if command -v teleport &>/dev/null; then
    skip "Teleport already installed ($(teleport version 2>/dev/null | head -1))"
    return
  fi

  local teleport_version
  teleport_version=$(curl -s https://api.github.com/repos/gravitational/teleport/releases/latest \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'].lstrip('v'))")
  curl https://goteleport.com/static/install-connect.sh | bash -s "$teleport_version"
  ok "Teleport Connect installed"
}

# ─── 17. GNOME Extensions ──────────────────────────────────────────────────────
setup_gnome_extensions() {
  step "GNOME extensions"

  if [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" ]]; then
    warn "No display detected — skipping GNOME extensions (run again from a desktop session)"
    return
  fi

  # touchegg — required for x11gestures extension
  # installed from upstream GitHub releases: the ppa:touchegg/stable PPA has not
  # published binaries for newer Ubuntu releases yet
  if ! command -v touchegg &>/dev/null; then
    local touchegg_url
    touchegg_url=$(curl -s https://api.github.com/repos/JoseExposito/touchegg/releases/latest \
      | python3 -c "import sys,json; d=json.load(sys.stdin); print([a['browser_download_url'] for a in d['assets'] if a['name'].endswith('_amd64.deb')][0])")
    wget -q -O /tmp/touchegg.deb "$touchegg_url"
    sudo apt install -y /tmp/touchegg.deb
    rm -f /tmp/touchegg.deb
    ok "touchegg installed (required for x11gestures)"
  else
    skip "touchegg already installed"
  fi

  pip3 install gnome-extensions-cli --break-system-packages --quiet 2>/dev/null || true

  local EXTENSIONS=(
    "blur-my-shell@aunetx"
    "clipboard-indicator@tudmotu.com"
    "dash-to-dock@micxgx.gmail.com"
    "gnome-ui-tune@itstime.tech"
    "just-perfection-desktop@just-perfection"
    "pip-on-top@rafostar.github.com"
    "pomodoro@arun.codito.in"
    "runcat@kolesnikov.se"
    "sensory-perception@HarlemSquirrel.github.io"
    "sound-output-device-chooser@kgshank.net"
    "ssm-gnome@lgiki.net"
    "transparent-window-moving@noobsai.github.com"
    "workspace_scroll@squgeim.com.np"
    "x11gestures@joseexposito.github.io"
    "bluetooth-quick-connect@bjarosze.gmail.com"
  )

  for ext in "${EXTENSIONS[@]}"; do
    if gnome-extensions list 2>/dev/null | grep -q "^${ext}$"; then
      skip "extension: $ext"
    else
      gext install "$ext" 2>/dev/null && ok "extension: $ext" || warn "Failed: $ext"
    fi
  done
}

# ─── 18. Android / React Native ────────────────────────────────────────────────
setup_android() {
  step "Android / React Native"
  sudo apt install -y watchman qemu-system-x86 qemu-utils libvirt-daemon-system libvirt-clients bridge-utils
  sudo usermod -aG kvm "$USER" || true

  zshrc_append 'ANDROID_HOME' '
### >>> ANDROID <<<
export ANDROID_HOME=$HOME/Android/Sdk
export JAVA_HOME=/snap/android-studio/current/jbr
export PATH=$PATH:$ANDROID_HOME/emulator:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$JAVA_HOME/bin
### <<< ANDROID >>>'

  ok "Android environment configured"
}

# ─── 19. pnpm PATH ─────────────────────────────────────────────────────────────
setup_pnpm_path() {
  zshrc_append 'PNPM_HOME' '
### >>> PNPM <<<
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
### <<< PNPM >>>'
}

# ─── 20. zoxide ────────────────────────────────────────────────────────────────
setup_zoxide() {
  step "zoxide"
  zshrc_append 'zoxide init zsh' '
### >>> ZOXIDE <<<
unalias zi 2>/dev/null
eval "$(zoxide init zsh)"
### <<< ZOXIDE >>>'
  ok "zoxide configured"
}

# ─── 21. direnv ────────────────────────────────────────────────────────────────
setup_direnv() {
  step "direnv"
  zshrc_append 'direnv hook zsh' 'eval "$(direnv hook zsh)"'
  ok "direnv configured"
}

# ─── 22. Aliases & Functions ───────────────────────────────────────────────────
setup_aliases() {
  step "Aliases & functions"

  grep -q 'alias dcu' ~/.zshrc 2>/dev/null && { skip "Aliases already in ~/.zshrc"; return; }

  cat >> ~/.zshrc << 'ALIASES'

### >>> ALIASES & FUNCTIONS <<<

# Docker
alias dcu="docker compose up -d"
alias dcub="docker compose up -d --build"
alias dcs="docker compose stop"
alias dcd="docker compose down"
alias dps="docker ps"

# Laravel Sail
alias sail='sh $([ -f sail ] && echo sail || echo vendor/bin/sail)'
alias slu='sh $([ -f sail ] && echo sail || echo vendor/bin/sail) up -d'
alias sls='sh $([ -f sail ] && echo sail || echo vendor/bin/sail) stop'
alias sla='sh $([ -f sail ] && echo sail || echo vendor/bin/sail) php artisan'
alias slat='sh $([ -f sail ] && echo sail || echo vendor/bin/sail) php artisan test'
alias slatp='sh $([ -f sail ] && echo sail || echo vendor/bin/sail) php artisan test -p'

# Git
alias ggmain='git checkout main && git pull origin main && clear'

# React Native
alias rn-clean='rm -rf android/app/build android/.gradle android/build'
alias rn-hard-reset='rm -rf android/app/build android/.gradle android/build node_modules'
alias rn-build='yarn && yarn android && yarn start --reset-cache'

# Utils
alias update='sudo apt-get update && sudo apt-get upgrade -y'
alias zshrc='code ~/.zshrc'
alias aliaslist='grep "^alias" ~/.zshrc | cut -d "=" -f 1 | cut -d " " -f 2'
alias node_modules_remove='find . -name "node_modules" -type d -prune -exec rm -rf {} +'

# killport — kills local process AND stops Docker containers on that port
killport() {
  local port="$1"
  if [[ -z "$port" ]]; then
    echo "uso: killport <porta>"
    return 1
  fi
  local killed=0
  local pids
  pids=$(lsof -ti :"$port" 2>/dev/null)
  if [[ -n "$pids" ]]; then
    local names
    names=$(lsof -ti :"$port" -sTCP:LISTEN 2>/dev/null | xargs -I{} ps -p {} -o comm= 2>/dev/null | tr '\n' ' ')
    echo "$pids" | xargs kill -9 2>/dev/null
    echo "✓ processos mortos na porta $port: ${names:-$pids}"
    killed=1
  fi
  local containers
  containers=$(docker ps --format '{{.Names}}\t{{.Ports}}' 2>/dev/null | grep ":${port}->" | awk '{print $1}')
  if [[ -n "$containers" ]]; then
    while IFS= read -r container; do
      docker stop "$container" >/dev/null 2>&1
      echo "✓ container Docker parado: $container (porta $port)"
      killed=1
    done <<< "$containers"
  fi
  if [[ $killed -eq 0 ]]; then
    echo "✗ nada encontrado na porta $port"
  fi
}

# aprint — Android screenshot via adb, saves to ~/images and copies to clipboard
# Usage: aprint          -> uses physical device (or only connected one)
#        aprint <serial> -> uses specific device (see: adb devices)
aprint() {
  local dir="$HOME/images"
  mkdir -p "$dir"
  local serial="${1:-}"
  if [[ -z "$serial" ]]; then
    local devices
    devices=$(adb devices | awk 'NR>1 && $2=="device" {print $1}')
    serial=$(echo "$devices" | grep -v '^emulator-' | head -1)
    [[ -z "$serial" ]] && serial=$(echo "$devices" | head -1)
  fi
  if [[ -z "$serial" ]]; then
    echo "✗ nenhum device conectado (rode: adb devices)"
    return 1
  fi
  local file="$dir/screen_$(date +%Y%m%d-%H%M%S).png"
  if adb -s "$serial" exec-out screencap -p > "$file" 2>/dev/null && [[ -s "$file" ]]; then
    if command -v xclip >/dev/null; then
      xclip -selection clipboard -t image/png -i "$file"
      echo "✓ print salva e copiada p/ clipboard: $file ($serial)"
    else
      echo "✓ print salva: $file ($serial)  [xclip ausente, sem clipboard]"
    fi
  else
    echo "✗ falha ao capturar de $serial"
    rm -f "$file"
    return 1
  fi
}

### <<< ALIASES & FUNCTIONS <<<
ALIASES

  ok "Aliases and functions added to ~/.zshrc"
}

# ─── 23. inotify ───────────────────────────────────────────────────────────────
setup_inotify() {
  step "inotify limits (permanent)"
  sudo tee /etc/sysctl.d/99-inotify.conf > /dev/null << 'EOF'
fs.inotify.max_user_watches=524288
fs.inotify.max_user_instances=8192
fs.inotify.max_queued_events=65536
EOF
  sudo sysctl --system &>/dev/null
  ok "inotify limits set"
}

# ─── 24. Swap ──────────────────────────────────────────────────────────────────
setup_swap() {
  if [[ "${SWAP_GB:-0}" -le 0 ]]; then
    skip "Swap: skipped"
    return
  fi

  step "Swap (${SWAP_GB}G)"
  sudo swapoff /swapfile 2>/dev/null || true
  sudo fallocate -l "${SWAP_GB}G" /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  sudo sed -i '/\/swapfile/d' /etc/fstab
  echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
  free -h
  ok "Swap configured: ${SWAP_GB}G"
}

# ─── 25. Ç Fix ─────────────────────────────────────────────────────────────────
setup_c_cedilla() {
  step "Ç keyboard fix"
  if [[ -f ~/.XCompose ]]; then
    skip "~/.XCompose already exists"
    return
  fi
  cat > ~/.XCompose << 'EOF'
include "%S/en_US.UTF-8/Compose"
<dead_acute> <C> : "Ç"
<dead_acute> <c> : "ç"
EOF
  ok "~/.XCompose written (logout/login to apply)"
}

# ─── 26. Verification Summary ──────────────────────────────────────────────────
verify() {
  echo ""
  echo -e "\033[1;35m  ╔══════════════════════════════════════════════╗"
  echo    "  ║               Verification                  ║"
  echo -e "  ╚══════════════════════════════════════════════╝\033[0m"
  echo ""

  check() {
    local label="$1"; shift
    local version
    version=$("$@" 2>/dev/null | head -1) && \
      printf "  \033[0;32m✓\033[0m  %-16s %s\n" "$label" "$version" || \
      printf "  \033[0;31m✗\033[0m  %-16s not found\n" "$label"
  }

  check "zsh"      zsh --version
  check "git"      git --version
  check "node"     node --version
  check "php"      php --version
  check "composer" composer --version --no-ansi
  check "docker"   docker --version
  check "kitty"    kitty --version
  check "nvim"     nvim --version
  check "gh"       gh --version

  echo ""
  echo -e "\033[1;33m  Manual steps remaining:\033[0m"
  echo "  1. Add SSH key to GitHub → https://github.com/settings/keys"
  echo "  2. Run 'jetbrains-toolbox' → install WebStorm, PhpStorm, DataGrip"
  echo "  3. Export IDE settings from old machine → drop zip in configs/jetbrains/ → import"
  echo "  4. Restart shell: exec zsh"
  echo ""
}

# ─── Main ──────────────────────────────────────────────────────────────────────
main() {
  banner
  collect_prompts

  setup_system
  setup_git
  setup_ssh
  setup_zsh
  setup_starship
  setup_fonts
  setup_nvm_node
  setup_php
  setup_chrome
  setup_zed
  setup_github_cli
  setup_docker
  setup_kitty
  setup_neovim
  setup_jetbrains_toolbox
  setup_snaps
  setup_flatpaks
  setup_teleport
  setup_gnome_extensions
  setup_android
  setup_pnpm_path
  setup_zoxide
  setup_direnv
  setup_aliases
  setup_inotify
  setup_swap
  setup_c_cedilla
  verify
}

main "$@"
