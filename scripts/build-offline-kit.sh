#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
os=$(uname -s | tr '[:upper:]' '[:lower:]')
arch=$(uname -m)
kit_name="dotfiles-offline-${os}-${arch}"
build_root=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-kit.XXXXXX")
kit_dir="$build_root/$kit_name"
output_dir="$repo_dir/dist"

cleanup() {
  rm -rf -- "$build_root"
}
trap cleanup EXIT HUP INT TERM

for command_name in chezmoi fzf hx yazi ya; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "$command_name is required to build the offline kit." >&2
    exit 1
  fi
done

mkdir -p "$kit_dir/bin" "$kit_dir/source" "$output_dir"
cp "$(command -v chezmoi)" "$(command -v fzf)" "$(command -v hx)" \
  "$(command -v yazi)" "$(command -v ya)" "$kit_dir/bin/"

helix_prefix=''
if command -v brew >/dev/null 2>&1; then
  helix_prefix=$(brew --prefix helix 2>/dev/null || true)
fi

if [ -n "$helix_prefix" ] && [ -d "$helix_prefix/libexec/runtime" ]; then
  cp -R "$helix_prefix/libexec/runtime" "$kit_dir/helix-runtime"
elif [ -n ${HELIX_RUNTIME:-} ] && [ -d "$HELIX_RUNTIME" ]; then
  cp -R "$HELIX_RUNTIME" "$kit_dir/helix-runtime"
else
  echo 'Helix runtime was not found. Set HELIX_RUNTIME and retry.' >&2
  exit 1
fi

tar -C "$repo_dir" \
  --exclude='.git' --exclude='dist' --exclude='ref' \
  -cf - . | tar -C "$kit_dir/source" -xf -
cp "$repo_dir/scripts/offline-install.sh" "$kit_dir/install.sh"
chmod 755 "$kit_dir/install.sh" "$kit_dir/bin/"*

archive="$output_dir/$kit_name.tar.gz"
tar -C "$build_root" -czf "$archive" "$kit_name"
echo "Created $archive"
