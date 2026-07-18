# Bootstrap: relocate the rest of zsh's dotfiles under ~/.config/zsh (XDG).
export ZDOTDIR="$HOME/.config/zsh"

# HISTFILE here (not .zshrc) so every zsh — incl. non-interactive — uses the
# XDG path instead of the default ~/.zsh_history.
export HISTFILE="$ZDOTDIR/.zsh_history"

# Codex CLI: keep all its state under ~/.config (see dotfiles reorg spec).
export CODEX_HOME="$HOME/.config/codex"

# Keep misc tool history out of $HOME (~/.config always exists, so no mkdir needed).
export LESSHISTFILE="$HOME/.config/less_history"
export PSQL_HISTORY="$HOME/.config/psql_history"
