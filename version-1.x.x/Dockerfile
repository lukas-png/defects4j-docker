# =============================================================================
# Defects4J 1.x.x (Java 7) — self-contained, ready-to-work image.
#
# Build with the repository root as build context (so common/ and base/ are
# reachable):
#   docker build -f version-1.x.x/Dockerfile -t d4j-full:1.4.0 \
#       --build-arg D4J_VERSION=1.4.0 .
# =============================================================================
FROM ubuntu:26.04

ENV DEBIAN_FRONTEND=noninteractive

ARG D4J_VERSION=1.4.0

ENV TZ=America/Los_Angeles


# ---------- System deps ----------
RUN apt-get update && apt-get install -y \
    git subversion \
    perl cpanminus libcrypt-dev \
    gcc g++ make build-essential \
    unzip curl wget ca-certificates \
    ant maven \
    && rm -rf /var/lib/apt/lists/*

# ---------- Install Java 7 (Zulu OpenJDK 7) ----------
ENV ZULU7_TGZ=zulu7.56.0.11-ca-jdk7.0.352-linux_x64.tar.gz
RUN mkdir -p /opt/jdks && \
    curl -fsSL "https://cdn.azul.com/zulu/bin/${ZULU7_TGZ}" -o "/tmp/${ZULU7_TGZ}" && \
    tar -xzf "/tmp/${ZULU7_TGZ}" -C /opt/jdks && \
    rm -f "/tmp/${ZULU7_TGZ}" 


ENV JAVA_HOME=/opt/jdks/zulu7.56.0.11-ca-jdk7.0.352-linux_x64
ENV PATH=${JAVA_HOME}/bin:${PATH}

# -----------------------------------------------------------------------------
# Defects4J — clone framework and check out the target version
# -----------------------------------------------------------------------------

COPY base/defects4j-repos.zip /opt/defects4j-repos.zip

WORKDIR /opt
RUN git clone https://github.com/rjust/defects4j.git
WORKDIR /opt/defects4j
RUN echo "Checking out Defects4J version: v${D4J_VERSION}" && \
    git checkout "v${D4J_VERSION}"

# #############################################################################
# # CONTAINER FIXES — patches to upstream Defects4J needed to build/run inside
# # Docker. These do NOT exist upstream; everything outside the fix blocks is
# # stock Defects4J setup. (A second fix block follows after init.sh.)
# #############################################################################

# FIX: Defects4J creates per-bug working copies with `git clone`, which uses
#      hardlinks by default and fails across Docker's overlay layers.
RUN sed -i 's|git clone $self->{repo}|git clone --no-hardlinks $self->{repo}|' \
    /opt/defects4j/framework/core/Vcs/Git.pm

# FIX: allow Defects4J's bug patches to touch paths outside the work tree
#      (modern git refuses this without --unsafe-paths).
RUN sed -i \
    's/git --work-tree=\$work_dir apply --directory=/git --work-tree=\$work_dir apply --unsafe-paths --directory=/' \
    /opt/defects4j/framework/core/Vcs/Git.pm

# #############################################################################
# # END CONTAINER FIXES (part 1)
# #############################################################################

# -----------------------------------------------------------------------------
# Local scripts — offline init, repo extraction, and bulk checkout.
#   get_repos.sh extracts the project repos from base/defects4j-repos.zip
#   (copied above to /opt/defects4j-repos.zip); nothing is downloaded at build time.
# -----------------------------------------------------------------------------
COPY version-1.x.x/init.sh         /opt/defects4j/init.sh
COPY version-1.x.x/get_repos.sh    /opt/defects4j/project_repos/get_repos.sh
COPY version-1.x.x/checkout_all.sh        /usr/local/bin/checkout_all.sh
RUN chmod +x /opt/defects4j/init.sh \
             /opt/defects4j/project_repos/get_repos.sh \
             /usr/local/bin/checkout_all.sh && \
    sed -i 's/\r$//' /opt/defects4j/init.sh \
                     /opt/defects4j/project_repos/get_repos.sh \
                     /usr/local/bin/checkout_all.sh

# Optionally bake in the local Gradle archives so init.sh can use them instead
# of downloading from defects4j.org (~100 MB for dists). The wildcards make the
# zips optional: when an archive is absent only the .keep placeholder is copied
# and init.sh falls back to the remote download for that archive.
COPY base/.gradle-keep \
     base/defects4j-gradle-dists.zip* \
     base/defects4j-gradle-deps.zip* \
     /opt/gradle-dists/

# -----------------------------------------------------------------------------
# Perl dependencies + Defects4J initialization (Java 7)
# -----------------------------------------------------------------------------
# Explicit Perl deps to bypass 'Configuring . failed' on newer cpanm/perl.
RUN cpanm --notest DBI DBD::CSV URI JSON JSON::XS List::MoreUtils version \
    || { echo "--- CPANM BUILD LOG ---"; cat /root/.cpanm/work/*/build.log; exit 1; }
RUN ./init.sh

# #############################################################################
# # CONTAINER FIXES (part 2) — must run AFTER init.sh has populated the tree
# #############################################################################

# FIX: Math's build.xml uses a <scriptdef language="javascript"> target that
#      needs a JSR-223/BSF JS engine, which is absent on Zulu JDK 7 + Major's
#      Ant. Remove that block so Math compiles.
RUN sed -i '/<scriptdef name="hastarget"/,/<\/scriptdef>/d' \
        /opt/defects4j/framework/projects/Math/Math.build.xml && \
    sed -i '/<hastarget /d' \
        /opt/defects4j/framework/projects/Math/Math.build.xml

# FIX: Major's Ant integration references ant-contrib, which is not bundled.
RUN mkdir -p /opt/defects4j/major/lib/ant && \
    curl -fsSL https://repo1.maven.org/maven2/ant-contrib/ant-contrib/1.0b3/ant-contrib-1.0b3.jar \
        -o /opt/defects4j/major/lib/ant/ant-contrib-1.0b3.jar

# #############################################################################
# # END CONTAINER FIXES (part 2)
# #############################################################################

# -----------------------------------------------------------------------------
# Environment + helper scripts
# -----------------------------------------------------------------------------
ENV D4J_HOME=/opt/defects4j
ENV PATH=/opt/defects4j/framework/bin:${PATH}
ENV JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF-8"

# d4j-checkout <Project>-<BugID>: check out + compile a single bug (Java 7)
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
'echo "[*] Java (should be 1.7): $(java -version 2>&1 | head -n 1)"' \
'echo "[*] Checkout ${PROJECT}-${BID} into ${WORK}/${PROJECT}/${BID}"' \
'defects4j checkout -p "$PROJECT" -v "${BID}b" -w "${WORK}/${PROJECT}/${BID}"' \
'cd "${WORK}/${PROJECT}/${BID}"' \
'echo "[*] Compile (Java 7)..."' \
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
