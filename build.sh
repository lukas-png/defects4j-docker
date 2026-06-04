#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REGISTRY="${REGISTRY:-ghcr.io/lukas-png/defects4j-docker}"

PUSH=0
CHECKOUT_ALL=0
FILTER=""
for arg in "$@"; do
    case "$arg" in
        --push)         PUSH=1 ;;
        --checkout-all) CHECKOUT_ALL=1 ;;
        *)              FILTER="$arg" ;;
    esac
done

cyan() { printf '\033[36m%b\033[0m\n' "$*"; }
green() { printf '\033[32m%b\033[0m\n' "$*"; }
yellow() { printf '\033[33m%b\033[0m\n' "$*"; }
red() { printf '\033[31m%b\033[0m\n' "$*"; }

# Defects4J versions
BUILDS=(
  "0.1.0"
  "0.2.0"

  "1.0.0"
  "1.0.1"
  "1.1.0"
  "1.2.0"
  "1.3.0"
  "1.3.1"
  "1.4.0"
  "1.5.0"

  "2.0.0"
  "2.0.1"
  "2.1.0"

  "3.0.0"
  "3.0.1"
)

# Base archives the Dockerfiles COPY from common/. Downloaded on demand when
# missing (see common/.gitignore for the same URLs).
BASE_ZIPS=(
  "https://defects4j.org/downloads/defects4j-repos.zip"
  "https://defects4j.org/downloads/defects4j-repos-v3.zip"
  "https://defects4j.org/downloads/defects4j-gradle-dists.zip"
  "https://defects4j.org/downloads/defects4j-gradle-deps.zip"

  "https://cdn.azul.com/zulu/bin/zulu7.56.0.11-ca-jdk7.0.352-linux_x64.tar.gz"
  "https://archive.apache.org/dist/ant/binaries/apache-ant-1.9.16-bin.tar.gz"
)

# Fetch any common/*.zip that is absent so a clean checkout can build without
# manual downloads. Existing (non-empty) archives are left untouched.
ensure_base_zips() {
    local file url dest tmp
    for url in "${BASE_ZIPS[@]}"; do
        file="${url##*/}"
        dest="$BASE_DIR/common/$file"

        if [[ -s "$dest" ]]; then
            green "common/$file present"
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
        green "Downloaded common/$file"
    done
}

ctx_for_version() {
    local ver="$1"

    case "$ver" in
        0.*) echo "version-1.x.x" ;;
        1.*) echo "version-1.x.x" ;;
        2.*) echo "version-2.x.x" ;;
        3.*) echo "version-3.x.x" ;;
        *)
            red "Unsupported Defects4J version: $ver"
            exit 1
            ;;
    esac
}

ensure_base_zips


# Container engine: honour $ENGINE if set, otherwise prefer podman, then docker.
ENGINE="${ENGINE:-}"
if [[ -z "$ENGINE" ]]; then
    if command -v podman >/dev/null 2>&1; then
        ENGINE="podman"
    elif command -v docker >/dev/null 2>&1; then
        ENGINE="docker"
    else
        red "Neither podman nor docker found on PATH."
        exit 1
    fi
elif ! command -v "$ENGINE" >/dev/null 2>&1; then
    red "Requested engine '$ENGINE' not found on PATH."
    exit 1
fi


built=()
pushed=()
for ver in "${BUILDS[@]}"; do
    [[ -n "$FILTER" && "$ver" != "$FILTER" ]] && continue

    ctx="$(ctx_for_version "$ver")"
    local_tag="defects4j:$ver"

    cyan "\nBuilding $local_tag (Defects4J $ver) from $ctx with $ENGINE"
    "$ENGINE" build \
        --build-arg D4J_VERSION="$ver" \
        --build-arg CHECKOUT_BUGS="$( [[ "$CHECKOUT_ALL" -eq 1 ]] && echo true || echo false )" \
        -f "$BASE_DIR/$ctx/Dockerfile" \
        -t "$local_tag" \
        "$BASE_DIR" || { red "Failed to build $local_tag"; exit 1; }
    green "Built $local_tag"
    built+=("$local_tag")

    if [[ "$PUSH" -eq 1 ]]; then
        remote_tag="$REGISTRY:$ver"
        "$ENGINE" tag "$local_tag" "$remote_tag"
        cyan "Pushing $remote_tag"
        "$ENGINE" push "$remote_tag"
        green "Pushed  $remote_tag"
        pushed+=("$remote_tag")
    fi
done

if [[ ${#built[@]} -eq 0 ]]; then
    yellow "No version matched filter '$FILTER'."
    exit 1
fi


if [[ "$PUSH" -eq 1 ]]; then
    green "\nAll images pushed to $REGISTRY:"
    printf '  - %s\n' "${pushed[@]}"
else
    green "\nAll requested images built:"
    printf '  - %s\n' "${built[@]}"
    echo
    echo "Run one with e.g.: $ENGINE run --rm -it ${built[0]}"
fi
