#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if ! command -v chezmoi >/dev/null 2>&1; then
  echo 'chezmoi is required. Install it or use the offline kit.' >&2
  exit 1
fi

chezmoi --source "$repo_dir" diff
printf 'Apply these changes? [y/N] '
read -r answer
case "$answer" in
  y|Y|yes|YES) chezmoi --source "$repo_dir" apply ;;
  *) echo 'No changes were applied.' ;;
esac
