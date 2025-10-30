# PostgreSQL Database Plugin

PostgreSQL relational database plugin for ARFNI.

## Overview

This plugin provides PostgreSQL database service for your ARFNI stacks. PostgreSQL is a powerful, open-source object-relational database system with a strong reputation for reliability, data integrity, and correctness.

## Features

- Multiple PostgreSQL versions (13, 14, 15, 16)
- Persistent data storage
- Health checks
- Connection verification
- Production-ready configuration

## Installation

```bash
# CLI
arfni plugin install postgresql

# Or from GitHub
arfni plugin install https://github.com/Arfni/arfni-plugins/tree/main/plugins/database/postgresql
```

## Usage

### In GUI Canvas

1. Open ARFNI GUI
2. Navigate to NodePalette
3. Go to **Database** category
4. Drag **PostgreSQL** node to canvas
5. Connect it to your application node (e.g., Django)
6. Configure connection in application:
   - Use service name: `postgres`
   - Port: `5432`
   - Database name, username, password from configuration

### Configuration

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `postgres_version` | select | `15` | PostgreSQL version (13, 14, 15, 16) |
| `db_name` | text | `myapp` | Database name |
| `db_user` | text | `postgres` | Database username |
| `db_password` | secret | - | Database password (required) |
| `db_port` | number | `5432` | PostgreSQL port |
| `enable_backup` | boolean | `false` | Enable automatic backups |

### Connection URL

When connected to your application, the following environment variable is automatically set:

```
DATABASE_URL=postgresql://{{db_user}}:{{db_password}}@postgres:5432/{{db_name}}
```

## Examples

### With Django

```yaml
# Generated stack.yaml
services:
  django:
    kind: docker.container
    environment:
      DATABASE_URL: "postgresql://postgres:password@postgres:5432/myapp"
    depends_on:
      - postgres

  postgres:
    kind: db.postgres
    spec:
      image: postgres:15-alpine
      environment:
        POSTGRES_DB: myapp
        POSTGRES_USER: postgres
        POSTGRES_PASSWORD: password
```

### With FastAPI

```python
# FastAPI app
from sqlalchemy import create_engine
import os

DATABASE_URL = os.getenv("DATABASE_URL")
engine = create_engine(DATABASE_URL)
```

## Volumes

- `postgres_data` - Persistent PostgreSQL data directory (`/var/lib/postgresql/data`)

## Health Checks

The plugin includes automatic health checks:
- **TCP Check**: Verifies PostgreSQL port (5432) is accessible
- **Connection Verification**: Tests database connection after deployment

## Troubleshooting

### Connection Refused

If you get "connection refused" errors:

1. Ensure PostgreSQL container is running:
   ```bash
   docker compose ps postgres
   ```

2. Check logs:
   ```bash
   docker compose logs postgres
   ```

3. Verify port mapping:
   ```bash
   docker compose port postgres 5432
   ```

### Permission Denied

If you get permission errors with volumes:

```bash
# Fix volume permissions
docker compose exec postgres chown -R postgres:postgres /var/lib/postgresql/data
```

### Data Persistence

Data is stored in Docker volume `postgres_data`. To backup:

```bash
# Create backup
docker compose exec -T postgres pg_dump -U postgres myapp > backup.sql

# Restore backup
cat backup.sql | docker compose exec -T postgres psql -U postgres myapp
```

## Requirements

- Docker 20.10+
- ARFNI 0.2.0+

## Service Kind

`db.postgres`

## Version History

- **1.0.0** (2024-01-15): Initial release

## License

MIT License

## Support

- [GitHub Issues](https://github.com/Arfni/arfni-plugins/issues)
- [Documentation](https://github.com/Arfni/arfni-plugins/tree/main/plugins/database/postgresql)

## Related Plugins

- [MySQL](../mysql/) - MySQL database
- [MongoDB](../mongodb/) - NoSQL document database
- [Redis](../../cache/redis/) - In-memory cache
