#!/bin/bash
set -e
cd "$(dirname "$0")/.."

NAME="chk-$(date +%s)-$RANDOM"
APP_PORT=$(( RANDOM % 6767 + 1067 ))
export APP_PORT
URL="http://127.0.0.1:$APP_PORT"
N=6
STAGE="begin"

cleanup() {
    rc=$?
    trap - EXIT INT TERM
    if [ $rc -ne 0 ]; then
        echo "[FAIL stage=$STAGE] rc=$rc"
    fi
    docker compose -p "$NAME" -f docker-compose.yaml down -v || true
    exit $rc
}
trap cleanup EXIT INT TERM

fail() { echo "  detail: $*"; exit 1; }

request() {
    out=$(curl -fsS --max-time 5 -X "$1" -w $'\n%{http_code}' "$URL$2") || true
    if [ -z "$out" ]; then
        CODE="000"
        BODY=""
        return
    fi
    CODE=$(echo "$out" | tail -n 1)
    BODY=$(echo "$out" | sed '$d')
}

wait_for() {
    local end=$((SECONDS + $4))
    while [ $SECONDS -lt $end ]; do
        request "$1" "$2"
        [ "$CODE" = "$3" ] && return 0
        sleep 1
    done
    fail "timeout: $1 $2 - $CODE, ждали $3"
}

check_counter() {
    request GET /
    [ "$CODE" = "200" ] || fail "GET / - $CODE"
    local got
    got=$(echo "$BODY" | sed -n 's/.*"count": *\([0-9]*\).*/\1/p')
    [ "$got" = "$1" ] || fail "counter=$got, ждали $1"
}

STAGE="docker up"
echo "$STAGE"
docker compose -p "$NAME" -f docker-compose.yaml up -d --build
wait_for GET /readyz 200 30

STAGE="count N"
echo "$STAGE"
check_counter 0
i=0
while [ $i -lt $N ]; do
    request POST /increment
    [ "$CODE" = "200" ] || fail "POST /increment - $CODE"
    i=$((i + 1))
done
check_counter "$N"

STAGE="recreate app"
echo "$STAGE"
docker compose -p "$NAME" -f docker-compose.yaml up -d --no-deps --force-recreate app
wait_for GET /readyz 200 30
check_counter "$N"

STAGE="stop redis"
echo "$STAGE"
docker compose -p "$NAME" -f docker-compose.yaml stop redis
wait_for GET  /healthz   200 30
wait_for GET  /readyz    503 30
wait_for POST /increment 503 30

STAGE="start redis"
echo "$STAGE"
docker compose -p "$NAME" -f docker-compose.yaml start redis
wait_for GET /readyz 200 30
check_counter "$N"
request POST /increment
[ "$CODE" = "200" ] || fail "POST /increment после start redis - $CODE"
check_counter "$((N + 1))"

STAGE="backup"
echo "$STAGE"
docker compose -p "$NAME" -f docker-compose.yaml stop app redis
mkdir -p backups
docker compose -p "$NAME" -f docker-compose.yaml cp -a redis:/data "./backups/redis-${NAME}"

echo OK