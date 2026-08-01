#!/bin/sh
set -eu

kit_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
source_dir="$HOME/.local/share/chezmoi"

if [ -e "$source_dir" ]; then
  echo "$source_dir already exists; refusing to overwrite it." >&2
  exit 1
fi

mkdir -p "$HOME/.local/bin" "$HOME/.config/helix" "$source_dir"
cp "$kit_dir/bin/chezmoi" "$kit_dir/bin/fzf" "$kit_dir/bin/hx" \
  "$kit_dir/bin/yazi" "$kit_dir/bin/ya" "$HOME/.local/bin/"
chmod 755 "$HOME/.local/bin/chezmoi" "$HOME/.local/bin/fzf" \
  "$HOME/.local/bin/hx" "$HOME/.local/bin/yazi" "$HOME/.local/bin/ya"
cp -R "$kit_dir/helix-runtime" "$HOME/.config/helix/runtime"
cp -R "$kit_dir/source/." "$source_dir/"

"$HOME/.local/bin/chezmoi" init --apply
