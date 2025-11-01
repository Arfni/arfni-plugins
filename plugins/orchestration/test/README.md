# Django Framework Plugin

Production-ready Django deployment with PostgreSQL, Redis, and automated migrations.

## Features

- 🐍 Python 3.9-3.12 support
- 🗄️ PostgreSQL database integration
- 🚀 Redis cache support (optional)
- 🔒 Security best practices (non-root user, secrets management)
- 📦 Multi-stage Docker builds
- 🔄 Automatic database migrations
- 📊 Health checks
- 🎨 Static file collection
- ⚡ Gunicorn WSGI server with configurable workers
- 👤 Automatic superuser creation

## Installation

### Using ARFNI CLI
```bash
arfni plugin install django
```

### Using ARFNI GUI
1. Settings > Plugins
2. Enter "django" in the install box
3. Click Install

## Usage

### Quick Start

1. **Create Django project:**
```bash
django-admin startproject myproject
cd myproject
```

2. **Initialize ARFNI:**
```bash
arfni init
```

3. **Configure stack.yaml:**
```yaml
apiVersion: v0.1
name: my-django-app

targets:
  local:
    type: docker-desktop

services:
  api:
    kind: docker.container
    target: local
    spec:
      build: .
      ports: ["8000:8000"]
      env:
        SECRET_KEY: ${DJANGO_SECRET_KEY}
        DATABASE_URL: postgresql://postgres:${POSTGRES_PASSWORD}@postgres:5432/mydb
```

4. **Set environment variables:**
```bash
# .env
DJANGO_SECRET_KEY=your-secret-key-here
POSTGRES_PASSWORD=your-postgres-password
```

5. **Deploy:**
```bash
arfni apply
```

Your Django app will be available at `http://localhost:8000`

## Configuration

### Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DJANGO_SECRET_KEY` | Yes | - | Django secret key for cryptographic signing |
| `POSTGRES_PASSWORD` | Yes | - | PostgreSQL database password |
| `DJANGO_SUPERUSER_USERNAME` | No | `admin` | Admin username |
| `DJANGO_SUPERUSER_EMAIL` | No | `admin@localhost` | Admin email |
| `DJANGO_SUPERUSER_PASSWORD` | No | auto-generated | Admin password |

### Plugin Inputs

Configure via `plugin.yaml` or ARFNI GUI:

```yaml
inputs:
  python_version: "3.11"
  django_port: 8000
  postgres_db: "mydb"
  enable_redis: true
  debug_mode: false
  gunicorn_workers: 4
```

## Services

This plugin adds three services to your stack:

### Django Service
- **Image**: Custom built from your Django project
- **Port**: 8000 (configurable)
- **Health Check**: HTTP GET `/health/`
- **Volumes**: `./media`, `./static`
- **Dependencies**: PostgreSQL, Redis (optional)

### PostgreSQL Service
- **Image**: `postgres:15-alpine`
- **Port**: 5432
- **Volume**: `postgres-data` (persistent)
- **Health Check**: TCP port 5432

### Redis Service (Optional)
- **Image**: `redis:7-alpine`
- **Port**: 6379
- **Volume**: `redis-data` (persistent)
- **Health Check**: TCP port 6379

## Lifecycle Hooks

The plugin executes hooks at different stages:

### 1. Pre-Generate: `validate-project.sh`
- Validates Django project structure
- Checks for required files (`manage.py`, `requirements.txt`)

### 2. Post-Build: `collect-static.sh`
- Collects Django static files
- Prepares assets for production

### 3. Pre-Deploy: `migrate-database.sh`
- Waits for PostgreSQL to be ready
- Runs Django database migrations
- Shows migration status

### 4. Post-Deploy: `create-superuser.sh`
- Creates Django superuser if needed
- Uses `DJANGO_SUPERUSER_*` environment variables
- Generates random password if not provided

### 5. Health Check: `health-check.sh`
- Verifies Django application health
- Checks database connectivity
- Validates Redis connection (if enabled)
- Reports unapplied migrations

## Project Requirements

Your Django project must have:

- ✅ `manage.py` - Django management script
- ✅ `requirements.txt` - Python dependencies
- ✅ `settings.py` - Django settings
- ✅ `wsgi.py` or `asgi.py` - WSGI/ASGI application

### Recommended requirements.txt

```txt
Django>=4.2,<5.0
psycopg2-binary>=2.9
gunicorn>=20.1
python-dotenv>=1.0
redis>=4.5  # if using Redis
```

## Examples

### Example 1: Basic Django App

```yaml
# stack.yaml
apiVersion: v0.1
name: django-blog

targets:
  local:
    type: docker-desktop

services:
  blog:
    kind: docker.container
    target: local
    spec:
      build: .
      ports: ["8000:8000"]
```

### Example 2: Django with PostgreSQL

