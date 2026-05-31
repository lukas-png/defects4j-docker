# =============================================================================
# Defects4J 2.x (Java 8) — self-contained, ready-to-work image.
#
# Like 0.x / 1.x this builds from a stock Ubuntu base; the only difference is
# Java 8 instead of Java 7. Build with the repository root as build context
# (so common/ and base/ are reachable):
#   docker build -f version-2.x.x/Dockerfile -t d4j-full:2.0.0 \
#       --build-arg D4J_VERSION=2.0.0 .
# =============================================================================
FROM ubuntu:26.04

ENV DEBIAN_FRONTEND=noninteractive
ARG D4J_VERSION=2.0.0

# -----------------------------------------------------------------------------
# System dependencies + Java 8
# -----------------------------------------------------------------------------
RUN apt-get update && apt-get install -y \
    git subversion \
    perl cpanminus \
    libdbi-perl \
    openjdk-8-jdk \
    gcc g++ make build-essential \
    unzip curl wget ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV PATH=${JAVA_HOME}/bin:${PATH}
# Defects4J needs this timezone for deterministic test execution
ENV TZ=America/Los_Angeles

# use-javaDefect: (re)select the Java 8 used for Defects4J builds
RUN printf '%s\n' \
'#!/usr/bin/env bash' \
'set -euo pipefail' \
'export JAVA_HOME="'"${JAVA_HOME}"'"' \
'export PATH="$JAVA_HOME/bin:${PATH//"$JAVA_HOME\/bin:"/}"' \
'java -version' \
> /usr/local/bin/use-javaDefect && chmod +x /usr/local/bin/use-javaDefect

# -----------------------------------------------------------------------------
# Defects4J — clone framework and check out the target version
# -----------------------------------------------------------------------------
WORKDIR /opt
RUN git clone https://github.com/rjust/defects4j.git
WORKDIR /opt/defects4j
RUN echo "Checking out Defects4J version: v${D4J_VERSION}" && \
    git checkout "v${D4J_VERSION}"

# #############################################################################
# # CONTAINER FIX — patch to upstream Defects4J needed to run inside Docker.
# # This does NOT exist upstream; everything outside this block is stock setup.
# #############################################################################

# FIX: Defects4J creates per-bug working copies with `git clone`, which uses
#      hardlinks by default and fails across Docker's overlay layers.
RUN sed -i 's|git clone $self->{repo}|git clone --no-hardlinks $self->{repo}|' \
    /opt/defects4j/framework/core/Vcs/Git.pm

# #############################################################################
# # END CONTAINER FIX
# #############################################################################

# -----------------------------------------------------------------------------
# Local scripts + offline repo bundle.
#   The repo bundle is the SAME single source of truth used by 0.x / 1.x:
#   base/defects4j-repos.zip. get_repos.sh extracts the project repos from
#   it (/opt/defects4j-repos.zip); nothing is downloaded at build time.
# -----------------------------------------------------------------------------
COPY base/defects4j-repos.zip      /opt/defects4j-repos.zip
COPY version-2.x.x/get_repos.sh    /opt/defects4j/project_repos/get_repos.sh
COPY version-2.x.x/checkout_all.sh        /usr/local/bin/checkout_all.sh
RUN chmod +x /opt/defects4j/project_repos/get_repos.sh \
             /usr/local/bin/checkout_all.sh && \
    sed -i 's/\r$//' /opt/defects4j/project_repos/get_repos.sh \
                     /usr/local/bin/checkout_all.sh

# -----------------------------------------------------------------------------
# Defects4J initialization (Java 8) — uses the upstream init.sh
# -----------------------------------------------------------------------------
RUN ./init.sh

# -----------------------------------------------------------------------------
# Environment + helper scripts
# -----------------------------------------------------------------------------
ENV D4J_HOME=/opt/defects4j
ENV PATH=/opt/defects4j/framework/bin:${PATH}

# d4j-checkout <Project>-<BugID>: check out + compile a single bug (Java 8)
RUN printf '%s\n' \
'#!/usr/bin/env bash' \
'set -euo pipefail' \
'BUG="${1:-Lang-1}"' \
'WORK="${2:-/work}"' \
'PROJECT="${BUG%%-*}"' \
'BID="${BUG##*-}"' \
'' \
'export JAVA_HOME="'"${JAVA_HOME}"'"' \
'export PATH="$JAVA_HOME/bin:${PATH//"$JAVA_HOME\/bin:"/}"' \
'' \
'mkdir -p "$WORK/$PROJECT"' \
'echo "[*] Java (should be 1.8): $(java -version 2>&1 | head -n 1)"' \
'echo "[*] Checkout ${PROJECT}-${BID} into ${WORK}/${PROJECT}/${BID}"' \
'defects4j checkout -p "$PROJECT" -v "${BID}b" -w "${WORK}/${PROJECT}/${BID}"' \
'cd "${WORK}/${PROJECT}/${BID}"' \
'echo "[*] Compile (Java 8)..."' \
'defects4j compile' \
'echo "[*] Done. Run tests with: defects4j test"' \
> /usr/local/bin/d4j-checkout && chmod +x /usr/local/bin/d4j-checkout

# -----------------------------------------------------------------------------
# Bake the full checkout into the image, then move it to the cache so /work
# starts empty and is seeded by the entrypoint at run time.
# -----------------------------------------------------------------------------
RUN /usr/local/bin/checkout_all.sh && \
    mkdir -p /opt/d4j-cache && \
    mv /work/* /opt/d4j-cache/ 2>/dev/null || true

# Ready-to-work entrypoint (seeds /work from the cache on first start)
COPY common/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh && sed -i 's/\r$//' /usr/local/bin/entrypoint.sh

WORKDIR /work
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash"]
