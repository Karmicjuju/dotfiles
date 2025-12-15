# Shared aliases - sourced by both .zshrc and .bashrc

# Python
alias python=python3
alias pip=pip3

# Editor
alias nv=nvim

# Claude Code
alias ccyolo='claude --dangerously-skip-permissions'

# Modern replacements (if available)
if command -v eza &> /dev/null; then
  alias ls='eza'
  alias ll='eza -la'
  alias la='eza -a'
  alias lt='eza --tree'
fi

# Git shortcuts
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline -20'
alias gd='git diff'
