#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
failed=0

check_required() {
  if command -v "$1" >/dev/null 2>&1; then
    printf 'ok       %-24s %s\n' "$1" "$(command -v "$1")"
  else
    printf 'missing  %-24s required\n' "$1"
    failed=1
  fi
}

check_optional() {
  if command -v "$1" >/dev/null 2>&1; then
    printf 'ok       %-24s %s\n' "$1" "$(command -v "$1")"
  else
    printf 'optional %-24s not installed\n' "$1"
  fi
}

check_optional_editor() {
  if command -v hx >/dev/null 2>&1; then
    printf 'ok       %-24s %s\n' 'helix (hx)' "$(command -v hx)"
  elif command -v helix >/dev/null 2>&1; then
    printf 'ok       %-24s %s\n' 'helix' "$(command -v helix)"
  else
    printf 'optional %-24s not installed\n' 'helix'
  fi
}

check_required zsh
check_required chezmoi
check_required git
check_required curl
check_optional fzf
check_optional_editor
check_optional yazi
check_optional ya
check_optional conda

if command -v fzf >/dev/null 2>&1; then
  if fzf --zsh >/dev/null 2>&1; then
    printf 'ok       %-24s modern integration\n' 'fzf zsh'
  elif [ -r /usr/share/doc/fzf/examples/key-bindings.zsh ]; then
    printf 'ok       %-24s distribution fallback\n' 'fzf zsh'
  else
    printf 'warning  %-24s integration unavailable\n' 'fzf zsh'
  fi
fi

for file in \
  "$repo_dir/dot_config/zsh/vendor/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  "$repo_dir/dot_config/zsh/vendor/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
do
  if [ -r "$file" ]; then
    printf 'ok       %-24s present\n' "$(basename "$file")"
  else
    printf 'missing  %-24s required\n' "$(basename "$file")"
    failed=1
  fi
done

exit "$failed"
