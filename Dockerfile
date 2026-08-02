# =============================================================================
# Django application container image
# =============================================================================
# This multi-stage build keeps the image lean while preserving the application
# behavior for local testing and future deployment environments.
# =============================================================================

# Stage 1: dependency build
FROM python:3.9-slim AS builder

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    default-libmysqlclient-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Stage 2: runtime image
FROM python:3.9-slim AS production

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    DJANGO_SETTINGS_MODULE=employee_management_system.settings \
    PATH="/opt/venv/bin:$PATH"

RUN apt-get update && apt-get install -y --no-install-recommends \
    default-mysql-client \
    libmariadb3 \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Create a dedicated non-root user for improved container security.
RUN groupadd -r django && useradd -r -g django django

COPY --from=builder /opt/venv /opt/venv

WORKDIR /usr/src/app
COPY --chown=django:django . .

RUN mkdir -p /usr/src/app/static /usr/src/app/media /usr/src/app/logs \
    && chown -R django:django /usr/src/app

USER django

# Collect static assets using the Django project settings.
RUN python manage.py collectstatic --noinput --clear

# Health check for container orchestration.
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8000/hello/ || exit 1

EXPOSE 8000

# Production WSGI entry point.
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "3", "--timeout", "120", "--access-logfile", "-", "--error-logfile", "-", "employee_management_system.wsgi:application"]

