#!/usr/bin/env bash

#  ██╗  ██╗ █████╗ ██████╗ ███╗   ███╗██╗ ██████╗         ██╗██╗   ██╗     ██╗██╗   ██╗
#  ██║ ██╔╝██╔══██╗██╔══██╗████╗ ████║██║██╔════╝         ██║██║   ██║     ██║██║   ██║
#  █████╔╝ ███████║██████╔╝██╔████╔██║██║██║              ██║██║   ██║     ██║██║   ██║
#  ██╔═██╗ ██╔══██║██╔══██╗██║╚██╔╝██║██║██║         ██   ██║██║   ██║██   ██║██║   ██║
#  ██║  ██╗██║  ██║██║  ██║██║ ╚═╝ ██║██║╚██████╗    ╚█████╔╝╚██████╔╝╚█████╔╝╚██████╔╝
#  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝ ╚═════╝     ╚════╝  ╚═════╝  ╚════╝  ╚═════╝
#
#  ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░
#  ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░
#
#  System Initialization Script - From Zero to Hero
#  Supports: Arch Linux, Debian, Ubuntu, macOS
#
#  ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░
#  ░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
DOTFILES_REPO="https://github.com/karmicjuju/dotfiles.git" # UPDATE THIS
DOTFILES_DIR="$HOME/dotfiles"

# Logging functions
log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to detect the operating system
detect_os() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "macos"
  elif [ -f /etc/arch-release ]; then
    echo "arch"
  elif [ -f /etc/debian_version ]; then
    if grep -q "Ubuntu" /etc/os-release 2>/dev/null; then
      echo "ubuntu"
    else
      echo "debian"
    fi
  else
    log_error "Unsupported operating system"
    exit 1
  fi
}

# Function to install packages for Arch Linux
install_arch() {
  log_info "Setting up Arch Linux..."

  # Update system
  log_info "Updating system packages..."
  sudo pacman -Syu --noconfirm

  log_info "Installing base-devel and git for paru installation..."
    sudo pacman -S --needed --noconfirm base-devel git
    
    # Install paru if not present
    if ! command -v paru &> /dev/null; then
        log_info "Installing paru..."
        temp_dir=$(mktemp -d)
        cd "$temp_dir"
        git clone https://aur.archlinux.org/paru.git
        cd paru
        makepkg -si --noconfirm
        cd "$HOME"
        rm -rf "$temp_dir"
    fi
    
    # Install all packages with paru (handles both official and AUR)
    log_info "Installing all packages with paru..."
    paru -S --needed --noconfirm \
        curl \
        wget \
        zsh \
        python \
        fzf \
        gnu-netcat \
        bind \
        starship \
        neovim-nightly-bin \
        zoxide-bin \
        eza-bin

  # Install uv
  install_uv
}

# Function to install packages for Debian
install_debian() {
  log_info "Setting up Debian..."

  # Update system
  log_info "Updating system packages..."
  sudo apt update && sudo apt upgrade -y

  # Install dependencies and base packages
  log_info "Installing base packages..."
  sudo apt install -y \
    build-essential \
    git \
    curl \
    wget \
    zsh \
    python3 \
    python3-pip \
    python3-venv \
    fzf \
    netcat-openbsd \
    dnsutils \
    software-properties-common \
    ca-certificates \
    gnupg \
    lsb-release

  # Install Starship
  install_starship

  # Install Neovim (latest stable via AppImage or build from source)
  install_neovim_debian

  # Install eza
  install_eza_debian

  # Install zoxide
  install_zoxide_debian

  # Install uv
  install_uv
}

# Function to install packages for Ubuntu
install_ubuntu() {
  log_info "Setting up Ubuntu..."

  # Update system
  log_info "Updating system packages..."
  sudo apt update && sudo apt upgrade -y

  # Install dependencies and base packages
  log_info "Installing base packages..."
  sudo apt install -y \
    build-essential \
    git \
    curl \
    wget \
    zsh \
    python3 \
    python3-pip \
    python3-venv \
    fzf \
    netcat-openbsd \
    dnsutils \
    software-properties-common \
    ca-certificates \
    gnupg \
    lsb-release

  # Add Neovim PPA for latest version
  log_info "Installing Neovim..."
  sudo add-apt-repository ppa:neovim-ppa/unstable -y
  sudo apt update
  sudo apt install -y neovim

  # Install eza
  install_eza_debian

  # Install zoxide
  install_zoxide_debian

  # Install uv
  install_uv
}

