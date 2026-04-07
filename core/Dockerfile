FROM python:3.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    DB_ENGINE=sqlite

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        default-libmysqlclient-dev \
        pkg-config \
    && rm -rf /var/lib/apt/lists/*

COPY manage.py /app/
COPY core /app/core
COPY main /app/main

RUN python -m pip install --upgrade pip \
    && python -m pip install --no-cache-dir \
        Django==5.2.12 \
        Pillow==12.1.1 \
        mysqlclient==2.2.7

EXPOSE 8000

CMD ["sh", "-c", "python manage.py migrate --noinput && python manage.py runserver 0.0.0.0:8000 --noreload"]
