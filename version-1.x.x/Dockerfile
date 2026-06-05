# =============================================================================
# Defects4J 0.* & 1.* (Java 7) — self-contained, ready-to-work image.
#
# Build with the repository root as build context (so common/ is reachable):
#   docker build -f version-1.x.x/Dockerfile -t defects4j:1.4.0 --build-arg D4J_VERSION=1.4.0 .
# =============================================================================
FROM ubuntu:26.04
LABEL org.opencontainers.image.source=https://github.com/lukas-png/defects4j-docker
LABEL org.opencontainers.image.licenses=MIT

# -----------------------------------------------------------------------------
# System dependencies
# -----------------------------------------------------------------------------
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        perl cpanminus build-essential libcrypt-dev git subversion unzip \
        fontconfig fonts-dejavu-core \
    && rm -rf /var/lib/apt/lists/*


# -----------------------------------------------------------------------------
# Perl dependencies
# -----------------------------------------------------------------------------
RUN cpanm --notest DBI DBD::CSV URI JSON JSON::Parse List::Util \
    || { echo "--- CPANM BUILD LOG ---"; cat /root/.cpanm/work/*/build.log; exit 1; }


# -----------------------------------------------------------------------------
# Zulu OpenJDK 7
# -----------------------------------------------------------------------------
ENV ZULU7_TGZ=zulu7.56.0.11-ca-jdk7.0.352-linux_x64.tar.gz
COPY common/${ZULU7_TGZ} /tmp/
RUN mkdir -p /opt/jdks && \
    tar -xzf "/tmp/${ZULU7_TGZ}" -C /opt/jdks && \
    rm -f "/tmp/${ZULU7_TGZ}" 
ENV JAVA_HOME=/opt/jdks/zulu7.56.0.11-ca-jdk7.0.352-linux_x64
ENV PATH=${JAVA_HOME}/bin:${PATH}


# -----------------------------------------------------------------------------
# Defects4J
# -----------------------------------------------------------------------------
ARG D4J_VERSION=1.4.0
ADD https://github.com/rjust/defects4j/archive/refs/tags/v${D4J_VERSION}.tar.gz /tmp/
RUN tar -xzf /tmp/v${D4J_VERSION}.tar.gz -C /opt && \
    mv /opt/defects4j-${D4J_VERSION} /opt/defects4j && \
    rm /tmp/v${D4J_VERSION}.tar.gz
RUN printf '%s\n' "$D4J_VERSION" > /opt/defects4j/version

###############################################################################
# CONTAINER FIXES — patches to upstream Defects4J needed to run inside Docker.
# These do NOT exist upstream; everything outside this block is stock setup.
# (first block BEFORE init.sh is run)
###############################################################################

# FIX: Defects4J creates per-bug working copies with `git clone`, which uses
#      hardlinks by default and fails across Docker's overlay layers.
RUN sed -i 's|git clone $self->{repo}|git clone --no-hardlinks $self->{repo}|' \
    /opt/defects4j/framework/core/Vcs/Git.pm

# FIX: allow Defects4J's bug patches to touch paths outside the work tree
#      (modern git refuses this without --unsafe-paths).
RUN sed -i \
    's/git --work-tree=\$work_dir apply --directory=/git --work-tree=\$work_dir apply --unsafe-paths --directory=/' \
    /opt/defects4j/framework/core/Vcs/Git.pm

# Don't check for test generation tool existence; not needed for base
# Defects4J functionality
RUN sed -i \
    '/-d "\$TESTGEN_LIB_DIR"/{N;d;}' \
     /opt/defects4j/framework/core/Constants.pm

###############################################################################
# END CONTAINER FIXES
###############################################################################


# -----------------------------------------------------------------------------
# Defects4J initialization
# -----------------------------------------------------------------------------
# simulate init.sh
COPY common/defects4j-repos.zip /tmp/
RUN unzip -q /tmp/defects4j-repos.zip -d /opt && \
    rm /tmp/defects4j-repos.zip && \
    rm -rf \
        commons-cli.git \
        commons-collections.git \
        commons-csv.git \
        jackson-core.git \
        jackson-dataformat-xml.git \
        mockito.git \
        commons-codec.git \
        commons-compress.git \
        commons-jxpath.git \
        gson.git \
        jackson-databind.git \
        jsoup.git

COPY common/major-1.3.4_jre7.zip /tmp/
RUN if ! echo "$D4J_VERSION" | grep -q '^0'; then \
        unzip -q /tmp/major-1.3.4_jre7.zip -d /opt/defects4j && \
        cp /opt/defects4j/major/bin/.ant /opt/defects4j/major/bin/ant; \
    fi && \
    rm /tmp/major-1.3.4_jre7.zip

RUN mkdir -p /opt/defects4j/framework/lib/build_systems/gradle/dists
COPY common/defects4j-gradle-dists.zip /tmp/
COPY common/defects4j-gradle-deps.zip /tmp/
RUN unzip -q /tmp/defects4j-gradle-dists.zip -d /opt/defects4j/framework/lib/build_systems/gradle/dists && \
    unzip -q /tmp/defects4j-gradle-deps.zip -d /opt/defects4j/framework/lib/build_systems/gradle && \
    rm /tmp/defects4j-gradle-dists.zip /tmp/defects4j-gradle-deps.zip

###############################################################################
# CONTAINER FIXES — patches to upstream Defects4J needed to run inside Docker.
# These do NOT exist upstream; everything outside this block is stock setup.
# (second block AFTER init.sh has run)
###############################################################################

# FIX: Math's build.xml uses a <scriptdef language="javascript"> target that
#      needs a JSR-223/BSF JS engine, which is absent on Zulu JDK 7 + Major's
#      Ant. Remove that block so Math compiles.
RUN sed -i '/<scriptdef name="hastarget"/,/<\/scriptdef>/d' \
        /opt/defects4j/framework/projects/Math/Math.build.xml && \
    sed -i '/<hastarget /d' \
        /opt/defects4j/framework/projects/Math/Math.build.xml

###############################################################################
# END CONTAINER FIXES (part 2)
###############################################################################


# -----------------------------------------------------------------------------
# Helper scripts
# -----------------------------------------------------------------------------
COPY version-1.x.x/d4j-list  /usr/local/bin/d4j-list
COPY common/d4j-checkout     /usr/local/bin/d4j-checkout
COPY common/d4j-checkout-all /usr/local/bin/d4j-checkout-all
RUN chmod +x /usr/local/bin/d4j-checkout \
             /usr/local/bin/d4j-list \
             /usr/local/bin/d4j-checkout-all


# -----------------------------------------------------------------------------
# Environment
# -----------------------------------------------------------------------------
ENV D4J_HOME=/opt/defects4j
ENV PATH=/opt/defects4j/framework/bin:${PATH}
ENV TZ=America/Los_Angeles
ENV _JAVA_OPTIONS="-XX:MaxPermSize=1g -Xmx3g -Dfile.encoding=UTF-8"


# -----------------------------------------------------------------------------
# Optionally bake the full checkout into the image at /work.
# Pass --build-arg CHECKOUT_BUGS=true to enable (>1h build, multi-GB image).
# -----------------------------------------------------------------------------
ARG CHECKOUT_BUGS=false
RUN if [ "$CHECKOUT_BUGS" = "true" ]; then \
        d4j-checkout-all; \
    fi


WORKDIR /work
CMD ["bash"]
