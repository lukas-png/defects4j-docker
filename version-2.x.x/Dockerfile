# =============================================================================
# Defects4J 2.* (Java 8) — self-contained, ready-to-work image.
#
# Build with the repository root as build context (so common/ is reachable):
#   docker build -f version-2.x.x/Dockerfile -t defects4j:2.0.0 --build-arg D4J_VERSION=2.0.0 .
# =============================================================================
FROM ubuntu:26.04
LABEL org.opencontainers.image.source=https://github.com/lukas-png/defects4j-docker
LABEL org.opencontainers.image.licenses=MIT

ARG D4J_VERSION=2.0.0

# -----------------------------------------------------------------------------
# System dependencies + Java 8
# -----------------------------------------------------------------------------
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        git subversion perl cpanminus libdbi-perl openjdk-8-jdk  gcc g++ make \
        build-essential unzip curl wget ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV PATH=${JAVA_HOME}/bin:${PATH}

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
###############################################################################

# FIX: Defects4J creates per-bug working copies with `git clone`, which uses
#      hardlinks by default and fails across Docker's overlay layers.
RUN sed -i 's|git clone $self->{repo}|git clone --no-hardlinks $self->{repo}|' \
    /opt/defects4j/framework/core/Vcs/Git.pm

###############################################################################
# END CONTAINER FIXES
###############################################################################

# -----------------------------------------------------------------------------
# Defects4J initialization
# -----------------------------------------------------------------------------
# Use custom get_repos.sh which uses provided defects4j-repos.zip
COPY common/get_repos.sh        /opt/defects4j/project_repos/get_repos.sh
COPY common/defects4j-repos.zip /opt/defects4j-repos.zip
RUN chmod +x /opt/defects4j/project_repos/get_repos.sh
RUN ./init.sh && rm /opt/defects4j-repos.zip

# -----------------------------------------------------------------------------
# Helper scripts
# -----------------------------------------------------------------------------
COPY common/d4j-checkout                /usr/local/bin/d4j-checkout
COPY version-2.x.x/d4j-checkout-all     /usr/local/bin/d4j-checkout-all
RUN chmod +x /usr/local/bin/d4j-checkout \
             /usr/local/bin/d4j-checkout-all


# -----------------------------------------------------------------------------
# Environment
# -----------------------------------------------------------------------------
ENV D4J_HOME=/opt/defects4j
ENV PATH=/opt/defects4j/framework/bin:${PATH}
ENV TZ=America/Los_Angeles

WORKDIR /work
CMD ["bash"]
