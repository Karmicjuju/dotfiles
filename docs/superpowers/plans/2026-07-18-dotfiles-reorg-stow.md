# Dotfiles Reorg (Stow + XDG + Minimal Bootstrap) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate the dotfiles repo to GNU Stow packages, consolidate git/zsh/codex into `~/.config` (XDG), track more configs safely, and shrink `init.sh` to a thin runner backed by declarative manifests — without breaking the live machine.

**Architecture:** Each config becomes a Stow *package* whose internal tree mirrors `$HOME`. Linking is `stow --no-folding --target="$HOME" <pkgs>` (no-folding guarantees stow creates real directories and symlinks only tracked files, so apps never write state into the repo). OS differences stay handled in-file. `init.sh` detects OS, installs from `Brewfile`/`packages.txt`, ensures `stow`, and runs it.

**Tech Stack:** GNU Stow, Homebrew (`brew bundle`), zsh (`ZDOTDIR`), git native XDG, bash.

## Global Constraints

- Repo `Karmicjuju/dotfiles` is **PUBLIC** — no secret may ever be tracked. Secret files: `**/auth.json`, `**/oauth_creds.json`, `**/google_accounts.json`, `*.local`.
- Stow always invoked with `--no-folding --target="$HOME"`.
- Explicit package list only — never `stow */` (would link `shell/` and `.claude/`).
- Stow package set: `zsh bash git starship nvim wezterm gh ghostty zed zellij codex gemini`.
- Non-packages, untouched by stow: `shell/` (sourced via `~/.config/dotfiles-dir`), `.claude/`.
- All work on branch `dotfiles-reorg`. Keep the current terminal session open throughout (its env is already sourced) so a broken intermediate state can't lock you out. Rollback: `git checkout main` then re-run the old link step / `stow -D`.
- Commit after every task.

---

### Task 1: Create branch, install stow, add verification script

**Files:**
- Create: `scripts/verify-links.sh`

**Interfaces:**
- Produces: `scripts/verify-links.sh` — run as `bash scripts/verify-links.sh`; exits 0 iff every managed dotfile is a symlink into the repo and no secret is tracked. Reused as the "test" in later tasks.

- [ ] **Step 1: Create the branch**

```bash
cd "$HOME/dotfiles"
git checkout -b dotfiles-reorg
```

- [ ] **Step 2: Ensure stow is installed**

```bash
command -v stow >/dev/null || brew install stow
stow --version
```
Expected: prints a version (e.g. `stow (GNU Stow) version 2.4.x`).

- [ ] **Step 3: Write the verification script**

```bash
mkdir -p scripts
cat > scripts/verify-links.sh <<'EOF'
#!/usr/bin/env bash
# Verify every managed dotfile is a symlink into the repo, and no secret is tracked.
set -u
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
fail=0
check() {
  local p="$1"
  if [ -L "$p" ] && readlink "$p" | grep -q "dotfiles"; then
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
exit $fail
EOF
chmod +x scripts/verify-links.sh
```

- [ ] **Step 4: Run it (expected to FAIL now — nothing migrated yet)**

