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
