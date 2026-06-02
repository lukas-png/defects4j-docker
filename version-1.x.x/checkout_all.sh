#!/bin/bash
set -euo pipefail

# Directory where bugs will be checked out
WORK_DIR="/work"
mkdir -p "$WORK_DIR"

checkout_bug() {
    local PID="$1"
    local BID="$2"
    local DIR_NAME="${PID}/${BID}"
    local TARGET_PATH="$WORK_DIR/$DIR_NAME"

    if [ -d "$TARGET_PATH" ]; then
        echo "    [SKIP] $DIR_NAME already exists."
        return 0
    fi

    echo "    [Checkout] $PID-${BID}b -> $TARGET_PATH"
    /usr/local/bin/d4j-checkout "$PID"-"$BID"
}

declare -A BUG_COUNTS=(
    [Chart]=26
    [Closure]=133
    [Math]=106
    [Mockito]=38
    [Lang]=65
    [Time]=27
)

for project in "$@"; do
    count="${BUG_COUNTS[$project]}"

    if [ -z "$count" ]; then
        echo "Unknown project: $project" >&2
        exit 1
    fi

    echo "--------------------------------------------------"
    echo "Processing $project ($count bugs)"

    for bug in $(seq 1 "$count"); do
        checkout_bug "$project" "$bug"
    done
done

echo "--------------------------------------------------"
echo "Done with all checkouts"
