#!/bin/bash
set -e

# подгоняем GID docker.sock под хостовый
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

exec su mimo -c "ttyd -W -p 7681 bash -lc 'cd /workspace && mimo'"