Run: `bash scripts/verify-links.sh; echo "exit=$?"`
Expected: several `FAIL` lines (new paths don't exist yet), `exit=1`. This confirms the checker actually detects an unmigrated state.

- [ ] **Step 5: Commit**

```bash
git add scripts/verify-links.sh
git commit -m "chore: add dotfiles link verification script"
```

---

### Task 2: Add secret & state gitignore guards

Do this **before** any `stow --adopt`, so an adopted file can never stage a secret.

**Files:**
- Modify: `.gitignore`

- [ ] **Step 1: Append guards to .gitignore**

```bash
cd "$HOME/dotfiles"
cat >> .gitignore <<'EOF'

# --- secrets: never track (repo is public) ---
**/auth.json
**/oauth_creds.json
**/google_accounts.json
*.local

# --- runtime state that may sit next to tracked config ---
**/.zsh_history
**/.zcompdump*
**/.zsh_sessions/
EOF
```

- [ ] **Step 2: Verify the patterns match**

Run:
```bash
git check-ignore -v codex/.config/codex/auth.json gemini/.gemini/oauth_creds.json git/.config/git/config.local
```
Expected: three lines, each showing a `.gitignore` rule matched (paths need not exist yet — `check-ignore` matches by pattern).

- [ ] **Step 3: Commit**

```bash
git add .gitignore
git commit -m "chore: gitignore secrets and shell runtime state"
```

---

### Task 3: Restructure existing packages into stow layout (repo only)

Pure `git mv` + content edits inside the repo. This **breaks the live symlinks** (their targets move) — that is expected and repaired in Task 5. Keep your terminal open.

**Files:**
- Move: `zsh/.zshrc` → `zsh/.config/zsh/.zshrc`
- Create: `zsh/.zshenv`
- Move: `git/.gitconfig` → `git/.config/git/config`
- Move: `starship/starship.toml` → `starship/.config/starship.toml`
- Move: `nvim/{init.lua,lua,lazy-lock.json,.stylua.toml}` → `nvim/.config/nvim/`
- Move: `wezterm/wezterm.lua` → `wezterm/.config/wezterm/wezterm.lua`
- Move: `gh/{config.yml,hosts.yml}` → `gh/.config/gh/`
- Move: `ghostty/config` → `ghostty/.config/ghostty/config`
- (bash unchanged: `bash/.bashrc` stays)

**Interfaces:**
- Produces: the on-disk package layout the stow command in Task 5 depends on.

- [ ] **Step 1: git mv the simple packages**

```bash
cd "$HOME/dotfiles"
mkdir -p zsh/.config/zsh git/.config/git starship/.config wezterm/.config/wezterm gh/.config/gh ghostty/.config/ghostty
git mv zsh/.zshrc         zsh/.config/zsh/.zshrc
git mv git/.gitconfig     git/.config/git/config
git mv starship/starship.toml starship/.config/starship.toml
git mv wezterm/wezterm.lua wezterm/.config/wezterm/wezterm.lua
git mv gh/config.yml      gh/.config/gh/config.yml
git mv gh/hosts.yml       gh/.config/gh/hosts.yml
git mv ghostty/config     ghostty/.config/ghostty/config
```

- [ ] **Step 2: git mv the nvim package (directory contents)**

```bash
cd "$HOME/dotfiles/nvim"
mkdir -p .config/nvim
git mv init.lua lua lazy-lock.json .stylua.toml .config/nvim/
cd "$HOME/dotfiles"
```

- [ ] **Step 3: Create `zsh/.zshenv` (the only zsh file that stays in $HOME)**

```bash
cat > zsh/.zshenv <<'EOF'
# Bootstrap: relocate the rest of zsh's dotfiles under ~/.config/zsh (XDG).
export ZDOTDIR="$HOME/.config/zsh"

# Codex CLI: keep all its state under ~/.config (see dotfiles reorg spec).
export CODEX_HOME="$HOME/.config/codex"
EOF
git add zsh/.zshenv
```

- [ ] **Step 4: Edit `zsh/.config/zsh/.zshrc` — history path and local-override path**

In `zsh/.config/zsh/.zshrc`, change the `HISTFILE` line from:

```zsh
HISTFILE="$HOME/.zsh_history"
```
to:
```zsh
HISTFILE="$ZDOTDIR/.zsh_history"
```

and change the local-override line at the bottom from:

```zsh
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
```
to:
```zsh
[[ -f "$ZDOTDIR/.zshrc.local" ]] && source "$ZDOTDIR/.zshrc.local"
```

- [ ] **Step 5: Edit `git/.config/git/config` — re-point the include**

In `git/.config/git/config`, change:

```gitconfig
[include]
    path = ~/.gitconfig.local
```
to:
```gitconfig
[include]
    path = ~/.config/git/config.local
```

- [ ] **Step 6: Verify repo layout and shell syntax**

Run:
```bash
cd "$HOME/dotfiles"
find zsh bash git starship nvim wezterm gh ghostty -type f | sort
zsh -n zsh/.config/zsh/.zshrc && echo "zshrc syntax OK"
zsh -n zsh/.zshenv && echo "zshenv syntax OK"
git config -f git/.config/git/config --get include.path
```
Expected: files listed under their `.config/...` paths; both "syntax OK" lines; include path prints `~/.config/git/config.local`.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "refactor: restructure configs into stow packages + XDG paths"
```

---

### Task 4: Minimal init.sh + Brewfile + packages.txt + POLICY.md

**Files:**
- Overwrite: `init.sh`
- Create: `Brewfile`
- Create: `packages.txt`
- Create: `POLICY.md`

**Interfaces:**
- Consumes: the stow package layout from Task 3.
- Produces: `init.sh` that a fresh machine runs to install packages + link everything.

- [ ] **Step 1: Write the Brewfile**

```bash
cd "$HOME/dotfiles"
cat > Brewfile <<'EOF'
# CLI
brew "git"
brew "curl"
brew "stow"
brew "zsh"
brew "zsh-syntax-highlighting"
brew "zsh-autosuggestions"
brew "neovim"
brew "zoxide"
brew "eza"
brew "fzf"
brew "starship"
brew "zellij"
brew "python@3.12"
brew "netcat"
brew "bind"

# GUI
cask "wezterm"
cask "ghostty"
cask "zed"
EOF
```

- [ ] **Step 2: Write packages.txt (Linux common set)**

```bash
cat > packages.txt <<'EOF'
git
curl
stow
zsh
zsh-syntax-highlighting
zsh-autosuggestions
neovim
zoxide
eza
fzf
python3
zellij
EOF
```

- [ ] **Step 3: Write the thin init.sh**

```bash
cat > init.sh <<'EOF'
#!/usr/bin/env bash
# Bootstrap: install packages, then link dotfiles with GNU Stow.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR"
mkdir -p "$HOME/.config"
echo "$DOTFILES_DIR" > "$HOME/.config/dotfiles-dir"

PACKAGES=(zsh bash git starship nvim wezterm gh ghostty zed zellij codex gemini)

detect_os() {
  if [[ "$OSTYPE" == "darwin"* ]]; then echo macos
  elif [ -f /etc/arch-release ]; then echo arch
  elif [ -f /etc/debian_version ]; then echo debian
  else echo unknown; fi
}

install_macos() {
  command -v brew >/dev/null || /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
  brew bundle --file="$DOTFILES_DIR/Brewfile"
}

install_linux() {
  local mgr=$1
  mapfile -t pkgs < "$DOTFILES_DIR/packages.txt"
  if [ "$mgr" = pacman ]; then
    sudo pacman -Syu --needed --noconfirm "${pkgs[@]}" openbsd-netcat bind starship || true
  else
    sudo apt update
    sudo apt install -y "${pkgs[@]}" netcat-openbsd dnsutils || true
    command -v starship >/dev/null || curl -sS https://starship.rs/install.sh | sh -s -- -y
  fi
  command -v stow >/dev/null || { [ "$mgr" = pacman ] && sudo pacman -S --noconfirm stow || sudo apt install -y stow; }
}

os=$(detect_os)
echo "Detected OS: $os"
case "$os" in
  macos)  install_macos ;;
  arch)   install_linux pacman ;;
  debian) install_linux apt ;;
  *) echo "Unsupported OS"; exit 1 ;;
