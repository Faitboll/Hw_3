FROM python:3.11-alpine

RUN apk add --no-cache curl

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

COPY --chown=appuser:appgroup . .

USER appuser

CMD ["python3", "app.py"]


