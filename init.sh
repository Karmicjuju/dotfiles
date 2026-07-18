#!/usr/bin/env bash
# Bootstrap: install packages, then link dotfiles with GNU Stow.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR"
mkdir -p "$HOME/.config"
echo "$DOTFILES_DIR" > "$HOME/.config/dotfiles-dir"

PACKAGES=(zsh bash git starship nvim wezterm gh ghostty zed zellij codex gemini)

detect_os() {
  if [[ "$OSTYPE" == "darwin"* ]]; then echo macos
  elif [ -f /etc/arch-release ]; then echo arch
  elif [ -f /etc/debian_version ]; then echo debian
  else echo unknown; fi
}

install_macos() {
  command -v brew >/dev/null || /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
  brew bundle --file="$DOTFILES_DIR/Brewfile"
}

install_linux() {
  local mgr=$1
  mapfile -t pkgs < "$DOTFILES_DIR/packages.txt"
  if [ "$mgr" = pacman ]; then
    sudo pacman -Syu --needed --noconfirm "${pkgs[@]}" openbsd-netcat bind starship || true
  else
    sudo apt update
    sudo apt install -y "${pkgs[@]}" netcat-openbsd dnsutils || true
    command -v starship >/dev/null || curl -sS https://starship.rs/install.sh | sh -s -- -y
  fi
  command -v stow >/dev/null || { [ "$mgr" = pacman ] && sudo pacman -S --noconfirm stow || sudo apt install -y stow; }
}

os=$(detect_os)
echo "Detected OS: $os"
case "$os" in
  macos)  install_macos ;;
  arch)   install_linux pacman ;;
  debian) install_linux apt ;;
  *) echo "Unsupported OS"; exit 1 ;;
esac

# ponytail: Linux package names are best-effort; starship/eza fall back to curl/cargo per distro.

command -v stow >/dev/null || { echo "stow missing"; exit 1; }
stow --no-folding --target="$HOME" --dir="$DOTFILES_DIR" "${PACKAGES[@]}"

# Optional tools not cleanly in package managers
command -v uv >/dev/null     || curl -LsSf https://astral.sh/uv/install.sh | sh
command -v claude >/dev/null || curl -fsSL https://claude.ai/install.sh | bash

echo "Done. Restart your shell (new ZDOTDIR) or run: exec zsh -l"
