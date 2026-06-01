#!/bin/bash
set -uo pipefail

# Directory where bugs will be checked out
WORK_DIR="/work"
mkdir -p "$WORK_DIR"

FAILURE_LOG="$WORK_DIR/checkout_failures.log"
echo "Checkout Failures Log - $(date)" > "$FAILURE_LOG"
echo "========================================" >> "$FAILURE_LOG"

TOTAL_ATTEMPTS=0
SUCCESSFUL=0
FAILED=0
SKIPPED=0

checkout_bug() {
    local PID="$1"
    local BID="$2"
    local DIR_NAME="${PID}/${BID}"
    local TARGET_PATH="$WORK_DIR/$DIR_NAME"

    ((TOTAL_ATTEMPTS++))

    if [ -d "$TARGET_PATH" ]; then
        echo "    [SKIP] $DIR_NAME already exists."
        ((SKIPPED++))
        return 0
    fi

    echo "    [Checkout] $PID-${BID}b -> $TARGET_PATH"

    if /usr/local/bin/d4j-checkout "$PID"-"$BID" 2>&1; then
        ((SUCCESSFUL++))
        return 0
    else
        local EXIT_CODE=$?
        ((FAILED++))
        echo "    [FAIL] $PID-$BID failed with exit code $EXIT_CODE"
        echo "$PID-$BID (exit code: $EXIT_CODE)" >> "$FAILURE_LOG"
        return 1
    fi
}

echo "Starting checkout in $WORK_DIR..."
echo "--------------------------------------------------"
echo "Processing JFreeChart (Chart)"
for bug in $(seq 1 26); do #26
    checkout_bug "Chart" "$bug" || true
done

echo "Starting checkout in $WORK_DIR..."
echo "--------------------------------------------------"
echo "Closure compiler (Closure)"
for bug in $(seq 1 133); do #133
    checkout_bug "Closure" "$bug" || true
done

echo "--------------------------------------------------"
echo "Processing Commons Math (Math)"
for bug in $(seq 1 106); do #106
    checkout_bug "Math" "$bug" || true
done

echo "--------------------------------------------------"
echo "Processing Apache Commons Lang (Lang)"
for bug in $(seq 1 65); do #65
    checkout_bug "Lang" "$bug" || true
done

echo "--------------------------------------------------"
echo "Processing Joda Time (Time)"
for bug in $(seq 1 27); do #27
    checkout_bug "Time" "$bug" || true
done

echo "--------------------------------------------------"
echo "Checkout Summary:"
echo "  Total attempts:  $TOTAL_ATTEMPTS"
echo "  Successful:      $SUCCESSFUL"
echo "  Failed:          $FAILED"
echo "  Skipped:         $SKIPPED"
echo ""
echo "Failed checkouts logged to: $FAILURE_LOG"
if [ "$FAILED" -gt 0 ]; then
    echo ""
    echo "Failed bugs:"
    tail -n +3 "$FAILURE_LOG" || true
fi
echo "--------------------------------------------------"
echo "Done."

# Exit with 0 even if there were failures (for Docker build to continue)
exit 0