esac

# ponytail: Linux package names are best-effort; starship/eza fall back to curl/cargo per distro.

command -v stow >/dev/null || { echo "stow missing"; exit 1; }
stow --no-folding --target="$HOME" --dir="$DOTFILES_DIR" "${PACKAGES[@]}"

# Optional tools not cleanly in package managers
command -v uv >/dev/null     || curl -LsSf https://astral.sh/uv/install.sh | sh
command -v claude >/dev/null || curl -fsSL https://claude.ai/install.sh | bash

echo "Done. Restart your shell (new ZDOTDIR) or run: exec zsh -l"
EOF
chmod +x init.sh
```

- [ ] **Step 4: Write POLICY.md**

```bash
cat > POLICY.md <<'EOF'
# Dotfiles tracking policy

**Tracked:** hand-authored config files, managed as GNU Stow packages
(target `$HOME`, linked with `--no-folding`).

**Never tracked:** secrets (`auth.json`, `oauth_creds.json`,
`google_accounts.json`, `*.local`), tool state/caches, large app data
directories. Machine-specific and secret values live in `*.local` files
(`~/.config/git/config.local`, `~/.config/zsh/.zshrc.local`).

**Add a new config:** create a package dir mirroring `$HOME`
(e.g. `foo/.config/foo/foo.toml`), add `foo` to `PACKAGES` in `init.sh`,
run `stow --no-folding --target="$HOME" foo`.