# Function to install packages for macOS
install_macos() {
  log_info "Setting up macOS..."

  # Install Homebrew if not present
  if ! command -v brew &>/dev/null; then
    log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for Apple Silicon
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
  fi

  # Update Homebrew
  log_info "Updating Homebrew..."
  brew update

  # Install packages
  log_info "Installing packages with Homebrew..."
  brew install \
    git \
    curl \
    zsh \
    neovim \
    zoxide \
    eza \
    fzf \
    python@3.12 \
    netcat \
    bind \
    starship

  # Install uv
  install_uv
}

# Function to install Starship prompt
install_starship() {
  log_info "Installing Starship prompt..."

  if command -v starship &>/dev/null; then
    log_info "Starship is already installed"
  else
    curl -sS https://starship.rs/install.sh | sh -s -- -y
  fi
}
# Function to install Neovim for Debian (using AppImage for latest version)
# Install Neovim for Debian (using AppImage for latest version)
install_neovim_debian() {
  log_info "Installing Neovim (latest)..."

  # Download and install Neovim AppImage
  curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
  chmod u+x nvim.appimage

  # Extract AppImage if FUSE is not available
  if ! ./nvim.appimage --version &>/dev/null; then
    ./nvim.appimage --appimage-extract
    sudo mv squashfs-root /opt/nvim
    sudo ln -sf /opt/nvim/AppRun /usr/local/bin/nvim
    rm -rf nvim.appimage squashfs-root
  else
    sudo mv nvim.appimage /usr/local/bin/nvim
  fi
}

