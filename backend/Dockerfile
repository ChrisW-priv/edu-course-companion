# This Dockerfile will build backend for app assuming the build context is the root of project directory
FROM ghcr.io/astral-sh/uv@sha256:0a5c60f84655a2d331b5280955abb0104dbea7188d7bb4749bbb13a1bbd90119 AS base

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    UV_COMPILE_BYTECODE=1 \
    UV_PYTHON_PREFERENCE='only-system'

COPY pyproject.toml .

RUN uv sync --no-dev

FROM python:3.13-slim@sha256:f41a75c9cee9391c09e0139f7b49d4b1fbb119944ec740ecce4040626dc07bed AS default-service-target

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

COPY --from=base /app /app

WORKDIR /app/backend

COPY backend/ /app/backend

RUN chmod +x ./entrypoint.sh

ENTRYPOINT ["/app/backend/entrypoint.sh", "run_asgi"]
