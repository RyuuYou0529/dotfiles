# Portable zsh dotfiles

Small, explicit terminal configuration for macOS and Linux, managed by chezmoi.

## Included tools

- zsh with native completion and a dependency-free prompt
- fzf shell integration
- vendored zsh-autosuggestions and zsh-syntax-highlighting
- Helix as the preferred editor, with Vim/vi fallback
- Yazi as the optional terminal file manager
- proxy helpers, enabled by default
- lazy Conda initialization
- global Codex guidance in `~/.codex/AGENTS.md`

There is no shell framework or plugin manager. Shell startup never downloads files.

## Apply from this checkout

Review the changes first:

```sh
chezmoi --source "$PWD" diff
```

Apply them:

```sh
chezmoi --source "$PWD" apply
```

For a new machine with network access:

```sh
chezmoi init --apply <repository-url>
```

## Machine-local settings

On first apply, chezmoi creates `~/.config/zsh/local.zsh` without taking ownership
of later changes. Edit it for the current machine:

```zsh
PROXY_HTTP_URL='http://127.0.0.1:7897'
PROXY_SOCKS_URL='socks5h://127.0.0.1:7897'
PROXY_NO_PROXY='localhost,127.0.0.1,::1'
PROXY_AUTO_ENABLE=1
CONDA_ROOT='/opt/miniforge3'
```

Set `PROXY_AUTO_ENABLE=0` on a machine where the proxy client is not always
available. Proxy commands are:

```sh
proxy_on
proxy_off
proxy_status
with_proxy command arg
```

Conda is loaded only when `conda` is first invoked. Run `conda init --reverse zsh`
before migrating an existing generated setup; this repository owns `.zshrc`.

## Editors and file navigation

The editor is selected in this order: `hx`, `vim`, then `vi`. Learn Helix with:

```sh
hx --tutor
```

Run Yazi with `y`. If a directory is selected before quitting, the shell changes
to that directory.

## Optional packages

On macOS:

```sh
brew install chezmoi fzf helix yazi
```

The two zsh plugins are already included in this repository and must not be
installed separately.

## Offline kit

After the user-facing binaries are installed on a machine, build a kit for
that machine's OS and architecture:

```sh
./scripts/build-offline-kit.sh
```

Copy the generated archive from `dist/` to the target machine, extract it, and
run `./install.sh`. Build one kit for each OS/architecture combination you use.

## Validation

```sh
./tests/run.sh
./scripts/doctor.sh
```

Tests apply the source state to a temporary home and never modify the live home.

## Excluded data

The repository intentionally excludes shell history, `ref/`, SSH keys, Codex
sessions and authentication, secrets, caches, and machine-local proxy credentials.
