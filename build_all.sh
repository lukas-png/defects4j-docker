#!/usr/bin/env bash
# Build every Defects4J version as a ready-to-work image (all active bugs
# checked out + compiled at build time). The build context is this directory
# so the shared common/ scripts are reachable.
#
#   ./build_all.sh        build everything in the matrix below
#   ./build_all.sh 2.x    build only the matching context(s)
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILTER="${1:-}"

cyan() { printf '\033[36m%b\033[0m\n' "$*"; }
green() { printf '\033[32m%b\033[0m\n' "$*"; }
yellow() { printf '\033[33m%b\033[0m\n' "$*"; }
red() { printf '\033[31m%b\033[0m\n' "$*"; }

# Version matrix:  "context|image-tag|D4J_VERSION build-arg"
# context determines Java version: 0.x.x + 1.x.x → Java 7 (Zulu), 2.x.x → Java 8
BUILDS=(
  # --- 0.x (Java 7) ---
  "version-0.x.x|d4j-full:0.1.0|0.1.0"

  # --- 1.x (Java 7) ---
  "version-1.x.x|d4j-full:1.4.0|1.4.0"

  # --- 2.x (Java 8) ---
  "version-2.x.x|d4j-full:2.0.0|2.0.0"
)


built=()
for entry in "${BUILDS[@]}"; do
    IFS='|' read -r ctx tag ver <<< "$entry"
    [[ -n "$FILTER" && "$ctx" != *"$FILTER"* ]] && continue

    cyan "\nBuilding $tag (Defects4J $ver) from $ctx"
    if podman build \
        --build-arg D4J_VERSION="$ver" \
        -f "$BASE_DIR/$ctx/Dockerfile" \
        -t "$tag" \
        "$BASE_DIR"; then
        green "Built $tag"
        built+=("$tag")
    else
        red "Failed to build $tag"
        exit 1
    fi
done

if [[ ${#built[@]} -eq 0 ]]; then
    yellow "No version matched filter '$FILTER'."
    exit 1
fi

green "\nAll requested images built:"
printf '  - %s\n' "${built[@]}"
echo
echo "Run one with e.g.:  docker run --rm -it ${built[0]}"
