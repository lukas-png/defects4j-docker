#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FILTER="${1:-}"

cyan() { printf '\033[36m%b\033[0m\n' "$*"; }
green() { printf '\033[32m%b\033[0m\n' "$*"; }
yellow() { printf '\033[33m%b\033[0m\n' "$*"; }
red() { printf '\033[31m%b\033[0m\n' "$*"; }

# Defects4J versions
BUILDS=(
  "0.1.0"
  "1.4.0"
  "2.0.0"
)

ctx_for_version() {
    local ver="$1"

    case "$ver" in
        0.*) echo "version-0.x.x" ;;
        1.*) echo "version-1.x.x" ;;
        2.*) echo "version-2.x.x" ;;
        *)
            red "Unsupported Defects4J version: $ver"
            exit 1
            ;;
    esac
}

built=()
for ver in "${BUILDS[@]}"; do
    [[ -n "$FILTER" && ! "$ver" =~ ^$FILTER ]] && continue

    ctx="$(ctx_for_version "$ver")"
    tag="defects4j:$ver"

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
    yellow "No version matched filter '^$FILTER'."
    exit 1
fi

green "\nAll requested images built:"
printf '  - %s\n' "${built[@]}"
echo
echo "Run one with e.g.: docker run --rm -it ${built[0]}"
