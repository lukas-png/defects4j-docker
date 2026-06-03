# =============================================================================
# Defects4J 0.* & 1.* (Java 7) — self-contained, ready-to-work image.
#
# Build with the repository root as build context (so common/ is reachable):
#   docker build -f version-1.x.x/Dockerfile -t defects4j:1.4.0 --build-arg D4J_VERSION=1.4.0 .
# =============================================================================
FROM ubuntu:26.04
LABEL org.opencontainers.image.source=https://github.com/lukas-png/defects4j-docker
LABEL org.opencontainers.image.licenses=MIT

ARG D4J_VERSION=1.4.0

# -----------------------------------------------------------------------------
# System dependencies
# -----------------------------------------------------------------------------
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        git subversion perl cpanminus libcrypt-dev gcc g++ make \
        build-essential unzip curl wget ca-certificates ant maven \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# Java 7 (Zulu OpenJDK 7)
# -----------------------------------------------------------------------------
ENV ZULU7_TGZ=zulu7.56.0.11-ca-jdk7.0.352-linux_x64.tar.gz
RUN mkdir -p /opt/jdks && \
    curl -fsSL "https://cdn.azul.com/zulu/bin/${ZULU7_TGZ}" -o "/tmp/${ZULU7_TGZ}" && \
    tar -xzf "/tmp/${ZULU7_TGZ}" -C /opt/jdks && \
    rm -f "/tmp/${ZULU7_TGZ}" 


ENV JAVA_HOME=/opt/jdks/zulu7.56.0.11-ca-jdk7.0.352-linux_x64
ENV PATH=${JAVA_HOME}/bin:${PATH}

# -----------------------------------------------------------------------------
# Perl dependencies
# -----------------------------------------------------------------------------
# Explicit Perl deps to bypass 'Configuring . failed' on newer cpanm/perl.
RUN cpanm --notest DBI DBD::CSV URI JSON JSON::XS List::MoreUtils version \
    || { echo "--- CPANM BUILD LOG ---"; cat /root/.cpanm/work/*/build.log; exit 1; }

# -----------------------------------------------------------------------------
# Defects4J — clone framework and check out the target version
# -----------------------------------------------------------------------------

WORKDIR /opt
RUN git clone https://github.com/rjust/defects4j.git
WORKDIR /opt/defects4j
RUN git checkout "v${D4J_VERSION}"

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

###############################################################################
# END CONTAINER FIXES
###############################################################################

# -----------------------------------------------------------------------------
# Defects4J initialization
# -----------------------------------------------------------------------------
# Bake in the local Gradle archives so init.sh can use them instead
# of downloading from defects4j.org (~100 MB for dists). The wildcards make the
# zips optional: when an archive is absent only the .keep placeholder is copied
# and init.sh falls back to the remote download for that archive.
COPY common/defects4j-gradle-dists.zip \
     common/defects4j-gradle-deps.zip \
     /opt/gradle-dists/
# Use custom init.sh TODO why?
COPY version-1.x.x/init.sh      /opt/defects4j/init.sh
# Use custom get_repos.sh which uses provided defects4j-repos.zip
COPY common/get_repos.sh        /opt/defects4j/project_repos/get_repos.sh
RUN chmod +x /opt/defects4j/init.sh \
             /opt/defects4j/project_repos/get_repos.sh \
COPY common/defects4j-repos.zip /opt/defects4j-repos.zip
RUN ./init.sh && rm /opt/defects4j-repos.zip


# -----------------------------------------------------------------------------
# Helper scripts
# -----------------------------------------------------------------------------
COPY common/d4j-checkout                /usr/local/bin/d4j-checkout
COPY version-1.x.x/d4j-checkout-project /usr/local/bin/d4j-checkout-project
RUN chmod +x /usr/local/bin/d4j-checkout \
             /usr/local/bin/d4j-checkout-project


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

# FIX: Major's Ant integration references ant-contrib, which is not bundled.
RUN mkdir -p /opt/defects4j/major/lib/ant && \
    curl -fsSL https://repo1.maven.org/maven2/ant-contrib/ant-contrib/1.0b3/ant-contrib-1.0b3.jar \
        -o /opt/defects4j/major/lib/ant/ant-contrib-1.0b3.jar

###############################################################################
# END CONTAINER FIXES (part 2)
###############################################################################

# -----------------------------------------------------------------------------
# Environment
# -----------------------------------------------------------------------------
ENV D4J_HOME=/opt/defects4j
ENV PATH=/opt/defects4j/framework/bin:${PATH}
ENV JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF-8"
ENV TZ=America/Los_Angeles


WORKDIR /work
CMD ["bash"]
