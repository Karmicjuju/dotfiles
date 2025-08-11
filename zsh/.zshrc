alias python=python3
alias pip=pip3
alias nv=nvim
# Load local environment variables (not tracked in git)
if [[ -f ~/.zshrc.local ]]; then
    source ~/.zshrc.local
fi
alias ccyolo='claude --dangerously-skip-permissions'
export PATH="/opt/homebrew/bin:$PATH"


eval "$(starship init zsh)"

# ---- Project-aware tab/window titles for Ghostty ----
function _title_precmd() {
  local repo
  repo="$(git rev-parse --show-toplevel 2>/dev/null)"
  if [[ -n "$repo" ]]; then
    repo="${repo:t}"
    print -Pn "\e]0;$repo — %~\a"
  else
    print -Pn "\e]0;%~\a"
  fi
}
function _title_preexec() {
  # $1 is the full command line about to run
  print -Pn "\e]0;$1\a"
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd  _title_precmd
add-zsh-hook preexec _title_preexec

