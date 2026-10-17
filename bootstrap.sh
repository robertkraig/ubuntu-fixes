#!/bin/bash
# bootstrap.sh — Fresh Ubuntu setup for Dell Precision 7560
# Installs repos, packages, and tools in one shot.
# Safe to re-run: checks before installing.
#
# Usage: sudo ./bootstrap.sh
set -e

UBUNTU_CODENAME=$(lsb_release -cs)
USER_HOME=$(eval echo ~${SUDO_USER:-$USER})
ACTUAL_USER=${SUDO_USER:-$USER}

info()    { echo -e "\e[34m==>\e[0m $*"; }
success() { echo -e "\e[32m ✓\e[0m $*"; }
warn()    { echo -e "\e[33m  !\e[0m $*"; }

require_root() {
    [ "$EUID" -eq 0 ] || { echo "Run with sudo."; exit 1; }
}

pkg_installed() { dpkg -l "$1" 2>/dev/null | grep -q "^ii"; }

apt_install() {
    local missing=()
    for pkg in "$@"; do
        pkg_installed "$pkg" || missing+=("$pkg")
    done
    [ ${#missing[@]} -eq 0 ] && return 0
    apt-get install -y "${missing[@]}"
}

require_root

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq

# ─── Repos ────────────────────────────────────────────────────────────────────

info "Setting up repositories..."

# Google Chrome
if [ ! -f /etc/apt/sources.list.d/google.sources ] && [ ! -f /etc/apt/sources.list.d/google-chrome.list ]; then
    curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
        > /etc/apt/sources.list.d/google-chrome.list
    success "Google Chrome repo"
fi

# Spotify
if [ ! -f /etc/apt/sources.list.d/spotify.sources ] && [ ! -f /etc/apt/sources.list.d/spotify.list ]; then
    curl -fsSL https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg | gpg --dearmor -o /usr/share/keyrings/spotify.gpg
    echo "deb [signed-by=/usr/share/keyrings/spotify.gpg] http://repository.spotify.com stable non-free" \
        > /etc/apt/sources.list.d/spotify.list
    success "Spotify repo"
fi

# Docker
if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $UBUNTU_CODENAME stable" \
        > /etc/apt/sources.list.d/docker.list
    success "Docker repo"
fi

# NodeSource (Node.js LTS)
if [ ! -f /etc/apt/sources.list.d/nodesource.list ]; then
    curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
    success "NodeSource repo"
fi

# TLP (linrunner PPA)
if ! apt-cache policy | grep -q linrunner; then
    add-apt-repository -y ppa:linrunner/tlp
    success "TLP linrunner PPA"
fi

# GitHub CLI
if [ ! -f /etc/apt/sources.list.d/github-cli.list ]; then
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | gpg --dearmor -o /usr/share/keyrings/githubcli.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/githubcli.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list
    success "GitHub CLI repo"
fi

# VS Code
if [ ! -f /etc/apt/sources.list.d/vscode.list ] && [ ! -f /etc/apt/sources.list.d/vscode.sources ]; then
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
        > /etc/apt/sources.list.d/vscode.list
    success "VS Code repo"
fi

# Sublime Text
if [ ! -f /etc/apt/sources.list.d/sublime-text.list ] && [ ! -f /etc/apt/sources.list.d/sublime-text.sources ]; then
    curl -fsSL https://download.sublimetext.com/sublimehq-pub.gpg | gpg --dearmor -o /usr/share/keyrings/sublimehq.gpg
    echo "deb [signed-by=/usr/share/keyrings/sublimehq.gpg] https://download.sublimetext.com/ apt/stable/" \
        > /etc/apt/sources.list.d/sublime-text.list
    success "Sublime Text repo"
fi

# Signal
if [ ! -f /etc/apt/sources.list.d/signal.list ]; then
    curl -fsSL https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor -o /usr/share/keyrings/signal.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/signal.gpg] https://updates.signal.org/desktop/apt xenial main" \
        > /etc/apt/sources.list.d/signal.list
    success "Signal repo"
fi

# HashiCorp (Terraform)
if [ ! -f /etc/apt/sources.list.d/hashicorp.list ]; then
    curl -fsSL https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp.gpg] https://apt.releases.hashicorp.com $UBUNTU_CODENAME main" \
        > /etc/apt/sources.list.d/hashicorp.list
    success "HashiCorp repo"
fi

# Solaar (Logitech)
if ! apt-cache policy | grep -q solaar-unifying; then
    add-apt-repository -y ppa:solaar-unifying/stable
    success "Solaar PPA"
fi

apt-get update -qq

# ─── System & Power Management ────────────────────────────────────────────────

info "Installing system & power management packages..."
apt_install \
    tlp tlp-rdw tlp-pd \
    thermald powertop \
    lm-sensors fancontrol \
    i8kutils \
    nvidia-prime plasma-optimus \
    linux-generic

# ─── Core Utilities ───────────────────────────────────────────────────────────

info "Installing core utilities..."
apt_install \
    curl wget gpg ca-certificates apt-transport-https \
    software-properties-common \
    build-essential cmake make autoconf pkg-config \
    git git-delta \
    jq yq \
    pv gum zenity \
    net-tools \
    unzip xz-utils gzip \
    flatpak \
    gdebi

# ─── Terminal & Shell Tools ───────────────────────────────────────────────────