**OS differences** are handled in-file (e.g. `is_macos()`), not via templating.
EOF
```

- [ ] **Step 5: Verify init.sh parses**

Run: `bash -n init.sh && echo "init.sh syntax OK"`
Expected: `init.sh syntax OK`.

- [ ] **Step 6: Commit**

```bash
git add init.sh Brewfile packages.txt POLICY.md
git commit -m "feat: minimal stow-based init.sh with declarative manifests"
```

---

### Task 5: Cut over on disk — remove old links, relocate zsh/git, stow, verify

This repairs the live machine to the new layout. Keep the current terminal open; test with a **new** `zsh` invocation.

**Files:** (on-disk `$HOME` changes; repo change = adopting `.zprofile`)
- Move into repo: `~/.zprofile` → `zsh/.config/zsh/.zprofile`

- [ ] **Step 1: Remove the old live symlinks**

```bash
rm -f "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.gitconfig" \
      "$HOME/.config/starship.toml" \
      "$HOME/.config/wezterm/wezterm.lua" \
      "$HOME/.config/gh/config.yml" "$HOME/.config/gh/hosts.yml" \
      "$HOME/.config/ghostty/config"
# nvim is currently a single dir symlink:
[ -L "$HOME/.config/nvim" ] && rm -f "$HOME/.config/nvim"
```

- [ ] **Step 2: Relocate zsh & git local/state files into ~/.config**

```bash
mkdir -p "$HOME/.config/zsh" "$HOME/.config/git"
# untracked machine-local files (stay untracked; gitignored via *.local):
[ -f "$HOME/.zshrc.local" ]   && mv "$HOME/.zshrc.local"   "$HOME/.config/zsh/.zshrc.local"
[ -f "$HOME/.gitconfig.local" ] && mv "$HOME/.gitconfig.local" "$HOME/.config/git/config.local"
# history (state):
[ -f "$HOME/.zsh_history" ]   && mv "$HOME/.zsh_history"   "$HOME/.config/zsh/.zsh_history"
```

- [ ] **Step 3: Adopt `~/.zprofile` into the zsh package**

```bash
cd "$HOME/dotfiles"
mv "$HOME/.zprofile" zsh/.config/zsh/.zprofile
git add zsh/.config/zsh/.zprofile
```

- [ ] **Step 4: Stow the existing packages**

```bash
cd "$HOME/dotfiles"
stow --no-folding --target="$HOME" zsh bash git starship nvim wezterm gh ghostty
```
Expected: no output (success). If stow reports a conflict, the target still exists as a real file — inspect it, back it up, remove, re-run.

- [ ] **Step 5: Verify links resolve and a fresh shell boots**

Run:
```bash
bash "$HOME/dotfiles/scripts/verify-links.sh"    # zed/zellij/codex/gemini lines still FAIL — adopted in Tasks 6-7
echo "--- fresh login shell ---"
zsh -l -i -c 'echo SHELL_OK; echo "ZDOTDIR=$ZDOTDIR"; git config --get core.editor'
```
Expected: `OK` for `.zshenv`, `.config/zsh/.zshrc`, `.config/zsh/.zprofile`, `.bashrc`, `.config/git/config`, `.config/starship.toml`, `.config/nvim/init.lua`, `.config/wezterm/wezterm.lua`, `.config/gh/config.yml`, `.config/ghostty/config`; the fresh shell prints `SHELL_OK`, `ZDOTDIR=/Users/<you>/.config/zsh`, and `nvim`.

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat: adopt .zprofile into zsh package"
```