# Function to install eza for Debian/Ubuntu
install_eza_debian() {
  log_info "Installing eza..."

  # Install eza via cargo or download binary
  if command -v cargo &>/dev/null; then
    cargo install eza
  else
    # Download pre-built binary
    local eza_version=$(curl -s https://api.github.com/repos/eza-community/eza/releases/latest | grep -Po '"tag_name": "\K[^"]*')
    local arch=$(dpkg --print-architecture)

    if [[ "$arch" == "amd64" ]]; then
      arch="x86_64"
    elif [[ "$arch" == "arm64" ]]; then
      arch="aarch64"
    fi

    wget -O eza.tar.gz "https://github.com/eza-community/eza/releases/download/${eza_version}/eza_${arch}-unknown-linux-gnu.tar.gz"
    tar -xzf eza.tar.gz
    sudo mv eza /usr/local/bin/
    rm eza.tar.gz
  fi
}

# Function to install zoxide for Debian/Ubuntu
install_zoxide_debian() {
  log_info "Installing zoxide..."

  curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
}

# Function to install uv (Python package manager)
install_uv() {
  log_info "Installing uv..."

  if command -v uv &>/dev/null; then
    log_info "uv is already installed"
  else
    curl -LsSf https://astral.sh/uv/install.sh | sh

    # Add to current session PATH
    export PATH="$HOME/.cargo/bin:$PATH"
  fi
}

# Function to clone and set up dotfiles repository
setup_dotfiles() {
  log_info "Setting up dotfiles..."

  if [ -d "$DOTFILES_DIR" ]; then
    log_warning "Dotfiles directory already exists. Pulling latest changes..."
    cd "$DOTFILES_DIR"
    git pull
  else
    log_info "Cloning dotfiles repository..."
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
  fi

  # Link dotfiles (customize this based on your dotfiles structure)
  log_info "Linking dotfiles..."
  cd "$DOTFILES_DIR"

  # Symlink common dotfiles
  # Zsh config
  if [ -f "$DOTFILES_DIR/zsh/.zshrc" ]; then
    ln -sf "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
    log_info "Linked .zshrc"
  fi

  # Starship config
  if [ -f "$DOTFILES_DIR/starship/starship.toml" ]; then
    ln -sf "$DOTFILES_DIR/starship/starship.toml" "$HOME/.config/starship.toml"
    log_info "Linked starship.toml"
  fi

  # Example linking commands - adjust based on your dotfiles structure
  # ln -sf "$DOTFILES_DIR/.config/nvim" "$HOME/.config/"
  # Add more symlinks as needed

  log_warning "Please manually link any remaining dotfiles or run your dotfiles install script"
}

# Function to configure the default shell and its settings
configure_shell() {
  log_info "Configuring shell..."

  # Set zsh as default shell if not already
  if [ "$SHELL" != "$(which zsh)" ]; then
    log_info "Setting zsh as default shell..."
    chsh -s "$(which zsh)"
    log_warning "Shell changed to zsh. Please logout and login for changes to take effect."
  fi

  # Check if .zshrc exists or is already symlinked from dotfiles
  if [ ! -e "$HOME/.zshrc" ]; then
    # Only create a basic .zshrc if the dotfiles version doesn't exist
    if [ ! -f "$DOTFILES_DIR/zsh/.zshrc" ]; then
      log_info "Creating basic .zshrc (no dotfiles version found)..."
      cat >"$HOME/.zshrc" <<'EOF'
# Initialize Starship prompt
eval "$(starship init zsh)"

# Initialize zoxide
eval "$(zoxide init zsh)"

# FZF key bindings
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# User configuration
# Add your custom configuration here
EOF
    else
      log_info ".zshrc will be linked from dotfiles"
    fi
  else
    # Check if we need to add Starship init (only if not using dotfiles version)
    if [ ! -L "$HOME/.zshrc" ] && [ -f "$HOME/.zshrc" ]; then
      if ! grep -q "eval \"\$(starship init zsh)\"" "$HOME/.zshrc"; then
        log_info "Adding Starship to existing .zshrc..."
        echo '' >>"$HOME/.zshrc"
        echo '# Initialize Starship prompt' >>"$HOME/.zshrc"
        echo 'eval "$(starship init zsh)"' >>"$HOME/.zshrc"
      fi
    fi
  fi

  # Create config directory for Starship
  mkdir -p "$HOME/.config"

  # Symlink Starship config from dotfiles (backup check)
  if [ -f "$DOTFILES_DIR/starship/starship.toml" ] && [ ! -L "$HOME/.config/starship.toml" ]; then
    log_info "Linking Starship configuration from dotfiles..."
    ln -sf "$DOTFILES_DIR/starship/starship.toml" "$HOME/.config/starship.toml"
  fi
}

# Function for post-installation setup tasks
post_install() {
  log_info "Running post-installation setup..."

  # Initialize zoxide
  if command -v zoxide &>/dev/null; then
    log_info "Initializing zoxide..."
    eval "$(zoxide init zsh)"
  fi

  # Install fzf key bindings and fuzzy completion
  if command -v fzf &>/dev/null; then
    log_info "Setting up fzf..."
    if [ -f /usr/share/fzf/key-bindings.zsh ]; then
      source /usr/share/fzf/key-bindings.zsh
    elif [ -f "$HOME/.fzf.zsh" ]; then
      source "$HOME/.fzf.zsh"
    fi
  fi

  # Create common directories
  mkdir -p "$HOME/.config"
  mkdir -p "$HOME/.local/bin"
  mkdir -p "$HOME/projects"

  log_info "Post-installation setup complete!"
}

# Main execution function
main() {
  log_info "Starting system initialization..."

  # Detect OS
  OS=$(detect_os)
  log_info "Detected OS: $OS"

  # Check if running with proper permissions
  if [ "$OS" != "macos" ] && [ "$EUID" -eq 0 ]; then
    log_error "Please do not run this script as root"
    exit 1
  fi

  # Install packages based on OS
  case "$OS" in
  arch)
    install_arch
    ;;
  debian)
    install_debian
    ;;
  ubuntu)
    install_ubuntu
    ;;
  macos)
    install_macos
    ;;
  *)
    log_error "Unsupported OS: $OS"
    exit 1
    ;;
  esac

  # Common setup tasks
  setup_dotfiles
  configure_shell
  post_install

  log_info "================================"
  log_info "System initialization complete!"
  log_info "================================"
  log_info ""
  log_info "Next steps:"
  log_info "1. Link your dotfiles manually or run your dotfiles install script"
  log_info "2. Restart your terminal or logout/login for shell changes"
  log_info "3. Configure Neovim with your plugins and settings"
  log_info ""
  log_info "Installed tools:"
  log_info "  - zsh (default shell)"
  log_info "  - starship (prompt)"
  log_info "  - nvim (latest version)"
  log_info "  - zoxide (z command for directory jumping)"
  log_info "  - eza (modern ls replacement)"
  log_info "  - fzf (fuzzy finder)"
  log_info "  - git"
  log_info "  - python3 (latest)"
  log_info "  - uv (fast Python package manager)"
  log_info "  - curl"
  log_info "  - nc (netcat)"
  log_info "  - dig (DNS lookup)"
}

# Run main function
main "$@"
