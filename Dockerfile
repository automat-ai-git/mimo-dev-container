FROM ubuntu:24.04
USER root
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    build-essential \
    curl \
    git \
    nano \
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
    docker.io \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ttyd актуальной версии с поддержкой OSC52 clipboard
RUN curl -fsSL -o /usr/local/bin/ttyd https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.x86_64 \
    && chmod +x /usr/local/bin/ttyd

RUN groupadd -g 2000 workspace_users 2>/dev/null || true && \
    useradd -u 1003 -g 2000 -m -s /bin/bash mimo

RUN npm install -g @mimo-ai/cli @mimo-ai/mimocode-linux-x64

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /workspace
ENTRYPOINT ["/entrypoint.sh"]
