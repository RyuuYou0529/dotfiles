#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
test_root=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-test.XXXXXX")
test_home="$test_root/home"

cleanup() {
  rm -rf -- "$test_root"
}
trap cleanup EXIT HUP INT TERM

run_chezmoi() {
  HOME="$test_home" \
    XDG_CONFIG_HOME="$test_home/.config" \
    XDG_CACHE_HOME="$test_home/.cache" \
    XDG_STATE_HOME="$test_home/.local/state" \
    chezmoi "$@"
}

for file in \
  "$repo_dir/dot_zshenv" \
  "$repo_dir/dot_zprofile" \
  "$repo_dir/dot_zshrc" \
  "$repo_dir/dot_config/zsh/"*.zsh \
  "$repo_dir/dot_config/zsh/create_local.zsh"
do
  zsh -n "$file"
done

mkdir -p "$test_home"
run_chezmoi --source "$repo_dir" --destination "$test_home" apply
run_chezmoi --source "$repo_dir" --destination "$test_home" apply

HOME="$test_home" \
  XDG_CONFIG_HOME="$test_home/.config" \
  XDG_CACHE_HOME="$test_home/.cache" \
  XDG_STATE_HOME="$test_home/.local/state" \
  ZDOTDIR="$test_home" \
  /bin/zsh -dfic '
  source "$HOME/.zshrc"
  typeset -f proxy_on >/dev/null
  typeset -f proxy_off >/dev/null
  [[ "$HTTP_PROXY" == "http://127.0.0.1:7897" ]]
  [[ -n "$EDITOR" ]]
'

test -z "$(run_chezmoi --source "$repo_dir" --destination "$test_home" diff)"
echo 'All tests passed.'
