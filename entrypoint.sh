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

mkdir -p /home/mimo/.mimocode
chown -R 1003:2000 /home/mimo/.mimocode
chmod -R g+rwX /home/mimo/.mimocode

# Welcome banner
cat >> /home/mimo/.bashrc << 'BANNER'

echo ""
echo -e "\033[1;33m  MiMo-Code: AI Coding Assistant by Xiaomi\033[0m"
echo -e "\033[0;37m  ─────────────────────────────────────────\033[0m"
echo -e "  Запустить MiMo-Code:  \033[1;32mmimo\033[0m"
echo -e "  Рабочая директория:   \033[0;33m/workspace\033[0m"
echo ""
BANNER

# Start ttyd in background — auto-launches mimo on connect (as in working config)
su mimo -c "ttyd -W -p 7681 bash -lc 'cd /workspace && mimo'" &

# Start auth gateway (single entry point on :8080)
exec python3 /home/mimo/auth-gateway.py
