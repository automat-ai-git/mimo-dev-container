#!/usr/bin/env bash
#
# run.sh — Собрать и запустить MiMo-Code контейнер
#
# После запуска:
#   Портал: http://localhost:7682
#
# Остановка:  docker compose -f docker-compose.mimocode.yml down

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Обновление репозитория ==="
git -C "$SCRIPT_DIR" pull || echo "⚠ git pull не удался, собираем текущую версию"

echo ""
echo "=== Сборка Docker-образа ==="
docker compose -f "$SCRIPT_DIR/docker-compose.mimocode.yml" build

echo ""
echo "=== Запуск ==="
docker compose -f "$SCRIPT_DIR/docker-compose.mimocode.yml" up -d

echo ""
echo "=== Готово! ==="
echo ""
echo "  Портал:   http://localhost:7682"

PW=$(grep '^PASSWORD=' "$SCRIPT_DIR/.env" 2>/dev/null | cut -d= -f2)
if [ -n "$PW" ]; then
    echo "  Пароль:   $PW"
else
    echo "  Пароль:   не установлен (открытый доступ)"
fi

echo ""
echo "  Остановка:    docker compose -f docker-compose.mimocode.yml down"
echo "  Логи:         docker compose -f docker-compose.mimocode.yml logs -f"
