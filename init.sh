#!/usr/bin/env bash
# Bootstrap: install packages, then link dotfiles with GNU Stow.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR"
mkdir -p "$HOME/.config"
echo "$DOTFILES_DIR" > "$HOME/.config/dotfiles-dir"

PACKAGES=(zsh bash git starship nvim wezterm gh ghostty zed zellij gemini)

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
  brew bundle --file="$DOTFILES_DIR/Brewfile" || echo "WARN: some brew packages failed — continuing to stow"
}

install_linux() {
  local mgr=$1 pkg
  pm_install() {  # install one package; warn instead of aborting the batch
    if [ "$mgr" = pacman ]; then
      sudo pacman -S --needed --noconfirm "$1" || echo "WARN: could not install $1"
    else
      sudo apt install -y "$1" || echo "WARN: could not install $1"
    fi
  }
  if [ "$mgr" = pacman ]; then sudo pacman -Syu --noconfirm || true; else sudo apt update || true; fi
  # One package at a time: a single unresolved name (e.g. python3 on Arch) must
  # not void the whole install, and failures should warn, not silently vanish.
  while IFS= read -r pkg; do
    [ -z "$pkg" ] && continue
    [ "$mgr" = pacman ] && [ "$pkg" = python3 ] && pkg=python   # Arch names it 'python'
    pm_install "$pkg"
  done < "$DOTFILES_DIR/packages.txt"
  if [ "$mgr" = pacman ]; then
    pm_install openbsd-netcat; pm_install bind; pm_install starship
  else
    pm_install netcat-openbsd; pm_install dnsutils
  fi
  command -v starship >/dev/null || curl -sS https://starship.rs/install.sh | sh -s -- -y
  command -v stow >/dev/null || pm_install stow
}

os=$(detect_os)
echo "Detected OS: $os"
case "$os" in
  macos)  install_macos ;;
  arch)   install_linux pacman ;;
  debian) install_linux apt ;;
  *) echo "Unsupported OS"; exit 1 ;;
esac

# ponytail: Linux path installs each package independently and warns on failures;
# names are best-effort across apt/pacman. starship falls back to curl if absent.

command -v stow >/dev/null || { echo "stow missing"; exit 1; }
stow --no-folding --target="$HOME" --dir="$DOTFILES_DIR" "${PACKAGES[@]}"

# Optional tools not cleanly in package managers
command -v uv >/dev/null     || curl -LsSf https://astral.sh/uv/install.sh | sh
command -v claude >/dev/null || curl -fsSL https://claude.ai/install.sh | bash

echo "Done. Restart your shell (new ZDOTDIR) or run: exec zsh -l"
