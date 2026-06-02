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

echo "Starting checkout in $WORK_DIR..."
echo "--------------------------------------------------"
echo "Processing JFreeChart (Chart)"
for bug in $(seq 1 26); do #26
    checkout_bug "Chart" "$bug"
done

echo "Starting checkout in $WORK_DIR..."
echo "--------------------------------------------------"
echo "Closure compiler (Closure)"
for bug in $(seq 1 133); do #133
    checkout_bug "Closure" "$bug"
done

echo "--------------------------------------------------"
echo "Processing Commons Math (Math)"
for bug in $(seq 1 106); do #106
    checkout_bug "Math" "$bug"
done

echo "--------------------------------------------------"
echo "Processing Apache Commons Lang (Lang)"
for bug in $(seq 1 65); do #65
    checkout_bug "Lang" "$bug"
done

echo "--------------------------------------------------"
echo "Processing Joda Time (Time)"
for bug in $(seq 1 27); do #27
    checkout_bug "Time" "$bug"
done

echo "--------------------------------------------------"
echo "Done with all checkouts"
