# ДЗ №3 по ИПР

Отчёт о проверках находится в файле [REPORT.md](./REPORT.md).

## Структура проекта

- `app/` - исходный код приложения, `Dockerfile` и `requirements.txt`
- `docker-compose.yaml` - описание сервисов `app` и `redis`, volume, `healthcheck` и лимитов
- `.env.example` - пример файла с переменными окружения
- `scripts/check.sh` - скрипт для автоматической проверки и бэкапа
- `REPORT.md` - отчёт с командами и логами проверок

## Настройка окружения

Перед запуском нужно скопировать `.env.example` в `.env`:

```sh
cp .env.example .env
```

Переменные в `.env`:
- `APP_PORT=8080` - внешний порт на хосте
- `PORT=8080` - внутренний порт приложения в контейнере
- `GREETING="Hello world! ^-^"` - текст приветствия в ответе
- `STORAGE=redis` - режим хранения (`sqlite` или `redis`)
- `REDIS_URL=redis://redis:6379/0` - адрес Redis внутри сети Compose

## Запуск

### Один контейнер
```sh
docker build -t counter-app ./app
docker run -d --name counter -p 8080:8000 -e GREETING="Hello, bobrik!" -e DATA_FILE=/tmp/counter.db counter-app

curl -fsS http://localhost:8080/
curl -fsS -X POST http://localhost:8080/increment
docker logs counter
docker rm -f counter
```

### Docker Compose
```sh
# запуск со сборкой образа
docker compose up -d --build

# остановка без удаления данных
docker compose down

# остановка с удалением volume
docker compose down -v
```

### Скрипт проверки
```sh
./scripts/check.sh
```