---

### Task 6: Relocate codex to ~/.config and track its config

**Files:**
- Create: `codex/.config/codex/config.toml`, `codex/.config/codex/AGENTS.md` (via adopt)

**Interfaces:**
- Consumes: `CODEX_HOME="$HOME/.config/codex"` already exported in `zsh/.zshenv` (Task 3).

- [ ] **Step 1: Move the codex dir under ~/.config**

```bash
[ -d "$HOME/.codex" ] && mv "$HOME/.codex" "$HOME/.config/codex"
ls "$HOME/.config/codex/config.toml" && echo "codex relocated"
```
Expected: prints the path and `codex relocated`. (Rename on the same filesystem is instant regardless of the ~2GB size.)

- [ ] **Step 2: Create the package placeholders and adopt**

```bash
cd "$HOME/dotfiles"
mkdir -p codex/.config/codex
touch codex/.config/codex/config.toml codex/.config/codex/AGENTS.md
[ -f "$HOME/.config/codex/AGENTS.md" ] || rm codex/.config/codex/AGENTS.md   # skip if you have none
stow --no-folding --adopt --target="$HOME" codex
```
Note: `--adopt` moves the real `~/.config/codex/config.toml` (and `AGENTS.md`) into the repo, overwriting the empty placeholders, and replaces them with symlinks.

- [ ] **Step 3: Verify — config linked, secret NOT tracked**

Run:
```bash
readlink "$HOME/.config/codex/config.toml"
[ -f "$HOME/.config/codex/auth.json" ] && ! git -C "$HOME/dotfiles" check-ignore -q codex/.config/codex/auth.json; echo "auth ignored? exit(1=ignored)=$?"
git -C "$HOME/dotfiles" status --porcelain codex/
```
Expected: `config.toml` links into `dotfiles/codex/...`; `auth.json` is git-ignored; `git status` shows only `config.toml`/`AGENTS.md` staged, never `auth.json`.

- [ ] **Step 4: Commit**

```bash
cd "$HOME/dotfiles"
git add codex
git commit -m "feat: track codex config (relocated to ~/.config/codex)"
```

---

### Task 7: Adopt zed, zellij, and gemini configs

**Files:**
- Create (via adopt): `zed/.config/zed/settings.json`, `zellij/.config/zellij/config.kdl`, `gemini/.gemini/settings.json`, `gemini/.gemini/GEMINI.md`

- [ ] **Step 1: Create placeholders for each config that exists on disk**

```bash
cd "$HOME/dotfiles"
mkdir -p zed/.config/zed zellij/.config/zellij gemini/.gemini
[ -f "$HOME/.config/zed/settings.json" ]  && touch zed/.config/zed/settings.json
[ -f "$HOME/.config/zellij/config.kdl" ]  && touch zellij/.config/zellij/config.kdl
[ -f "$HOME/.gemini/settings.json" ]      && touch gemini/.gemini/settings.json
[ -f "$HOME/.gemini/GEMINI.md" ]          && touch gemini/.gemini/GEMINI.md
```

- [ ] **Step 2: Adopt each package**

```bash
for pkg in zed zellij gemini; do
  stow --no-folding --adopt --target="$HOME" "$pkg"
done
```

- [ ] **Step 3: Verify links + gemini secrets excluded**