```yaml
services:
  api:
    kind: docker.container
    spec:
      build: .
      ports: ["8000:8000"]
      env:
        DATABASE_URL: postgresql://postgres:${POSTGRES_PASSWORD}@postgres:5432/mydb

  postgres:
    kind: docker.container
    spec:
      image: postgres:15-alpine
      env:
        POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      volumes:
        - postgres-data:/var/lib/postgresql/data

volumes:
  - postgres-data
```

### Example 3: Full Production Stack

```yaml
services:
  api:
    kind: docker.container
    spec:
      build: .
      env:
        DEBUG: "False"
        DATABASE_URL: postgresql://postgres:${POSTGRES_PASSWORD}@postgres:5432/mydb
        REDIS_URL: redis://redis:6379/0
        ALLOWED_HOSTS: example.com,www.example.com

  postgres:
    kind: docker.container
    spec:
      image: postgres:15-alpine

  redis:
    kind: docker.container
    spec:
      image: redis:7-alpine

  nginx:
    kind: proxy.nginx  # Nginx plugin required
    spec:
      upstreams:
        - service: api
          port: 8000
      ssl:
        enabled: true
```

## Customization

### Custom Dockerfile

If you need a custom Dockerfile, create one in your project root. The plugin will detect it and skip generating a new one.

### Custom Settings

Create `settings_production.py` for production-specific settings:

```python
from .settings import *

DEBUG = False
ALLOWED_HOSTS = os.getenv('ALLOWED_HOSTS', '*').split(',')

# Database
DATABASES = {
    'default': dj_database_url.config(
        default=os.getenv('DATABASE_URL'),
        conn_max_age=600
    )
}

# Cache (Redis)
CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': os.getenv('REDIS_URL', 'redis://redis:6379/0'),
    }
}

# Static files
STATIC_ROOT = '/app/static/'
MEDIA_ROOT = '/app/media/'
```

### Custom Hooks

Override any hook by creating a script in your project:

```bash
# .arfni/hooks/pre-deploy.sh
#!/bin/bash
echo "Running custom pre-deploy hook"
python manage.py migrate
python manage.py loaddata initial_data.json
```

## Troubleshooting

### Database Connection Issues

**Problem**: Django can't connect to PostgreSQL

**Solution**:
1. Check PostgreSQL logs:
```bash
docker compose logs postgres
```

2. Verify environment variables:
```bash
docker compose config | grep DATABASE
```

3. Ensure PostgreSQL is ready before Django starts (handled by hooks)

### Migration Failures

**Problem**: Migrations fail during deployment

**Solution**:
1. Check Django logs:
```bash
docker compose logs django
```

2. Run migrations manually:
```bash
docker compose run --rm django python manage.py migrate --noinput
```

3. Check for migration conflicts:
```bash
docker compose run --rm django python manage.py showmigrations
```

### Static Files Not Loading

**Problem**: CSS/JS files not loading

**Solution**:
1. Collect static files manually:
```bash
docker compose run --rm django python manage.py collectstatic --noinput
```

2. Check volume mounts:
```bash
docker compose exec django ls -la /app/static
```

3. Verify Nginx configuration (if using Nginx plugin)

### Permission Denied Errors

**Problem**: Permission errors when writing to volumes

**Solution**:
The Dockerfile creates a non-root `django` user (UID 1000). Ensure your local directories match:

```bash
sudo chown -R 1000:1000 ./media ./static
```

## Health Check Endpoint

Add a health check view to your Django project:

```python
# urls.py
from django.http import JsonResponse
from django.db import connection

def health_check(request):
    # Check database
    try:
        connection.ensure_connection()
        db_status = "healthy"
    except Exception as e:
        db_status = f"unhealthy: {str(e)}"

    return JsonResponse({
        "status": "healthy" if db_status == "healthy" else "unhealthy",
        "database": db_status,
    })

urlpatterns = [
    path('health/', health_check),
    # ... other URLs
]
```

## Performance Tuning

### Gunicorn Workers

Formula: `(2 * CPU_CORES) + 1`

```yaml
inputs:
  gunicorn_workers: 9  # For 4-core machine
```

### Database Connection Pooling

Add to `settings.py`:

```python
DATABASES = {
    'default': {
        # ... other settings
        'CONN_MAX_AGE': 600,  # 10 minutes
        'OPTIONS': {
            'connect_timeout': 10,
        }
    }
}
```

### Redis Caching

```python
CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': os.getenv('REDIS_URL'),
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
            'CONNECTION_POOL_KWARGS': {'max_connections': 50}
        }
    }
}
```

## Requirements

- **ARFNI**: >=0.2.0
- **Docker**: >=20.10
- **Docker Compose**: >=2.0
- **Python**: 3.9-3.12
- **Django**: >=3.2

## License

MIT License - see [LICENSE](../../../../LICENSE) file for details.

## Contributing

Contributions welcome! Please see [CONTRIBUTING.md](../../../../CONTRIBUTING.md).

## Support

- **Documentation**: https://docs.arfni.dev/plugins/django
- **Issues**: https://github.com/arfni/arfni-plugins/issues
- **Discussions**: https://github.com/arfni/arfni/discussions

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

---

**Made with ❤️ by the ARFNI Community**
