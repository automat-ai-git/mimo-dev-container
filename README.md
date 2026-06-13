# MiMo-Code: Dev Container

Docker-контейнер с [MiMo-Code](https://github.com/XiaomiMiMo/MiMo-Code) — терминальным AI-ассистентом для кодинга от Xiaomi. Доступ через браузер с авторизацией.

## Что внутри

Один контейнер, два сервиса за общим порталом входа:

```
Браузер → :7682 (auth-gateway.py)
              └─ /terminal/ → ttyd (веб-терминал с MiMo CLI)
```

### Что установлено

- **MiMo-Code CLI** (`mimo`) — AI-ассистент с агентами build/plan/compose, памятью между сессиями.
- **MiMo Auto** — бесплатная модель от Xiaomi (настраивается при первом запуске).
- **ttyd** — веб-терминал в браузере.
- **Docker-in-Docker** — доступ к Docker daemon хоста.
- **Node.js 22, Python 3, build-essential** — базовый набор для разработки.

### Архитектура

| Компонент | Порт | Описание |
|-----------|------|----------|
| auth-gateway.py | 7682 (внешний) → 8080 (внутренний) | Python-прокси с cookie-авторизацией |
| ttyd | 7681 (внутренний) | Веб-терминал, без собственной авторизации |

## Быстрый старт

### 1. Клонировать и настроить

```bash
git clone https://github.com/automat-ai-git/mimo-dev-container.git
cd mimo-dev-container
cp .env.example .env
```

Опционально — задать пароль в `.env`:

```env
PASSWORD=my-secret-password
```

### 2. Создать Docker-сеть (если не существует)

```bash
docker network create localai_default
```

### 3. Собрать и запустить

```bash
./run.sh
```

### 4. Открыть в браузере

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
| `~/` | Домашняя директория хоста |
| `docker.sock` | Доступ к Docker daemon хоста |

## Доступ к файлам MiMo снаружи контейнера

Внутри контейнера файлы создаются от пользователя `mimo` (UID 1003, GID 2000). Чтобы несколько пользователей хоста могли читать и писать в `~/mimocode/home`, добавьте их в группу `workspace_users`:

```bash
# Создать группу с GID 2000 на хосте (если не существует)
sudo groupadd -g 2000 workspace_users 2>/dev/null || true

# Добавить пользователей (замените на реальные имена)
sudo usermod -aG workspace_users user1
sudo usermod -aG workspace_users user2
```

После этого перелогиниться или выполнить `newgrp workspace_users`.

Контейнер при каждом старте выполняет `chmod -R g+rwX` на `.mimocode/`, поэтому новые файлы тоже будут доступны группе.

## Лицензия

MIT
