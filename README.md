# MiMo-Code: Dev Container

Docker-контейнер с [MiMo-Code](https://github.com/XiaomiMiMo/MiMo-Code) — терминальным AI-ассистентом для кодинга от Xiaomi. Доступ через браузер по ttyd (веб-терминал).

## Что внутри

- **MiMo-Code CLI** (`mimo`) — AI-ассистент с агентами build/plan/compose, памятью между сессиями и поддержкой любых LLM-провайдеров.
- **MiMo Auto** — бесплатная модель от Xiaomi (настраивается при первом запуске).
- **ttyd** — веб-терминал в браузере (порт 7682).
- **Docker-in-Docker** — доступ к Docker daemon хоста через docker.sock.
- **Node.js 22, Python 3, build-essential** — базовый набор для разработки.

## Архитектура

```
Браузер → :7682 (ttyd) → bash → mimo CLI
                                    ├─ build  (агент по умолчанию, полные права)
                                    ├─ plan   (read-only анализ)
                                    └─ compose (разработка по спецификациям)
```

## Быстрый старт

### 1. Клонировать

```bash
git clone https://github.com/tdiz/mimo-dev-container.git
cd mimo-dev-container
cp .env.example .env
```

### 2. Собрать и запустить

```bash
docker compose -f docker-compose.mimocode.yml up --build -d
```

### 3. Открыть в браузере

```
http://localhost:7682
```

При первом запуске MiMo предложит интерактивную настройку (выбор провайдера, модели).

## Управление

```bash
# Остановить
docker compose -f docker-compose.mimocode.yml down

# Логи
docker compose -f docker-compose.mimocode.yml logs -f

# Пересобрать
docker compose -f docker-compose.mimocode.yml up --build -d
```

## Тома

| Том | Назначение |
|-----|-----------|
| `~/workspace` | Рабочая директория (общая с хостом) |
| `~/mimocode/home` | Конфиг и память MiMo (`.mimocode/`) |
| `~/` | Домашняя директория хоста (read-only в `/home/user/host_home`) |
| `docker.sock` | Доступ к Docker daemon хоста |

## Сеть

Контейнер подключён к внешней сети `localai_default`. Создать её, если не существует:

```bash
docker network create localai_default
```

## Лицензия

MIT
