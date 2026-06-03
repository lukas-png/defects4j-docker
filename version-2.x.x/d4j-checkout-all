#!/bin/bash
set -euo pipefail

# Defects4J requires timezone America/Los_Angeles for test execution
export TZ=America/Los_Angeles

# Directory where bugs will be checked out
WORK_DIR="/work"
mkdir -p "$WORK_DIR"

# Base path for Defects4J projects
D4J_PROJECTS="/opt/defects4j/framework/projects"

get_bug_count() {
    local PROJECT="$1"
    local ACTIVE_BUGS_FILE="$D4J_PROJECTS/$PROJECT/active-bugs.csv"
    
    if [ ! -f "$ACTIVE_BUGS_FILE" ]; then
        echo 0
        return
    fi
    
    # Count lines excluding the header
    local COUNT=$(tail -n +2 "$ACTIVE_BUGS_FILE" | wc -l)
    echo "$COUNT"
}

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

checkout_project() {
    local PROJECT_NAME="$1"
    local PROJECT_ID="$2"

    echo "--------------------------------------------------"
    echo "Processing $PROJECT_NAME ($PROJECT_ID)"

    local BUG_COUNT=$(get_bug_count "$PROJECT_ID")
    echo "    Found $BUG_COUNT active bugs"

    if [ "$BUG_COUNT" -eq 0 ]; then
        echo "    [SKIP] No active bugs found for $PROJECT_ID"
        return
    fi

    for bug in $(seq 1 "$BUG_COUNT"); do
        checkout_bug "$PROJECT_ID" "$bug"
    done
}

echo "Starting checkout in $WORK_DIR..."

# Checkout all projects with active bugs
checkout_project "JFreeChart" "Chart"
checkout_project "Commons Math" "Math"
checkout_project "Apache Commons Lang" "Lang"
checkout_project "Joda Time" "Time"
checkout_project "Closure Compiler" "Closure"
checkout_project "Commons CLI" "Cli"
checkout_project "Commons Codec" "Codec"
checkout_project "Commons Collections" "Collections"
checkout_project "Commons Compress" "Compress"
checkout_project "Commons CSV" "Csv"
checkout_project "Gson" "Gson"
checkout_project "Jackson Core" "JacksonCore"
checkout_project "Jackson Databind" "JacksonDatabind"
checkout_project "Jackson XML" "JacksonXml"
checkout_project "Jsoup" "Jsoup"
checkout_project "Commons JXPath" "JxPath"
checkout_project "Mockito" "Mockito"

echo "--------------------------------------------------"
echo "Done with all checkouts"
