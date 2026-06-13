FROM ubuntu:24.04
USER root

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# System packages
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    build-essential \
    curl \
    git \
    nano \
    vim \
    procps \
    lsof \
    ffmpeg \
    jq \
    ripgrep \
    fd-find \
    sqlite3 \
    unzip \
    zip \
    wget \
    rsync \
    docker.io \
    dumb-init \
    locales \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# code-server (VS Code in browser)
RUN curl -fsSL https://code-server.dev/install.sh | sh

# symlink code -> code-server (mimo может вызывать `code`)
RUN ln -sf /usr/bin/code-server /usr/local/bin/code

# Create user
RUN groupadd -g 2000 workspace_users 2>/dev/null || true && \
    useradd -u 1003 -g 2000 -m -s /bin/bash mimo

# MiMo-Code CLI
RUN npm install -g @mimo-ai/cli @mimo-ai/mimocode-linux-x64

# code-server settings
USER mimo
RUN mkdir -p /home/mimo/.local/share/code-server/User
COPY --chown=mimo:workspace_users code-server-settings.json /home/mimo/.local/share/code-server/User/settings.json

# Git defaults
RUN git config --global user.name "MiMo User" \
    && git config --global user.email "user@mimo.local" \
    && git config --global init.defaultBranch main

USER root

# Auth gateway + login page
COPY --chown=mimo:workspace_users auth-gateway.py /home/mimo/auth-gateway.py
COPY --chown=mimo:workspace_users login.html /home/mimo/login.html

# Entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Port 8080 = auth gateway (single entry point)
EXPOSE 8080

ENV PASSWORD=""

WORKDIR /workspace
ENTRYPOINT ["dumb-init", "--", "/entrypoint.sh"]
