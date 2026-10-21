# Copyright © 2026 by the Rectors and Visitors of the University of Virginia.

# Base image pinned by digest for reproducible rebuilds.
# python:3.14-slim-trixie (Debian 13) multi-arch index digest resolved 2026-08-31.
# Trixie over bookworm: fewer/less-severe base CVEs (drops the sqlite critical
# and the util-linux TOCTOU cluster). Re-pin with:
#   docker buildx imagetools inspect python:3.14-slim-trixie
FROM python:3.14-slim-trixie@sha256:cae66f2ef0ec51a9891263eeee7f987dacf0a9879e8aa9353d5606e0530619a5
LABEL org.opencontainers.image.description="Lean-Enabled Development and Publication VM"

ARG DEBIAN_FRONTEND=noninteractive

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    PYTHONIOENCODING=utf-8 \
    SHELL=/bin/bash

SHELL ["/bin/bash", "-c"]
USER root

# ----- Base tools -----
RUN apt-get update && \
    apt-get install --no-install-recommends --assume-yes \
      build-essential \
      curl \
      git \
      openssh-client \
      less \
      libffi-dev \
      libssl-dev \
      locales \
      pkg-config \
      unzip \
      vim \
      wget \
      zip \
      sudo && \
    sed -i '/en_US.UTF-8/s/^# //' /etc/locale.gen && \
    locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ----- Non-root user and workspace -----
# Created early so the Rust toolchain below can be chowned to `dev`.
# `git config --system` writes to /etc/gitconfig so the setting actually
# applies to dev (a prior --global as root only touched root's config).
RUN useradd -m -s /bin/bash dev && \
    usermod -aG sudo dev && \
    echo 'dev ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/dev && \
    chmod 0440 /etc/sudoers.d/dev && \
    mkdir -p /home/dev/app && chown -R dev:dev /home/dev/app && \
    git config --system --add safe.directory /home/dev/app

# Pinned tool versions — single source of truth shared with CI. Copied after
# apt so a version bump does not rebuild the base layer; owned by dev so the
# elan step below (which runs as dev) can source and then remove it.
COPY --chown=dev:dev versions.env /tmp/versions.env

# ----- yq + GitHub CLI + mdBook (system-wide, architecture-aware) -----
RUN set -a && . /tmp/versions.env && set +a && \
    ARCH=$(dpkg --print-architecture) && \
    case "$ARCH" in \
      amd64) YQ_ARCH=amd64; GH_ARCH=amd64; GNU_ARCH=x86_64-unknown-linux-gnu ;; \
      arm64) YQ_ARCH=arm64; GH_ARCH=arm64; GNU_ARCH=aarch64-unknown-linux-musl ;; \
      *) echo "Unsupported arch: $ARCH" && exit 1 ;; \
    esac && \
    curl -fsSLo /tmp/yq.tar.gz "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${YQ_ARCH}.tar.gz" && \
    tar -xzf /tmp/yq.tar.gz -C /tmp && mv /tmp/yq_linux_${YQ_ARCH} /usr/local/bin/yq && \
    curl -fsSLo /tmp/gh.tar.gz "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_${GH_ARCH}.tar.gz" && \
    tar -xzf /tmp/gh.tar.gz -C /tmp && mv /tmp/gh_${GH_VERSION}_linux_${GH_ARCH}/bin/gh /usr/local/bin/gh && \
    curl -fsSLo /tmp/mdbook.tar.gz "https://github.com/rust-lang/mdBook/releases/download/v${MDBOOK_VERSION}/mdbook-v${MDBOOK_VERSION}-${GNU_ARCH}.tar.gz" && \
    tar -xzf /tmp/mdbook.tar.gz -C /usr/local/bin && \
    chmod +x /usr/local/bin/yq /usr/local/bin/gh /usr/local/bin/mdbook && \
    rm -rf /tmp/*.tar.gz /tmp/gh_*

# ----- Rust toolchain (slim, retained for in-container preprocessor rebuilds) -----
# Installed under /usr/local with the minimal profile, then chowned to `dev`
# (NOT chmod a+rwX) so the non-root user can run and extend cargo without the
# toolchain being world-writable. The bulky registry/git cache produced while
# compiling the preprocessors is dropped to keep the image slim.
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:${PATH}
RUN set -a && . /tmp/versions.env && set +a && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
        sh -s -- -y --no-modify-path --profile minimal && \
    cargo --version && rustc --version && \
    cargo install --locked --version ${MDBOOK_TOC_VERSION}     mdbook-toc && \
    cargo install --locked --version ${MDBOOK_MERMAID_VERSION} mdbook-mermaid && \
    cp ${CARGO_HOME}/bin/mdbook-toc ${CARGO_HOME}/bin/mdbook-mermaid /usr/local/bin/ && \
    rm -rf ${CARGO_HOME}/registry ${CARGO_HOME}/git && \
    chown -R dev:dev ${RUSTUP_HOME} ${CARGO_HOME} && \
    printf '%s\n' \
        'export RUSTUP_HOME=/usr/local/rustup' \
        'export CARGO_HOME=/usr/local/cargo' \
        'export PATH="/home/dev/.elan/bin:/home/dev/.local/bin:/usr/local/cargo/bin:$PATH"' \
        > /etc/profile.d/devcontainer.sh && \
    chmod 0644 /etc/profile.d/devcontainer.sh

# ----- Switch to dev for user-scoped installs -----
USER dev
WORKDIR /home/dev

# Put user-local tools (elan/lean, claude, pip --user) on PATH.
ENV PATH="/home/dev/.elan/bin:/home/dev/.local/bin:${PATH}"

# ----- elan (Lean toolchain manager, user-local) -----
# Installed WITHOUT a default toolchain: the correct Lean version is fetched
# lazily from each package's lean-toolchain on the first `lake`/`lake build`,
# so the image stays small and version-agnostic while making `lake` usable
# headlessly (no VS Code extension required). After attaching, warm the
# Mathlib build cache with:
#   lake exe cache get
RUN set -a && . /tmp/versions.env && set +a && \
    ARCH=$(dpkg --print-architecture) && \
    case "$ARCH" in \
      amd64) ELAN_ARCH=x86_64-unknown-linux-gnu ;; \
      arm64) ELAN_ARCH=aarch64-unknown-linux-gnu ;; \
      *) echo "Unsupported arch: $ARCH" && exit 1 ;; \
    esac && \
    curl -fsSLo /tmp/elan.tar.gz "https://github.com/leanprover/elan/releases/download/v${ELAN_VERSION}/elan-${ELAN_ARCH}.tar.gz" && \
    tar -xzf /tmp/elan.tar.gz -C /tmp && \
    /tmp/elan-init -y --default-toolchain none --no-modify-path && \
    rm -f /tmp/elan.tar.gz /tmp/elan-init /tmp/versions.env

# ----- Claude Code CLI (user-local) -----
# Installed AFTER the USER switch so the binary lands in /home/dev/.local/bin
# (readable by dev) rather than /root/.local/bin.
RUN curl -fsSL https://claude.ai/install.sh | bash

# Workspace
WORKDIR /home/dev/app

# Keep the devcontainer running so VS Code can attach.
CMD ["sleep", "infinity"]
