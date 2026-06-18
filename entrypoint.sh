#!/bin/bash
set -e

# Match docker.sock GID to host
if [ -S /var/run/docker.sock ]; then
    HOST_DOCKER_GID=$(stat -c '%g' /var/run/docker.sock)
    if ! getent group "$HOST_DOCKER_GID" >/dev/null; then
        groupadd -g "$HOST_DOCKER_GID" dockerhost
    fi
    usermod -aG "$HOST_DOCKER_GID" mimo
fi

# Initialize course directory from image if volume is empty (first run)
if [ -d /home/mimo/.course-image ] && [ ! -f /home/mimo/course/.initialized ]; then
    cp -a /home/mimo/.course-image/. /home/mimo/course/
    touch /home/mimo/course/.initialized
fi

# Virtual framebuffer for MiMo clipboard (xclip needs DISPLAY)
Xvfb :99 -screen 0 1024x768x24 > /dev/null 2>&1 &
export DISPLAY=:99.0

# Prepare MiMo home (persisted via volume)
mkdir -p /home/mimo/.mimocode
chown -R 1003:2000 /home/mimo/.mimocode
chmod -R g+rwX /home/mimo/.mimocode

# Write banner and env ONCE (guard against duplicate appends on restart)
if ! grep -q "MIMOCODE_HOME" /home/mimo/.bashrc 2>/dev/null; then
    cat >> /home/mimo/.bashrc << 'BANNER'

export MIMOCODE_HOME=/home/mimo/.mimocode
export DISPLAY=:99.0

echo ""
echo -e "\033[1;33m  MiMo-Code: AI Coding Assistant by Xiaomi\033[0m"
echo -e "\033[0;37m  ─────────────────────────────────────────\033[0m"
echo -e "  Запустить MiMo-Code:  \033[1;32mmimo\033[0m"
echo -e "  Первое демо:          \033[0;33mcd sessions/01-setup/demo/financial-dashboard\033[0m"
echo -e "  Терминал (копирование):  \033[0;33m/tty/\033[0m в адресной строке"
echo -e "  Файловый менеджер:    \033[0;33m/files/\033[0m в адресной строке"
echo ""
BANNER
fi

# Start ttyd in background (web terminal with clipboard support)
su mimo -c "ttyd \
    --port 7681 \
    --interface 127.0.0.1 \
    --base-path /tty \
    -W \
    bash -c 'cd ~/course && exec bash -l'" > /tmp/ttyd.log 2>&1 &

# Start File Browser in background
FB_DB="/home/mimo/.config/filebrowser/filebrowser.db"
filebrowser --database "$FB_DB" > /tmp/filebrowser.log 2>&1 &

# Replace code-server favicon with MiMo orange icon
CS_MEDIA=$(find /usr/lib/code-server -path "*/media/favicon*" -type f 2>/dev/null | head -1)
if [ -n "$CS_MEDIA" ]; then
    CS_MEDIA_DIR=$(dirname "$CS_MEDIA")
    cp /home/mimo/favicon.svg "$CS_MEDIA_DIR/favicon.svg" 2>/dev/null || true
    cp /home/mimo/favicon.svg "$CS_MEDIA_DIR/favicon-dark-support.svg" 2>/dev/null || true
fi

# Start code-server in background (internal, no auth — gateway handles auth)
su mimo -c "code-server \
    --bind-addr 127.0.0.1:8081 \
    --auth none \
    --disable-telemetry \
    --app-name 'MiMo-Code' \
    /home/mimo/course" > /tmp/code-server.log 2>&1 &

# Start auth gateway (single entry point on :8080)
exec python3 /home/mimo/auth-gateway.py
