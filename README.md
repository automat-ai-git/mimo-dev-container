# MiMo-Code: контейнер рабочей среды курса

Docker-контейнер для курса с [MiMo-Code](https://github.com/XiaomiMiMo/MiMo-Code) — терминальным AI-ассистентом от Xiaomi. Каждый студент получает в браузере изолированную среду: VS Code, терминал с MiMo-Code CLI и файловый менеджер.

## Что внутри

Один контейнер, три сервиса за общим порталом входа:

```
Браузер → :7682 (auth-gateway.py)
              ├─ /ide/   → code-server (VS Code в браузере)
              │               └─ терминал → mimo CLI
              └─ /files/ → File Browser (файловый менеджер)
```

Студент логинится один раз и получает доступ ко всему.

### Что установлено

- **MiMo-Code CLI** (`mimo`) — основной инструмент курса.
- **MiMo Auto** — бесплатная модель от Xiaomi (настраивается при первом запуске).
- **19 Skills** — создание документов (DOCX, PPTX, XLSX, PDF), дизайн, автоматизация браузера и др.
- **LibreOffice** — конвертация офисных форматов.
- **Playwright + Chromium** — управление браузером из скриптов.
- **Pandoc, Tesseract OCR, FFmpeg** — конвертация и обработка файлов.
- **Python-библиотеки** — pandas, matplotlib, pdfplumber, reportlab, openpyxl и др.
- **28 демо-проектов** — готовые примеры по всем 5 сессиям курса.

### Архитектура

| Компонент | Порт | Описание |
|-----------|------|----------|
| auth-gateway.py | 7682 (внешний) → 8080 (внутренний) | Python-прокси с cookie-авторизацией, единая точка входа |
| code-server | 8081 (внутренний) | VS Code в браузере, без собственной авторизации |
| File Browser | 9090 (внутренний) | Файловый менеджер, noauth — авторизация через gateway |

## Быстрый старт

### 1. Клонировать и настроить

```bash
git clone https://github.com/automat-ai-git/mimo-dev-container.git
cd mimo-dev-container
cp .env.example .env
```

Узнать GID группы docker на вашем хосте и записать в `.env`:

```bash
stat -c '%g' /var/run/docker.sock
echo "DOCKER_GID=1001" >> .env
```

Опционально — задать пароль в `.env`:

```env
PASSWORD=my-secret-password
```

### 2. Создать Docker-сеть (если не существует)

```bash
docker network create localai_default
```

### 3. Сделать run.sh исполняемым, собрать и запустить

```bash
chmod +x run.sh
./run.sh
```

### 4. Открыть в браузере

```
http://localhost:7682
```

Откроется VS Code с материалами курса. В терминале (Ctrl+`) наберите `mimo` для запуска MiMo-Code.

## Управление

```bash
# Остановить
docker compose -f docker-compose.mimocode.yml down

# Остановить и удалить данные студента
docker compose -f docker-compose.mimocode.yml down -v

# Логи
docker compose -f docker-compose.mimocode.yml logs -f
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
sudo groupadd -g 2000 workspace_users 2>/dev/null || true
sudo usermod -aG workspace_users user1
sudo usermod -aG workspace_users user2
```

После этого перелогиниться или выполнить `newgrp workspace_users`.

## Лицензия

MIT
