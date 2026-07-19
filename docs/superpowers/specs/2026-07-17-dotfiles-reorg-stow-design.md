# Dotfiles Reorganization — Stow + XDG Consolidation + Minimal Bootstrap

Date: 2026-07-17
Status: Approved design (pre-implementation)
Repo: `Karmicjuju/dotfiles` (PUBLIC)

## Goals

All four, in priority order established with the user:

1. **Stop drift** — the repo is the single source of truth; the live config is always a symlink into it, never a divergent copy.
2. **One-command new machine** — bootstrap a fresh Mac/Linux box in one command.
3. **Declutter & prune** — cut cruft, define what's tracked, keep `$HOME` clean.
4. **Track more** — bring currently-untracked configs under version control cheaply.

## Decisions

- **Tool: GNU Stow.** OS differences stay handled *in-file* (existing `is_macos()` / OS-detect pattern), so a templating manager (chezmoi) is unnecessary and rejected.
- **XDG consolidation first.** Move configs into `~/.config` where the tool supports it, so stow packages are built around final locations (no double migration).
- **Track files, not state directories.** State-heavy dirs (`.codex`, `.cursor`, `.gemini`, `raycast`) contain credentials and large caches; only their hand-authored config files are tracked.
- **Minimal `init.sh`.** Replace ~530 lines of imperative per-tool installers with a thin runner + declarative package manifests (`Brewfile`, `packages.txt`).

## XDG Consolidation Plan

| Config | Action | Mechanism |
|--------|--------|-----------|
| git | Move to `~/.config/git/config` | Git reads it natively; re-point `[include]` to `~/.config/git/config.local` |
| zsh | Move to `~/.config/zsh/` | New `~/.zshenv` (only zsh file left in `$HOME`) sets `ZDOTDIR="$HOME/.config/zsh"`; `.zshrc`, `.zprofile`, history move there |
| codex | Move to `~/.config/codex/` | `export CODEX_HOME="$HOME/.config/codex"`; track `config.toml` + `AGENTS.md` |
| bash | Leave in `$HOME` | No XDG env; a stub would be net-zero for decluttering. Fallback shell. |
| vim | Drop | `~/.vim` is only `.netrwhist` state; no config exists |
| gemini | Stay in `~/.gemini` | Gemini CLI ignores `XDG_CONFIG_HOME` and can break on symlinked settings; track `settings.json` + `GEMINI.md` file-level |
| warp | Skip | No XDG support; Warp cloud-syncs settings |

Already in `~/.config`, no work: starship, nvim, wezterm, gh, ghostty, zed, zellij.

## Secrets — never tracked

Live credentials found next to tracked config (public repo — must be excluded):

- `~/.config/codex/auth.json` (after move)
- `~/.gemini/oauth_creds.json`, `~/.gemini/google_accounts.json`

Handling:
- `.gitignore` hard-excludes: `**/auth.json`, `**/oauth_creds.json`, `**/google_accounts.json`, `*.local`.
- Machine-local + secret values continue to use the existing `.local` override pattern (`config.local`, `.zshrc.local`), never committed.
- `~/.ssh`, `~/.aws` are never touched.

## Stow Package Layout

Stow target = `$HOME`. Each package's tree mirrors its destination.

```
zsh/.zshenv                              → ~/.zshenv          (sets ZDOTDIR)
zsh/.config/zsh/.zshrc                    → ~/.config/zsh/.zshrc
zsh/.config/zsh/.zprofile                 → ~/.config/zsh/.zprofile
bash/.bashrc                              → ~/.bashrc          (unchanged)
git/.config/git/config                    → ~/.config/git/config
starship/.config/starship.toml            → ~/.config/starship.toml
nvim/.config/nvim/**                       → ~/.config/nvim/
wezterm/.config/wezterm/wezterm.lua        → ~/.config/wezterm/wezterm.lua
gh/.config/gh/{config.yml,hosts.yml}       → ~/.config/gh/
ghostty/.config/ghostty/config             → ~/.config/ghostty/config
zed/.config/zed/settings.json              → ~/.config/zed/settings.json
zellij/.config/zellij/config.kdl           → ~/.config/zellij/config.kdl
codex/.config/codex/{config.toml,AGENTS.md} → ~/.config/codex/
gemini/.gemini/{settings.json,GEMINI.md}   → ~/.gemini/
```

