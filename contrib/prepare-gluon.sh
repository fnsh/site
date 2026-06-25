#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <build-info.json> <gluon-dir> <patches-dir>" >&2
  exit 1
fi

build_info="$1"
gluon_dir="$(realpath "$2")"
patches_dir="$(realpath "$3")"

if [ ! -f "$build_info" ]; then
  echo "Error: build info file not found: $build_info" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "Error: jq is required but not installed" >&2
  exit 1
fi

gluon_repo="$(jq -er '.gluon.repository' "$build_info")"
gluon_commit="$(jq -er '.gluon.commit' "$build_info")"
clone_url="https://github.com/${gluon_repo}.git"

echo "Preparing Gluon repository"
echo "  repo   : $clone_url"
echo "  commit : $gluon_commit"
echo "  dir    : $gluon_dir"
echo "  patches: $patches_dir"

if [ -d "$gluon_dir/.git" ]; then
  git -C "$gluon_dir" remote set-url origin "$clone_url"
else
  if [ -e "$gluon_dir" ]; then
    echo "Error: $gluon_dir exists but is not a git repository" >&2
    exit 1
  fi
  git clone "$clone_url" "$gluon_dir"
fi

git -C "$gluon_dir" fetch --tags --prune origin
git -C "$gluon_dir" checkout --detach "$gluon_commit"
git -C "$gluon_dir" reset --hard "$gluon_commit"
git -C "$gluon_dir" clean -fd

if [ ! -d "$patches_dir" ]; then
  echo "No patches directory found at $patches_dir, skipping patch application"
  exit 0
fi

echo "Applying patches from $patches_dir"
for patch in $(find "$patches_dir" -type f -name '*.patch' | sort); do
  echo "  -> $patch"
  patch_abs="$(realpath "$patch")"
  git -C "$gluon_dir" am --3way "$patch_abs"
done

echo "Prepare step completed successfully"
