FROM ubuntu:24.04
USER root

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# System packages + LibreOffice (for docx/pptx/xlsx conversion) + FFmpeg (for GIF/video)
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    sudo \
    locales \
    python3-pip \
    jq \
    unzip \
    dumb-init \
    ffmpeg \
    libreoffice-writer \
    libreoffice-calc \
    libreoffice-impress \
    tmux \
    fonts-liberation \
    fonts-dejavu-core \
    pandoc \
    poppler-utils \
    qpdf \
    tesseract-ocr \
    tesseract-ocr-rus \
    docker.io \
    zip \
    netcat-openbsd \
    build-essential \
    nano \
    vim \
    rsync \
    procps \
    lsof \
    ripgrep \
    fd-find \
    sqlite3 \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/bin/python3 /usr/bin/python

# Node.js 22
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# code-server (VS Code in browser)
RUN curl -fsSL https://code-server.dev/install.sh | sh

# File Browser — lightweight web file manager
RUN curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash

# MiMo-Code CLI (OpenCode fork by Xiaomi)
RUN npm install -g @mimo-ai/cli @mimo-ai/mimocode-linux-x64

# npm packages for document generation
RUN npm install -g docx pptxgenjs parcel @parcel/config-default html-inline

# Python packages
RUN pip3 install --no-cache-dir --break-system-packages \
    pypdf \
    python-pptx \
    python-docx \
    openpyxl \
    pillow \
    numpy \
    pandas \
    matplotlib \
    cairosvg \
    requests \
    lxml \
    imageio \
    imageio-ffmpeg \
    pdfplumber \
    reportlab \
    pdf2image \
    "markitdown[pptx]" \
    pytesseract \
    playwright \
    defusedxml \
    PyYAML

# uv / uvx — Python package runner for MCP servers
RUN curl -LsSf https://astral.sh/uv/install.sh | UV_INSTALL_DIR=/usr/local/bin sh

# symlink code -> code-server
RUN ln -sf /usr/bin/code-server /usr/local/bin/code

# Create user
RUN groupadd -g 2000 workspace_users 2>/dev/null || true && \
    useradd -u 1003 -g 2000 -m -s /bin/bash -G sudo mimo \
    && echo "mimo ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/mimo
RUN usermod -aG docker mimo 2>/dev/null || true

USER mimo
WORKDIR /home/mimo

# Git defaults
RUN git config --global user.name "MiMo User" \
    && git config --global user.email "user@mimo.local" \
    && git config --global init.defaultBranch main

# VS Code extensions
RUN code-server --install-extension ms-vscode.live-server \
    && code-server --install-extension analytic-signal.preview-pdf \
    && code-server --install-extension GrapeCity.gc-excelviewer \
    && code-server --install-extension hediet.vscode-drawio \
    || true

# Playwright: install Chromium browser + system deps
RUN playwright install --with-deps chromium

# code-server settings
RUN mkdir -p /home/mimo/.local/share/code-server/User
COPY --chown=mimo:workspace_users code-server-settings.json /home/mimo/.local/share/code-server/User/settings.json

# Course materials: copy to .course-image (pristine) and course (working dir)
COPY --chown=mimo:workspace_users course/ /home/mimo/.course-image/
COPY --chown=mimo:workspace_users course/ /home/mimo/course/

# File Browser config
RUN mkdir -p /home/mimo/.config/filebrowser
RUN filebrowser config init --database /home/mimo/.config/filebrowser/filebrowser.db \
    --root /home/mimo/course \
    --address 127.0.0.1 \
    --port 9090 \
    --baseurl /files \
    --auth.method=noauth \
    --branding.name="MiMo-Code: Файлы курса" \
    && filebrowser users add admin admin-noauth-dummy --perm.admin --database /home/mimo/.config/filebrowser/filebrowser.db

USER root

# Auth gateway + login page
COPY --chown=mimo:workspace_users auth-gateway.py /home/mimo/auth-gateway.py
COPY --chown=mimo:workspace_users login.html /home/mimo/login.html

# Entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Chart.js offline (used by demos)
RUN mkdir -p /home/mimo/course/assets \
    && curl -fsSL https://cdn.jsdelivr.net/npm/chart.js@4/dist/chart.umd.min.js \
    -o /home/mimo/course/assets/chart.min.js || true

# Port 8080 = auth gateway (single entry point)
EXPOSE 8080

ENV NODE_PATH="/usr/lib/node_modules"
ENV PASSWORD=""
ENV MIMOCODE_HOME=/home/mimo/.mimocode

ENTRYPOINT ["dumb-init", "--", "/entrypoint.sh"]