info "Installing terminal & shell tools..."
apt_install \
    zsh tmux screen \
    foot foot-themes \
    bat fd-find ripgrep \
    eza lsd \
    delta glow sd duf gping ack \
    zoxide fzf \
    htop glances inxi psensor \
    vim

# ─── Developer Tools ──────────────────────────────────────────────────────────

info "Installing developer tools..."
apt_install \
    gh \
    code \
    sublime-text sublime-merge \
    docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin \
    terraform \
    nodejs \
    python3 python3-pip python3-venv pipx \
    default-jdk openjdk-21-jdk \
    ruby-dev \
    cargo \
    maven sbt \
    ngrok

# ─── Languages & Build Deps ───────────────────────────────────────────────────

info "Installing language support & build dependencies..."
apt_install \
    libbz2-dev libffi-dev liblzma-dev libncurses-dev \
    libreadline-dev libsqlite3-dev libssl-dev \
    libxml2-dev libxml2-utils libyaml-dev \
    tk-dev llvm

# PHP
apt_install \
    php php-cli php-common php-curl php-gd \
    php-json php-mbstring php-xml php-zip php-bcmath

# ─── Media ────────────────────────────────────────────────────────────────────

info "Installing media packages..."
apt_install \
    vlc mpv audacious \
    spotify-client \
    easyeffects calf-plugins

# ─── Communication ────────────────────────────────────────────────────────────

info "Installing communication apps..."
apt_install \
    signal-desktop

# Zoom (deb download)
if ! pkg_installed zoom; then
    info "Installing Zoom..."
    curl -fsSL "https://zoom.us/client/latest/zoom_amd64.deb" -o /tmp/zoom.deb
    apt-get install -y /tmp/zoom.deb
    rm /tmp/zoom.deb
    success "Zoom"
fi

# ─── Browsers ─────────────────────────────────────────────────────────────────

info "Installing browsers..."
apt_install google-chrome-stable firefox

# ─── Desktop & Productivity ───────────────────────────────────────────────────

info "Installing desktop & productivity tools..."
apt_install \
    flameshot \
    gparted \
    dropbox \
    solaar logiops \
    libimage-exiftool-perl \
    sane sane-utils simple-scan \
    img2pdf pdfarranger pdfsam pdftk-java ghostscript \
    leapp

# ─── Neovim ───────────────────────────────────────────────────────────────────

info "Installing Neovim (latest stable)..."
NVIM_DIR="/opt/nvim"
if [ ! -f "$NVIM_DIR/bin/nvim" ]; then
    NVIM_URL=$(curl -fsSL https://api.github.com/repos/neovim/neovim/releases/latest \
        | grep "browser_download_url.*nvim-linux-x86_64.tar.gz" \
        | cut -d '"' -f 4)
    curl -fsSL "$NVIM_URL" -o /tmp/nvim.tar.gz
    mkdir -p "$NVIM_DIR"
    tar -xzf /tmp/nvim.tar.gz -C "$NVIM_DIR" --strip-components=1
    rm /tmp/nvim.tar.gz
    success "Neovim installed to $NVIM_DIR"
    warn "Add to PATH: export PATH=\"\$PATH:/opt/nvim/bin\""
else
    success "Neovim already installed"
fi

# ─── herdr ────────────────────────────────────────────────────────────────────

info "Installing herdr..."
HERDR_BIN="$USER_HOME/.local/bin/herdr"
if [ ! -f "$HERDR_BIN" ]; then
    HERDR_URL=$(curl -fsSL https://api.github.com/repos/herdr-io/herdr/releases/latest \
        | grep "browser_download_url.*linux.*x86_64" \
        | grep -v ".sha\|.asc" \
        | cut -d '"' -f 4 | head -1)
    if [ -n "$HERDR_URL" ]; then
        mkdir -p "$USER_HOME/.local/bin"
        curl -fsSL "$HERDR_URL" -o "$HERDR_BIN"
        chmod +x "$HERDR_BIN"
        chown "$ACTUAL_USER:$ACTUAL_USER" "$HERDR_BIN"
        success "herdr installed to $HERDR_BIN"
    else
        warn "Could not find herdr release URL — install manually from herdr.io"
    fi
else
    success "herdr already installed"
fi

# ─── npm globals ──────────────────────────────────────────────────────────────

info "Installing npm global packages..."
# Run as actual user, not root
sudo -u "$ACTUAL_USER" bash -c "
    npm install -g @anthropic-ai/claude-code
"
success "Claude Code CLI installed"

# ─── Post-install ─────────────────────────────────────────────────────────────

info "Disabling Docker autostart (use docker-start alias to start when needed)..."
systemctl disable docker docker.socket containerd 2>/dev/null || true

info "Enabling TLP..."
systemctl enable tlp tlp-pd
systemctl start tlp tlp-pd 2>/dev/null || true

echo ""
echo -e "\e[32m Bootstrap complete!\e[0m"
echo ""
echo "  Next steps:"
echo "  1. Reboot"
echo "  2. Run fixes in ./fixes/ — start with acpi-gpe6e and tlp-battery"
echo "  3. Set up Neovim lazy.nvim: https://lazy.nvim.dev"
echo "  4. Configure herdr: herdr --setup"
echo "  5. Log into Chrome, Spotify, Dropbox, Signal, Zoom"
echo ""
