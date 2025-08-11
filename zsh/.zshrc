eval "$(starship init zsh)"
eval "$(fzf --zsh)"
# ---- Zoxide (better cd) ----
eval "$(zoxide init zsh)"
alias cd="z"
# ---- Eza (better ls) -----
alias ls="eza --icons=always"
alias la="eza -a --icons=always"
alias ll="eza --icons=always"

alias v="nvim"
alias vim="nvim"
alias python="python3"

export PATH="/opt/homebrew/opt/python@3.13/bin:$PATH"

# history setup
HISTFILE=$HOME/.zhistory
SAVEHIST=1000
HISTSIZE=999
setopt share_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_verify

source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

source ~/fzf-git.sh/fzf-git.sh
# --- setup fzf theme ---
fg="#CBE0F0"
bg="#011628"
bg_highlight="#143652"
purple="#B388FF"
blue="#06BCE4"
cyan="#2CF9ED"


# Added by LM Studio CLI (lms)
export PATH="$PATH:/Users/colt/.lmstudio/bin"
# End of LM Studio CLI section

