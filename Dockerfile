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

# ttyd (web terminal with OSC52 clipboard support)
RUN curl -fsSL -o /usr/local/bin/ttyd https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.x86_64 \
    && chmod +x /usr/local/bin/ttyd

# Create user
RUN groupadd -g 2000 workspace_users 2>/dev/null || true && \
    useradd -u 1003 -g 2000 -m -s /bin/bash mimo

# MiMo-Code CLI
RUN npm install -g @mimo-ai/cli @mimo-ai/mimocode-linux-x64

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