Stow invocation uses an **explicit package list** (not `stow */`) so non-package dirs are never linked:

```
stow --target="$HOME" zsh bash git starship nvim wezterm gh ghostty zed zellij codex gemini
```

Not stow packages (unchanged):
- `shell/` — sourced at runtime via `~/.config/dotfiles-dir`, not symlinked.
- `.claude/` — repo settings.

### Folding hazard (correctness note for the plan)

Stow "folds" a package to a single directory symlink when the target dir doesn't exist. For packages where we link **one file into a dir the app also writes state to** (`codex`, `gemini`, `gh`), the target dir must **pre-exist as a real directory** (or use `stow --no-folding`) so stow links the file, not the folder — otherwise the app writes state into the repo. `nvim` is intentionally a single folded dir symlink (same as today; `lazy-lock.json` writes back to the repo as before).

## Minimal `init.sh`

Shrinks from ~530 lines to a ~40-line runner:

```
detect OS
  macos: brew bundle --file="$DOTFILES_DIR/Brewfile"
  linux: install packages from packages.txt (small per-distro name tweaks kept)
ensure stow is installed
stow --target="$HOME" <package list>
persist DOTFILES_DIR to ~/.config/dotfiles-dir   (unchanged mechanism)
```

New files:
- `Brewfile` — derived from the current macOS brew list + `stow` + casks (wezterm, ghostty).
- `packages.txt` — Linux package list. One acknowledged wrinkle: apt vs pacman name some packages differently (`netcat-openbsd` vs `openbsd-netcat`), so a tiny per-distro mapping stays.
- `POLICY.md` — one paragraph: what's tracked (hand-authored config) vs not (tool state, caches, secrets).

Deleted: `install_starship`, `install_neovim_debian`, `install_eza_debian`, `install_zoxide_debian` and the ~70-line hand-written symlink block. `uv` and `claude` (not cleanly in package managers) stay as two optional `curl` lines.

## Migration (safe, reversible, history-preserving)

Performed on a branch:

1. Restructure tracked packages into the new layout with `git mv` (preserves history).
2. XDG moves on disk: create `~/.zshenv`; move git/zsh/codex to their `~/.config` homes; re-point git include; add `ZDOTDIR`/`CODEX_HOME` to shell env.
3. `stow --adopt` to pull currently-untracked configs (zed, zellij, codex config, gemini config) into the repo in one move. (Note: `--adopt` overwrites repo content with the live file — review the diff before committing.)
4. Remove old symlinks, then `stow` to recreate them at the new source paths. Pre-create real target dirs for folding-hazard packages.
5. Prune cruft: `~/.config/nvim-bak`, `~/.config/nvim.bak`, `~/.claude.json.backup` (deleted with confirmation).
6. **Verify loop:** confirm every expected symlink resolves back into the repo, and that the running shell still boots (new `ZDOTDIR`), before committing.

Reversibility: `stow -D <pkg>` removes a package's links cleanly; the branch isolates the whole change until verified.

## Out of scope

- No chezmoi / templating.
- No tracking of `raycast`, `.cursor`, whole `.codex`/`.gemini` dirs, `waveterm`, `herdr`, matrix-*, tool state dirs.
- `bash` XDG relocation.

## Success criteria

- `init.sh` on a fresh machine installs packages + links all configs in one command.
- Editing a repo file changes the live config (symlink-verified).
- `$HOME` dotfile count reduced (zsh/git/codex consolidated under `~/.config`).
- No secret ever appears in the public repo (gitignore-verified).
