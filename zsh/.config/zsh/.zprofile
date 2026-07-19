# .zprofile

# Preserve the existing PATH
export ORIGINAL_PATH="$PATH"

# Add common paths (you can adjust these based on your system setup)
export PATH="/opt/homebrew/bin:$PATH"  # M1/M2 Macs with Homebrew
export PATH="$HOME/bin:$PATH"  # Add local bin directory


# Hermes Agent — ensure ~/.local/bin is on PATH
export PATH="$HOME/.local/bin:$PATH"
