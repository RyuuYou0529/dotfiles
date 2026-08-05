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

There is no shell framework or plugin manager. Shell startup never downloads files.

## Install tools

Run the cross-platform installer from this checkout:

```sh
./scripts/install-tools.sh
```

The installer detects macOS, Debian/Ubuntu, Fedora/RHEL, Arch Linux, and openSUSE
package managers. Existing commands are skipped. A failed installation is reported,
then the installer continues with the next tool.

Before the first system package installation, the script asks for confirmation and
then lets `sudo` request the password. User-level fallbacks are installed in
`~/.local/bin`. The installer does not change the login shell. Run this manually if
zsh is not already the login shell:

```sh
chsh -s "$(command -v zsh)"
```

The zsh plugins are vendored in this repository and are never downloaded during
installation. On Linux, chezmoi, Helix, and Yazi can fall back to their official
release installers or binaries when the system package is unavailable. Snap is
not used. Ubuntu installs Yazi from the official Yazi APT repository and Helix
from the third-party PPA documented by the Helix project. The Yazi binary fallback
uses the musl build to avoid host GLIBC version mismatches.

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

Linux machines are initially created with these workstation defaults:

```zsh
PROXY_HTTP_URL='http://127.0.0.1:20171'
PROXY_SOCKS_URL='socks5h://127.0.0.1:20170'
CONDA_ROOT='/opt/miniconda3'
CUDA_ROOT='/usr/local/cuda'
NVM_ROOT="$HOME/.nvm"
DISPLAY_DEFAULT=':0'
```

CUDA and NVM are configured only when their roots exist. NVM is loaded when the
interactive shell starts so Node.js and global Node.js tools are immediately
available. `DISPLAY_DEFAULT` is used only when the environment does not already
provide `DISPLAY`, so SSH X11 forwarding is preserved.

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

The repository intentionally excludes shell history, `ref/`, SSH keys, secrets,
caches, and machine-local proxy credentials.
