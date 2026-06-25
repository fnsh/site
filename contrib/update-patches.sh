#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <build-info.json> <gluon-dir> <patches-dir>" >&2
  exit 1
fi

build_info="$1"
gluon_dir="$(realpath "$2")"
patches_dir="$(realpath "$3")"
patches_gluon_dir="$patches_dir/gluon"

if [ ! -f "$build_info" ]; then
  echo "Error: build info file not found: $build_info" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required but not installed" >&2
  exit 1
fi

if [ ! -d "$gluon_dir/.git" ]; then
  echo "Error: not a git repository: $gluon_dir" >&2
  exit 1
fi

gluon_commit="$(jq -er '.gluon.commit' "$build_info")"

if ! git -C "$gluon_dir" rev-parse --verify "$gluon_commit^{commit}" >/dev/null 2>&1; then
  echo "Error: commit from build info not found in $gluon_dir: $gluon_commit" >&2
  echo "Hint: run 'make prepare' first or fetch the required commit." >&2
  exit 1
fi

if [ -n "$(git -C "$gluon_dir" status --porcelain)" ]; then
  echo "Error: $gluon_dir has uncommitted changes; commit or stash first" >&2
  exit 1
fi

mkdir -p "$patches_gluon_dir"
find "$patches_gluon_dir" -type f -name '*.patch' -delete

echo "Updating patch set"
echo "  base commit : $gluon_commit"
echo "  head commit : $(git -C "$gluon_dir" rev-parse HEAD)"
echo "  output dir  : $patches_gluon_dir"

if [ "$(git -C "$gluon_dir" rev-parse HEAD)" = "$gluon_commit" ]; then
  echo "No commits on top of base commit; generated patch set is empty"
  exit 0
fi

git -C "$gluon_dir" format-patch \
  --no-numbered \
  --no-signature \
  --output-directory "$patches_gluon_dir" \
  "$gluon_commit..HEAD"

for patch_file in "$patches_gluon_dir"/*.patch; do
  sed -i 's/^From [0-9a-f]\{40\} /From /' "$patch_file"
done

echo "Patch update completed successfully"
