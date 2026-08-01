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
  "$repo_dir/dot_config/zsh/"*.zsh
do
  zsh -n "$file"
done
sh -n "$repo_dir/scripts/install-tools.sh"

mkdir -p "$test_home"
run_chezmoi --source "$repo_dir" --destination "$test_home" apply
run_chezmoi --source "$repo_dir" --destination "$test_home" apply
zsh -n "$test_home/.config/zsh/local.zsh"

case "$(uname -s)" in
  Linux) expected_proxy='http://127.0.0.1:20171' ;;
  *)     expected_proxy='http://127.0.0.1:7897' ;;
esac

HOME="$test_home" \
  XDG_CONFIG_HOME="$test_home/.config" \
  XDG_CACHE_HOME="$test_home/.cache" \
  XDG_STATE_HOME="$test_home/.local/state" \
  EXPECTED_PROXY="$expected_proxy" \
  ZDOTDIR="$test_home" \
  /bin/zsh -dfic '
  source "$HOME/.zshrc"
  typeset -f proxy_on >/dev/null
  typeset -f proxy_off >/dev/null
  [[ "$HTTP_PROXY" == "$EXPECTED_PROXY" ]]
  [[ -n "$EDITOR" ]]
'

grep -q "PROXY_HTTP_URL='http://127.0.0.1:20171'" \
  "$repo_dir/dot_config/zsh/create_local.zsh.tmpl"
grep -q "PROXY_SOCKS_URL='socks5h://127.0.0.1:20170'" \
  "$repo_dir/dot_config/zsh/create_local.zsh.tmpl"

linux_fixture="$test_root/linux"
mkdir -p "$linux_fixture/cuda/bin" "$linux_fixture/cuda/lib64" "$linux_fixture/nvm"
printf '%s\n' \
  'nvm() { print -r -- "fake nvm"; }' \
  'node() { print -r -- "fake node"; }' \
  'npm() { print -r -- "fake npm"; }' \
  'npx() { print -r -- "fake npx"; }' \
  'corepack() { print -r -- "fake corepack"; }' \
  >"$linux_fixture/nvm/nvm.sh"

CUDA_ROOT="$linux_fixture/cuda" \
  NVM_ROOT="$linux_fixture/nvm" \
  DISPLAY_DEFAULT=':0' \
  LINUX_CONFIG="$repo_dir/dot_config/zsh/linux.zsh" \
  /bin/zsh -dfc '
  path=(/usr/bin /bin)
  source "$LINUX_CONFIG"
  [[ "$CUDA_HOME" == "$CUDA_ROOT" ]]
  [[ "$path[1]" == "$CUDA_ROOT/bin" ]]
  [[ ":$LD_LIBRARY_PATH:" == *":$CUDA_ROOT/lib64:"* ]]
  [[ "$DISPLAY" == ":0" ]]
  [[ "$(node)" == "fake node" ]]
'

test -z "$(run_chezmoi --source "$repo_dir" --destination "$test_home" diff)"
echo 'All tests passed.'
