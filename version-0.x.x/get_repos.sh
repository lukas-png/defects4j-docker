#!/usr/bin/env bash
#
# Populate project_repos/ from the local Defects4J repo bundle that is baked
# into the image. This script never downloads anything: the bundle under base/
# (base/defects4j-repos.zip) is the single source of truth for ALL versions.
set -e

# Local repo bundle baked into the image (from base/defects4j-repos.zip).
ARCHIVE=/opt/defects4j-repos.zip

main() {
    # Drop any stale repos, then extract the bundle in place (idempotent).
    clean
    unzip -q -u "$ARCHIVE" && mv defects4j/project_repos/* . && rm -r defects4j
}

# Remove previously extracted repositories so re-running is safe.
clean() {
    rm -rf \
    closure-compiler.git \
    commons-cli.git \
    commons-codec.git \
    commons-collections.git \
    commons-compress.git \
    commons-csv.git \
    commons-jxpath.git \
    commons-lang.git \
    commons-math.git \
    gson.git \
    jackson-core.git \
    jackson-databind.git \
    jackson-dataformat-xml.git \
    jfreechart \
    jfreechart.git \
    joda-time.git \
    jsoup.git \
    mockito.git \
    repos.csv \
    sync.sh \
    README
}

main
