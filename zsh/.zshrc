# Zsh configuration

# Determine dotfiles location
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

# History configuration
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt share_history hist_expire_dups_first hist_ignore_dups hist_verify

# Source shared configs
[[ -f "$DOTFILES_DIR/shell/paths.sh" ]] && source "$DOTFILES_DIR/shell/paths.sh"
[[ -f "$DOTFILES_DIR/shell/aliases.sh" ]] && source "$DOTFILES_DIR/shell/aliases.sh"
[[ -f "$DOTFILES_DIR/shell/functions.sh" ]] && source "$DOTFILES_DIR/shell/functions.sh"

# Zsh plugins (if installed)
[[ -f /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
[[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Initialize tools
command -v starship &> /dev/null && eval "$(starship init zsh)"
command -v zoxide &> /dev/null && eval "$(zoxide init zsh)"

# FZF key bindings (macOS Homebrew and Linux paths)
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh
[[ -f /opt/homebrew/opt/fzf/shell/key-bindings.zsh ]] && source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
[[ -f /opt/homebrew/opt/fzf/shell/completion.zsh ]] && source /opt/homebrew/opt/fzf/shell/completion.zsh
[[ -f /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh
[[ -f /usr/share/fzf/completion.zsh ]] && source /usr/share/fzf/completion.zsh

# Zsh-specific: Project-aware tab/window titles + sudo indicator
_SUDO_ACTIVE=0

function _title_precmd() {
  # Reset background if sudo was active
  if [[ $_SUDO_ACTIVE -eq 1 ]]; then
    printf '\e]111\a'  # Reset background to terminal default (theme-aware)
    _SUDO_ACTIVE=0
  fi

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
  # Detect privileged commands and tint background red
  if [[ "$1" =~ ^(sudo|doas|pkexec) ]]; then
    printf '\e]11;#442a2a\a'  # Dark red tint
    _SUDO_ACTIVE=1
  fi

  print -Pn "\e]0;$1\a"
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd  _title_precmd
add-zsh-hook preexec _title_preexec

# Load local overrides (not tracked in git)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

. "$HOME/.local/bin/env"
