#!/bin/bash
# Django database migration hook
# Runs before deployment to ensure database schema is up-to-date

set -e

echo "🔄 Running Django database migrations..."

# Check if Django service exists
if ! docker compose ps django &> /dev/null; then
    echo "⚠️  Django service not found, skipping migrations"
    exit 0
fi

# Check if DATABASE_URL is set
if [ -z "$DATABASE_URL" ]; then
    echo "⚠️  DATABASE_URL is not set. Skipping migrations."
    echo "💡 Tip: Connect a database service in the canvas to enable automatic migrations."
    exit 0
fi

echo "✅ DATABASE_URL detected: ${DATABASE_URL%%@*}@***"  # Hide password

# Detect database type and wait for it to be ready
MAX_RETRIES=30
RETRY_COUNT=0

if [[ $DATABASE_URL == postgresql://* ]] || [[ $DATABASE_URL == postgres://* ]]; then
    echo "🔍 PostgreSQL database detected"

    # Extract service name from DATABASE_URL (e.g., postgres from postgresql://user:pass@postgres:5432/db)
    DB_SERVICE=$(echo $DATABASE_URL | sed -n 's/.*@\([^:]*\):.*/\1/p')

    if [ -n "$DB_SERVICE" ]; then
        echo "⏳ Waiting for $DB_SERVICE to be ready..."
        until docker compose exec -T $DB_SERVICE pg_isready 2>/dev/null; do
            RETRY_COUNT=$((RETRY_COUNT+1))
            if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
                echo "❌ $DB_SERVICE did not become ready in time"
                exit 1
            fi
            echo "   Waiting for $DB_SERVICE... ($RETRY_COUNT/$MAX_RETRIES)"
            sleep 1
        done
        echo "✅ $DB_SERVICE is ready"
    fi

elif [[ $DATABASE_URL == mysql://* ]]; then
    echo "🔍 MySQL database detected"

    DB_SERVICE=$(echo $DATABASE_URL | sed -n 's/.*@\([^:]*\):.*/\1/p')

    if [ -n "$DB_SERVICE" ]; then
        echo "⏳ Waiting for $DB_SERVICE to be ready..."
        until docker compose exec -T $DB_SERVICE mysqladmin ping -h localhost 2>/dev/null; do
            RETRY_COUNT=$((RETRY_COUNT+1))
            if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
                echo "❌ $DB_SERVICE did not become ready in time"
                exit 1
            fi
            echo "   Waiting for $DB_SERVICE... ($RETRY_COUNT/$MAX_RETRIES)"
            sleep 1
        done
        echo "✅ $DB_SERVICE is ready"
    fi

elif [[ $DATABASE_URL == sqlite://* ]] || [[ $DATABASE_URL == sqlite3://* ]]; then
    echo "🔍 SQLite database detected (no wait needed)"

else
    echo "⚠️  Unknown database type, proceeding with migrations..."
fi

# Run migrations
echo "📊 Applying Django migrations..."
docker compose run --rm django python manage.py migrate --noinput

# Check migration status
if [ $? -eq 0 ]; then
    echo "✅ Migrations applied successfully"
else
    echo "❌ Migration failed"
    exit 1
fi

# Show current migration status
echo "📋 Current migration status:"
docker compose run --rm django python manage.py showmigrations --list

echo "✅ Database migration hook completed"
exit 0
