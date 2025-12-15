# Shared PATH setup - sourced by both .zshrc and .bashrc

# Homebrew (macOS)
if [[ -f /opt/homebrew/bin/brew ]]; then
  # Apple Silicon
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f /usr/local/bin/brew ]]; then
  # Intel Mac
  eval "$(/usr/local/bin/brew shellenv)"
fi

# User local binaries
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"

# Cargo (Rust)
[[ -d "$HOME/.cargo/bin" ]] && export PATH="$HOME/.cargo/bin:$PATH"

# uv (Python package manager)
[[ -d "$HOME/.uv/bin" ]] && export PATH="$HOME/.uv/bin:$PATH"
