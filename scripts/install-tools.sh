#!/bin/sh
set -u

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PATH="$HOME/.local/bin:$PATH"
export PATH

temp_dir=''
installed_count=0
skipped_count=0
failed_count=0
sudo_state='unknown'
packages_prepared=0

cleanup() {
  if [ -n "$temp_dir" ] && [ -d "$temp_dir" ]; then
    rm -rf -- "$temp_dir"
  fi
}
trap cleanup EXIT HUP INT TERM

has_command() {
  command -v "$1" >/dev/null 2>&1
}

report_installed() {
  printf 'installed %-18s %s\n' "$1" "$2"
  installed_count=$((installed_count + 1))
}

report_skipped() {
  printf 'skip      %-18s %s\n' "$1" "$2"
  skipped_count=$((skipped_count + 1))
}

report_failed() {
  printf 'failed    %-18s %s\n' "$1" "$2" >&2
  failed_count=$((failed_count + 1))
}

ensure_temp_dir() {
  if [ -z "$temp_dir" ]; then
    temp_dir=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-install.XXXXXX") || return 1
  fi
}

authorize_sudo() {
  if [ "$(id -u)" -eq 0 ]; then
    sudo_state='ready'
    return 0
  fi

  case "$sudo_state" in
    ready) return 0 ;;
    denied|failed) return 1 ;;
  esac

  if ! has_command sudo || [ ! -r /dev/tty ]; then
    sudo_state='failed'
    printf 'System package installation needs sudo and an interactive terminal.\n' >&2
    return 1
  fi

  printf 'System package installation requires sudo. Continue? [y/N] ' >/dev/tty
  IFS= read -r answer </dev/tty || answer=''
  case "$answer" in
    y|Y|yes|YES) ;;
    *)
      sudo_state='denied'
      printf 'System package installation was declined; user-level installs will continue.\n'
      return 1
      ;;
  esac

  printf 'sudo may now ask for your password.\n' >/dev/tty
  if sudo -v; then
    sudo_state='ready'
    return 0
  fi

  sudo_state='failed'
  printf 'sudo authorization failed; user-level installs will continue.\n' >&2
  return 1
}

run_privileged() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  else
    sudo "$@"
  fi
}

os_name=$(uname -s)
package_manager='none'

case "$os_name" in
  Darwin)
    has_command brew && package_manager='brew'
    ;;
  Linux)
    if has_command apt-get; then
      package_manager='apt'
    elif has_command dnf; then
      package_manager='dnf'
    elif has_command pacman; then
      package_manager='pacman'
    elif has_command zypper; then
      package_manager='zypper'
    fi
    ;;
  *)
    printf 'Unsupported operating system: %s\n' "$os_name" >&2
    ;;
esac

prepare_packages() {
  [ "$packages_prepared" -eq 0 ] || return 0
  packages_prepared=1

  case "$package_manager" in
    apt)
      authorize_sudo || return 1
      run_privileged apt-get update ||
        printf 'Warning: apt-get update failed; cached package data will be used.\n' >&2
      ;;
  esac
}

install_system_package() {
  package_name=$1

  case "$package_manager" in
    brew)
      brew install "$package_name"
      ;;
    apt)
      prepare_packages || return 1
      authorize_sudo || return 1
      run_privileged apt-get install -y "$package_name"
      ;;
    dnf)
      authorize_sudo || return 1
      run_privileged dnf install -y "$package_name"
      ;;
    pacman)
      authorize_sudo || return 1
      run_privileged pacman -S --needed --noconfirm "$package_name"
      ;;
    zypper)
      authorize_sudo || return 1
      run_privileged zypper --non-interactive install "$package_name"
      ;;
    *)
      return 1
      ;;
  esac
}

install_package_command() {
  label=$1
  command_name=$2
  package_name=$3

  if has_command "$command_name"; then
    report_skipped "$label" "$(command -v "$command_name")"
    return
  fi

  printf 'installing %-18s with %s\n' "$label" "$package_manager"
  if install_system_package "$package_name" && has_command "$command_name"; then
    report_installed "$label" "$(command -v "$command_name")"
  else
    report_failed "$label" "package installation failed"
  fi
}

github_asset_url() {
  repository=$1
  pattern=$2
  ensure_temp_dir || return 1
  release_file="$temp_dir/$(printf '%s' "$repository" | tr '/' '_').json"

  curl -fsSL "https://api.github.com/repos/$repository/releases/latest" \
    -o "$release_file" || return 1
  sed -n 's/.*"browser_download_url": "\([^"]*\)".*/\1/p' "$release_file" |
    grep -E "$pattern" | head -n 1
}

check_helix() {
  has_command hx || has_command helix
}

check_yazi() {
  has_command yazi && has_command ya
}

install_chezmoi_binary() {
  ensure_temp_dir || return 1
  mkdir -p "$HOME/.local/bin" || return 1
  curl -fsSL https://get.chezmoi.io -o "$temp_dir/get-chezmoi.sh" || return 1
  sh "$temp_dir/get-chezmoi.sh" -b "$HOME/.local/bin"
}

