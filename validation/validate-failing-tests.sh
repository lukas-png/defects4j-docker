#!/usr/bin/env bash
set -euo pipefail

IMAGE=""
BUGS=()

usage() {
  echo "Usage: $0 --tag <tag> <project-bug>..."
  echo "Or:    $0 --image <image> <project-bug>..."
  echo "Example: $0 --tag 1.4.0 Chart-1 Lang-1"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tag) IMAGE="ghcr.io/lukas-png/defects4j-docker:$2"; shift 2 ;;
    --image) IMAGE="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) BUGS+=("$1"); shift ;;
  esac
done

[[ -n "$IMAGE" ]] || usage

ENGINE="${ENGINE:-}"
if [[ -z "$ENGINE" ]]; then
  if command -v podman >/dev/null 2>&1; then
    ENGINE=podman
  else
    ENGINE=docker
  fi
fi

abs_path() {
  cd "$(dirname "$1")"
  printf '%s/%s\n' "$(pwd)" "$(basename "$1")"
}

CSV_ABS="$(abs_path expected-failing-tests.csv)"
SCRIPT_ABS="$(abs_path validate-in-container.sh)"

"$ENGINE" run --rm \
  -v "$CSV_ABS:/expected-failing-tests.csv:ro" \
  -v "$SCRIPT_ABS:/usr/local/bin/validate-in-container.sh:ro" \
  "$IMAGE" \
  bash /usr/local/bin/validate-in-container.sh "${BUGS[@]}"
