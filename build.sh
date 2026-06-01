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

# Base archives the Dockerfiles COPY from base/. Downloaded on demand when
# missing (see base/.gitignore for the same URLs). Format: "file|url".
BASE_ZIPS=(
  "defects4j-repos.zip|https://defects4j.org/downloads/defects4j-repos.zip"
  "defects4j-gradle-dists.zip|https://defects4j.org/downloads/defects4j-gradle-dists.zip"
  "defects4j-gradle-deps.zip|https://defects4j.org/downloads/defects4j-gradle-deps.zip"
)

# Fetch any base/*.zip that is absent so a clean checkout can build without
# manual downloads. Existing (non-empty) archives are left untouched.
ensure_base_zips() {
    local entry file url dest tmp
    for entry in "${BASE_ZIPS[@]}"; do
        file="${entry%%|*}"
        url="${entry#*|}"
        dest="$BASE_DIR/base/$file"

        if [[ -s "$dest" ]]; then
            green "base/$file present"
            continue
        fi

        cyan "Downloading $file from $url"
        tmp="$dest.partial"
        if command -v curl >/dev/null 2>&1; then
            curl -fL --retry 3 -o "$tmp" "$url" || { rm -f "$tmp"; red "Failed to download $file"; exit 1; }
        elif command -v wget >/dev/null 2>&1; then
            wget -O "$tmp" "$url" || { rm -f "$tmp"; red "Failed to download $file"; exit 1; }
        else
            red "Neither curl nor wget available to download $file"
            exit 1
        fi
        mv "$tmp" "$dest"
        green "Downloaded base/$file"
    done
}

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

ensure_base_zips

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