install_helix_binary() {
  case "$(uname -m)" in
    x86_64|amd64) release_arch='x86_64' ;;
    arm64|aarch64) release_arch='aarch64' ;;
    *) return 1 ;;
  esac

  ensure_temp_dir || return 1
  asset_url=$(github_asset_url helix-editor/helix \
    "/helix-[^/]+-${release_arch}-linux\\.tar\\.xz$") || return 1
  [ -n "$asset_url" ] || return 1

  archive="$temp_dir/helix.tar.xz"
  extract_dir="$temp_dir/helix"
  mkdir -p "$extract_dir" "$HOME/.local/bin" "$HOME/.config/helix" || return 1
  curl -fsSL "$asset_url" -o "$archive" || return 1
  tar -xJf "$archive" -C "$extract_dir" || return 1

  hx_source=$(find "$extract_dir" -type f -name hx | head -n 1)
  runtime_source=$(find "$extract_dir" -type d -name runtime | head -n 1)
  [ -n "$hx_source" ] && [ -n "$runtime_source" ] || return 1

  install -m 755 "$hx_source" "$HOME/.local/bin/hx" || return 1
  if [ ! -e "$HOME/.config/helix/runtime" ]; then
    cp -R "$runtime_source" "$HOME/.config/helix/runtime" || return 1
  else
    printf 'Keeping existing Helix runtime at %s\n' "$HOME/.config/helix/runtime"
  fi
}

install_yazi_binary() {
  case "$(uname -m)" in
    x86_64|amd64) release_arch='x86_64' ;;
    arm64|aarch64) release_arch='aarch64' ;;
    *) return 1 ;;
  esac

  ensure_temp_dir || return 1
  asset_url=$(github_asset_url sxyazi/yazi \
    "/yazi-${release_arch}-unknown-linux-gnu\\.zip$") || return 1
  [ -n "$asset_url" ] || return 1

  archive="$temp_dir/yazi.zip"
  extract_dir="$temp_dir/yazi"
  mkdir -p "$extract_dir" "$HOME/.local/bin" || return 1
  curl -fsSL "$asset_url" -o "$archive" || return 1
  unzip -q "$archive" -d "$extract_dir" || return 1

  yazi_source=$(find "$extract_dir" -type f -name yazi | head -n 1)
  ya_source=$(find "$extract_dir" -type f -name ya | head -n 1)
  [ -n "$yazi_source" ] && [ -n "$ya_source" ] || return 1

  install -m 755 "$yazi_source" "$HOME/.local/bin/yazi" || return 1
  install -m 755 "$ya_source" "$HOME/.local/bin/ya"
}

install_chezmoi() {
  if has_command chezmoi; then
    report_skipped chezmoi "$(command -v chezmoi)"
    return
  fi

  printf 'installing %-18s\n' chezmoi
  if [ "$os_name" = 'Darwin' ]; then
    install_system_package chezmoi
  else
    install_chezmoi_binary
  fi

  if has_command chezmoi; then
    report_installed chezmoi "$(command -v chezmoi)"
  else
    report_failed chezmoi 'installation failed'
  fi
}

install_helix() {
  if check_helix; then
    if has_command hx; then
      report_skipped helix "$(command -v hx)"
    else
      report_skipped helix "$(command -v helix)"
    fi
    return
  fi

  printf 'installing %-18s\n' helix
  helix_installed=0
  case "$os_name:$package_manager" in
    Darwin:brew|Linux:dnf|Linux:pacman)
      install_system_package helix && helix_installed=1
      ;;
    Linux:apt|Linux:zypper)
      if has_command snap && authorize_sudo; then
        run_privileged snap install --classic helix && helix_installed=1
      fi
      ;;
  esac

  if { [ "$helix_installed" -eq 0 ] || ! check_helix; } && [ "$os_name" = 'Linux' ]; then
    printf 'Falling back to the official Helix binary.\n'
    install_helix_binary && helix_installed=1
  fi

  if [ "$helix_installed" -eq 1 ] && check_helix; then
    if has_command hx; then
      report_installed helix "$(command -v hx)"
    else
      report_installed helix "$(command -v helix)"
    fi
  else
    report_failed helix 'installation failed'
  fi
}

install_yazi() {
  if check_yazi; then
    report_skipped yazi "$(command -v yazi)"
    return
  fi

  printf 'installing %-18s\n' yazi
  yazi_installed=0
  case "$os_name:$package_manager" in
    Darwin:brew|Linux:pacman)
      install_system_package yazi && yazi_installed=1
      ;;
    Linux:apt|Linux:dnf|Linux:zypper)
      if has_command snap && authorize_sudo; then
        run_privileged snap install --classic yazi && yazi_installed=1
      fi
      ;;
  esac

  if { [ "$yazi_installed" -eq 0 ] || ! check_yazi; } && [ "$os_name" = 'Linux' ]; then
    printf 'Falling back to the official Yazi binaries.\n'
    install_yazi_binary && yazi_installed=1
  fi

  if [ "$yazi_installed" -eq 1 ] && check_yazi; then
    report_installed yazi "$(command -v yazi)"
  else
    report_failed yazi 'installation failed or ya is missing'
  fi
}

printf 'Detected %s with package manager: %s\n' "$os_name" "$package_manager"

install_package_command zsh zsh zsh
install_package_command git git git
install_package_command curl curl curl
install_package_command fzf fzf fzf
install_package_command file file file
install_package_command unzip unzip unzip

if [ "$package_manager" = 'apt' ]; then
  install_package_command xz xz xz-utils
else
  install_package_command xz xz xz
fi

install_chezmoi
install_helix
install_yazi

if [ -r "$repo_dir/dot_config/zsh/vendor/zsh-autosuggestions/zsh-autosuggestions.zsh" ] &&
  [ -r "$repo_dir/dot_config/zsh/vendor/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
  report_skipped 'zsh plugins' 'vendored in this repository'
else
  report_failed 'zsh plugins' 'vendored files are missing'
fi

printf '\nSummary: %s installed, %s skipped, %s failed.\n' \
  "$installed_count" "$skipped_count" "$failed_count"
printf 'Run ./scripts/doctor.sh after applying the dotfiles.\n'
