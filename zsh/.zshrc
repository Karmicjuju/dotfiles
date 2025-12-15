# Zsh configuration

# Determine dotfiles location
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

# Source shared configs
[[ -f "$DOTFILES_DIR/shell/paths.sh" ]] && source "$DOTFILES_DIR/shell/paths.sh"
[[ -f "$DOTFILES_DIR/shell/aliases.sh" ]] && source "$DOTFILES_DIR/shell/aliases.sh"
[[ -f "$DOTFILES_DIR/shell/functions.sh" ]] && source "$DOTFILES_DIR/shell/functions.sh"

# Initialize tools
command -v starship &> /dev/null && eval "$(starship init zsh)"
command -v zoxide &> /dev/null && eval "$(zoxide init zsh)"

# FZF key bindings
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh
[[ -f /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh

# Zsh-specific: Project-aware tab/window titles
function _title_precmd() {
  local repo
  repo="$(git rev-parse --show-toplevel 2>/dev/null)"
  if [[ -n "$repo" ]]; then
    repo="${repo:t}"
    print -Pn "\e]0;$repo - %~\a"
  else
    print -Pn "\e]0;%~\a"
  fi
}

function _title_preexec() {
  print -Pn "\e]0;$1\a"
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd  _title_precmd
add-zsh-hook preexec _title_preexec

# Load local overrides (not tracked in git)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