Run:
```bash
for p in "$HOME/.config/zed/settings.json" "$HOME/.config/zellij/config.kdl" "$HOME/.gemini/settings.json"; do
  echo "$p -> $(readlink "$p" 2>/dev/null || echo NOT-LINK)"
done
git -C "$HOME/dotfiles" check-ignore gemini/.gemini/oauth_creds.json gemini/.gemini/google_accounts.json
git -C "$HOME/dotfiles" status --porcelain gemini/
```
Expected: all three print symlinks into `dotfiles/...`; both gemini secrets echoed by `check-ignore` (proving ignored); `git status` for `gemini/` shows only `settings.json`/`GEMINI.md`, no creds files.

- [ ] **Step 4: Commit**

```bash
cd "$HOME/dotfiles"
git add zed zellij gemini
git commit -m "feat: track zed, zellij, and gemini configs"
```

---

### Task 8: Prune cruft, full verification, finish the branch

- [ ] **Step 1: Delete cruft (confirm each exists first)**

```bash
for d in "$HOME/.config/nvim-bak" "$HOME/.config/nvim.bak" "$HOME/.claude.json.backup"; do
  [ -e "$d" ] && echo "removing $d" && rm -rf "$d"
done
```

- [ ] **Step 2: Full verification — every link + no tracked secret**

Run: `bash "$HOME/dotfiles/scripts/verify-links.sh"; echo "exit=$?"`
Expected: **all** lines `OK`, secret check all `OK`, `exit=0`.

- [ ] **Step 3: Confirm no secret is tracked anywhere in history-to-be**

Run:
```bash
cd "$HOME/dotfiles"
git ls-files | grep -E 'auth\.json|oauth_creds\.json|google_accounts\.json|\.local$' && echo "!!! SECRET TRACKED" || echo "clean: no secrets tracked"
```
Expected: `clean: no secrets tracked`.

- [ ] **Step 4: Confirm a fresh login shell is fully healthy**

Run: `zsh -l -i -c 'echo OK; command -v starship >/dev/null && echo starship-ok; git s >/dev/null 2>&1 && echo git-alias-ok'`
Expected: `OK`, `starship-ok`, `git-alias-ok`.

- [ ] **Step 5: Finish the branch**

Use the superpowers:finishing-a-development-branch skill (merge to `main` or open a PR, then push). Do not merge until Steps 2–4 all pass.

---

## Self-Review

**Spec coverage:**
- Stow tool → Tasks 1,3,4,5,6,7. ✓
- XDG consolidation (git/zsh/codex) → Task 3 (repo), Task 5 (git/zsh disk), Task 6 (codex). ✓
- Track files not dirs → Tasks 6,7 adopt single files; secrets gitignored (Task 2). ✓
- Minimal init.sh + Brewfile + packages.txt → Task 4. ✓
- git→~/.config/git/config → Tasks 3,5. ✓
- zsh ZDOTDIR → Tasks 3 (.zshenv, edits),5 (disk). ✓
- codex CODEX_HOME → Tasks 3 (env),6. ✓
- bash left in $HOME → present in package list, never moved. ✓
- vim dropped → not in package set. ✓
- gemini tracked in place → Task 7. ✓
- warp skipped → absent. ✓
- Secrets never tracked → Task 2 + verified Tasks 6,7,8. ✓
- Folding hazard → resolved globally via `--no-folding` (Global Constraints). ✓
- Migration on branch, --adopt, verify loop, prune cruft → Tasks 1,5,6,7,8. ✓

**Placeholder scan:** No TBD/TODO; all file contents and commands are literal. The one `ponytail:` note in init.sh documents a deliberate best-effort scope on Linux package names, not a gap.

**Type/name consistency:** `PACKAGES` set in `init.sh` matches the Global Constraints package list and the packages stowed across Tasks 5–7. `ZDOTDIR`/`CODEX_HOME` defined in `zsh/.zshenv` (Task 3) and consumed in Tasks 5–6. `scripts/verify-links.sh` paths match the final symlink targets adopted in Tasks 5–7.
