# MiMo-Code: суперсила для НЕпрограммистов

Добро пожаловать на курс! Здесь собраны все материалы для практической работы.

## Структура

| Папка | Сессия | Тема |
|-------|--------|------|
| `sessions/01-setup/demo/` | 1 | Установка и первые задачи |
| `sessions/02-context-skills/demo/` | 2 | Контекст и навыки |
| `sessions/03-mcp/demo/` | 3 | Внешние сервисы (MCP) |
| `sessions/04-agents/demo/` | 4 | Агенты и подагенты |
| `sessions/05-agent-teams/demo/` | 5 | Команды агентов |

## Как начать

1. Откройте терминал (Ctrl+` или Terminal > New Terminal)
2. Перейдите в папку демо:
   ```
   cd sessions/01-setup/demo/financial-dashboard
   ```
3. Запустите MiMo-Code:
   ```
   claude
   ```

## Полезные команды

| Команда | Описание |
|---------|----------|
| `mimo` | Запустить MiMo-Code |
| `cd sessions/01-setup/demo/...` | Перейти к демо |
| `cd ~/course` | Вернуться в корень |
| `~/switch-api-key.sh [primary\|backup]` | Переключить API-ключ |
| `~/switch-model.sh cloud` | Переключить на облако (Z.AI, по умолчанию) |
| `~/switch-model.sh local` | Переключить на локальную модель (Ollama) |
| `~/switch-model.sh` | Показать текущий режим |
| `source ~/.mimocode/.env && claude` | Применить переключение и запустить |

## Режимы работы

По умолчанию после запуска контейнера MiMo-Code работает через **облако** (Z.AI, GLM-модели).

### Переключение на локальную модель (Ollama)

```bash
~/switch-model.sh local
source ~/.mimocode/.env && claude
```

### Переключение обратно на облако

```bash
~/switch-model.sh cloud
source ~/.mimocode/.env && claude
```

### Проверить текущий режим

```bash
~/switch-model.sh
```

> `source ~/.mimocode/.env` нужен чтобы текущий терминал подхватил новые настройки без перезапуска. Новые терминалы подхватывают изменения автоматически.
