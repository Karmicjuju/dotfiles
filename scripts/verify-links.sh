#!/usr/bin/env bash
# Verify every managed dotfile is a symlink into the repo, and no secret is tracked.
set -u
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
fail=0
REPO_NAME="$(basename "$DOTFILES_DIR")"
check() {
  local p="$1"
  # stow makes relative symlinks (e.g. ../../dotfiles/... for nested targets,
  # or a bare "dotfiles/..." with no "../" when the link sits directly in
  # $HOME alongside the repo, e.g. ~/.zshenv, ~/.bashrc). Match the repo dir
  # name at the start of the target or preceded by "/", not just "/name/".
  if [ -L "$p" ] && readlink "$p" | grep -Eq "(^|/)$REPO_NAME/"; then
    echo "OK   $p"
  else
    echo "FAIL $p -> $(readlink "$p" 2>/dev/null || echo MISSING)"; fail=1
  fi
}
for p in \
  "$HOME/.zshenv" \
  "$HOME/.config/zsh/.zshrc" \
  "$HOME/.config/zsh/.zprofile" \
  "$HOME/.bashrc" \
  "$HOME/.config/git/config" \
  "$HOME/.config/starship.toml" \
  "$HOME/.config/nvim/init.lua" \
  "$HOME/.config/wezterm/wezterm.lua" \
  "$HOME/.config/gh/config.yml" \
  "$HOME/.config/ghostty/config" \
  "$HOME/.config/zed/settings.json" \
  "$HOME/.config/zellij/config.kdl" \
  "$HOME/.config/codex/config.toml" \
  "$HOME/.gemini/settings.json"; do
  check "$p"
done
echo "--- secret check ---"
cd "$DOTFILES_DIR" || exit 2
for s in auth.json oauth_creds.json google_accounts.json; do
  if git ls-files | grep -q "$s"; then echo "FAIL secret tracked: $s"; fail=1; else echo "OK   not tracked: $s"; fi
done
if git ls-files | grep -qE '\.local$'; then echo "FAIL secret tracked: *.local"; fail=1; else echo "OK   not tracked: *.local"; fi
exit $fail
