# Minimal .bashrc - fallback when zsh is not available

# Determine dotfiles location
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

# Source shared configs
[[ -f "$DOTFILES_DIR/shell/paths.sh" ]] && source "$DOTFILES_DIR/shell/paths.sh"
[[ -f "$DOTFILES_DIR/shell/aliases.sh" ]] && source "$DOTFILES_DIR/shell/aliases.sh"
[[ -f "$DOTFILES_DIR/shell/functions.sh" ]] && source "$DOTFILES_DIR/shell/functions.sh"

# Initialize tools if available
command -v starship &> /dev/null && eval "$(starship init bash)"
command -v zoxide &> /dev/null && eval "$(zoxide init bash)"

# FZF key bindings
[[ -f ~/.fzf.bash ]] && source ~/.fzf.bash
[[ -f /usr/share/fzf/key-bindings.bash ]] && source /usr/share/fzf/key-bindings.bash

# Load local overrides (not tracked in git)
[[ -f ~/.bashrc.local ]] && source ~/.bashrc.local
