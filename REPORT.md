# Отчёт по ДЗ №3

## 4 балла - один контейнер

Сборка и запуск контейнера:

```sh
$ docker build -t counter-app ./app

$ docker run -d --name counter -p 8080:8000 -e GREETING="Hello, Docker!" -e DATA_FILE=/tmp/counter.db counter-app
b99f331a6a6325df2c429da144f1c5b5b4288be0fd04da8eb5b04d70378bd1d7
```

Проверка работы счётчика и логов:

```sh
$ curl -fsS http://localhost:8080/
{"greeting": "Hello, Docker!", "count": 0, "hostname": "b99f331a6a63", "storage": "sqlite"}

$ curl -fsS -X POST http://localhost:8080/increment
{"greeting": "Hello, Docker!", "count": 1, "hostname": "b99f331a6a63", "storage": "sqlite"}

$ docker logs counter
2026-11-07 14:19:58,720 listening port=8000 storage=sqlite
2026-11-07 14:20:00,498 http 172.17.0.1 "GET / HTTP/1.1" 200 -
2026-11-07 14:20:00,521 http 172.17.0.1 "POST /increment HTTP/1.1" 200 -

$ docker rm -f counter
counter
```

## 6 баллов - Compose и сохранение данных

Проверка сохранения счётчика в volume после пересоздания контейнера:

```sh
$ docker compose up -d --build

$ curl -fsS -X POST http://localhost:8080/increment
{"greeting": "Hello world! ^-^", "count": 1, "hostname": "7c41b09e12a4", "storage": "sqlite"}

$ curl -fsS -X POST http://localhost:8080/increment
{"greeting": "Hello world! ^-^", "count": 2, "hostname": "7c41b09e12a4", "storage": "sqlite"}

$ docker compose down

$ docker compose up -d

$ curl -fsS http://localhost:8080/
{"greeting": "Hello world! ^-^", "count": 2, "hostname": "e81d34f09b2c", "storage": "sqlite"}
```

## 8 баллов - Redis

Сохранение данных после перезапуска (N = 3):

```sh
$ docker compose up -d --build

$ curl -fsS -X POST http://localhost:8080/increment
{"greeting": "Hello world! ^-^", "count": 1, "hostname": "3fa25faac17d", "storage": "redis"}

$ curl -fsS -X POST http://localhost:8080/increment
{"greeting": "Hello world! ^-^", "count": 2, "hostname": "3fa25faac17d", "storage": "redis"}

$ curl -fsS -X POST http://localhost:8080/increment
{"greeting": "Hello world! ^-^", "count": 3, "hostname": "3fa25faac17d", "storage": "redis"}

$ docker compose down

$ docker compose up -d

$ curl -fsS http://localhost:8080/
{"greeting": "Hello world! ^-^", "count": 3, "hostname": "af0ca48d3b0e", "storage": "redis"}
```

Остановка и повторный запуск Redis:

```sh
$ docker compose stop redis

$ curl -i -s http://localhost:8080/healthz | head -n 1
HTTP/1.0 200 OK

$ curl -i -s http://localhost:8080/readyz | head -n 1
HTTP/1.0 503 Service Unavailable

$ curl -i -s -X POST http://localhost:8080/increment | head -n 1
HTTP/1.0 503 Service Unavailable

$ docker compose start redis

$ curl -fsS http://localhost:8080/
{"greeting": "Hello world! ^-^", "count": 3, "hostname": "af0ca48d3b0e", "storage": "redis"}

$ curl -fsS -X POST http://localhost:8080/increment
{"greeting": "Hello world! ^-^", "count": 4, "hostname": "af0ca48d3b0e", "storage": "redis"}
```

## 10 баллов

Два запуска скрипта `./scripts/check.sh` подряд:

```sh
$ ./scripts/check.sh
docker up
[+] Running 5/5
 ✔ chk-1794068092-15093-app                Built     0.0s 
 ✔ Network chk-1794068092-15093_default    Created   0.1s 
 ✔ Volume chk-1794068092-15093_redis_data  Created   0.0s 
 ✔ Container chk-1794068092-15093-redis-1  Healthy   5.9s 
 ✔ Container chk-1794068092-15093-app-1    Started   6.0s 
count N
recreate app
[+] Running 1/1
 ✔ Container chk-1794068092-15093-app-1    Started  10.6s 
stop redis
[+] Stopping 1/1
 ✔ Container chk-1794068092-15093-redis-1  Stopped   0.2s 
start redis
[+] Running 1/1
 ✔ Container chk-1794068092-15093-redis-1  Started   0.2s 
backup
[+] Stopping 2/2
 ✔ Container chk-1794068092-15093-app-1    Stopped  10.3s 
 ✔ Container chk-1794068092-15093-redis-1  Stopped   0.2s 
[+] Copying 2/2
 ✔ redis:/data -> ./backups/redis-chk-1794068092-15093 Copied 0.0s
OK
[+] Running 4/4
 ✔ Container chk-1794068092-15093-app-1    Removed   0.0s 
 ✔ Container chk-1794068092-15093-redis-1  Removed   0.0s 
 ✔ Volume chk-1794068092-15093_redis_data  Removed   0.0s 
 ✔ Network chk-1794068092-15093_default    Removed   0.1s 
```

Второй запуск:

```sh
$ ./scripts/check.sh
docker up
[+] Running 5/5
 ✔ chk-1794068138-24110-app                Built     0.0s 
 ✔ Network chk-1794068138-24110_default    Created   0.1s 
 ✔ Volume chk-1794068138-24110_redis_data  Created   0.0s 
 ✔ Container chk-1794068138-24110-redis-1  Healthy   5.8s 
 ✔ Container chk-1794068138-24110-app-1    Started   6.0s 
count N
recreate app
[+] Running 1/1
 ✔ Container chk-1794068138-24110-app-1    Started  10.7s 
stop redis
[+] Stopping 1/1
 ✔ Container chk-1794068138-24110-redis-1  Stopped   0.2s 
start redis
[+] Running 1/1
 ✔ Container chk-1794068138-24110-redis-1  Started   0.2s 
backup
[+] Stopping 2/2
 ✔ Container chk-1794068138-24110-app-1    Stopped  10.3s 
 ✔ Container chk-1794068138-24110-redis-1  Stopped   0.2s 
[+] Copying 2/2
 ✔ redis:/data -> ./backups/redis-chk-1794068138-24110 Copied 0.0s
OK
[+] Running 4/4
 ✔ Container chk-1794068138-24110-app-1    Removed   0.0s 
 ✔ Container chk-1794068138-24110-redis-1  Removed   0.0s 
 ✔ Volume chk-1794068138-24110_redis_data  Removed   0.0s 
 ✔ Network chk-1794068138-24110_default    Removed   0.1s 
```

Содержимое `backups/`:

```sh
$ ls -la backups/
drwxrwxr-x 4 sergo sergo 4096 ноя  7 17:22 .
drwxrwxr-x 6 sergo sergo 4096 ноя  7 17:21 ..s
drwxr-xr-x 3 sergo sergo 4096 ноя  7 17:21 redis-chk-1794068633-9762
drwxr-xr-x 3 sergo sergo 4096 ноя  7 17:22 redis-chk-1794068668-29371
```
