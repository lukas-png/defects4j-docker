#!/usr/bin/env bash
# Make the container "ready to work": seed /work from the baked-in cache the
# first time it is empty (e.g. fresh container, or an empty mounted volume),
# then drop into the requested command inside /work.
set -euo pipefail

CACHE_DIR=/opt/d4j-cache
WORK_DIR=/work

mkdir -p "$WORK_DIR"

if [ -d "$CACHE_DIR" ] && [ -z "$(ls -A "$WORK_DIR" 2>/dev/null || true)" ]; then
    echo "Seeding $WORK_DIR from $CACHE_DIR (pre-checked-out Defects4J bugs)..."
    cp -a "$CACHE_DIR/." "$WORK_DIR/"
    echo "Ready. $(find "$WORK_DIR" -maxdepth 1 -mindepth 1 -type d | wc -l) bug working directories available."
fi

cd "$WORK_DIR"
exec "$@"
