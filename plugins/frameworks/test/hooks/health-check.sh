#!/bin/bash
# Django health check hook
# Verifies Django application is running properly

set -e

echo "🏥 Running Django health check..."

# Configuration
DJANGO_HOST=${DJANGO_HOST:-localhost}
DJANGO_PORT=${DJANGO_PORT:-8000}
HEALTH_ENDPOINT=${HEALTH_ENDPOINT:-/health/}
MAX_RETRIES=30
RETRY_DELAY=2

# Check if Django service exists
if ! docker compose ps django &> /dev/null; then
    echo "⚠️  Django service not found"
    exit 1
fi

# Wait for Django to be ready
echo "⏳ Waiting for Django to be ready..."
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://$DJANGO_HOST:$DJANGO_PORT$HEALTH_ENDPOINT 2>/dev/null || echo "000")

    if [ "$HTTP_CODE" = "200" ]; then
        echo "✅ Django is healthy (HTTP $HTTP_CODE)"
        break
    else
        RETRY_COUNT=$((RETRY_COUNT+1))
        echo "   Waiting for Django... ($RETRY_COUNT/$MAX_RETRIES) [HTTP $HTTP_CODE]"
        if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then
            echo "❌ Django did not become healthy in time"
            echo "📋 Django logs:"
            docker compose logs --tail=20 django
            exit 1
        fi
        sleep $RETRY_DELAY
    fi
done

# Database connection check
echo "🔍 Checking database connection..."
DB_CHECK=$(docker compose exec -T django python manage.py shell -c "from django.db import connection; connection.ensure_connection(); print('OK')" 2>/dev/null || echo "FAIL")

if [ "$DB_CHECK" = "OK" ]; then
    echo "✅ Database connection is healthy"
else
    echo "❌ Database connection failed"
    exit 1
fi

# Redis connection check (if enabled)
if docker compose ps redis &> /dev/null; then
    echo "🔍 Checking Redis connection..."
    REDIS_CHECK=$(docker compose exec -T redis redis-cli ping 2>/dev/null || echo "FAIL")

    if [ "$REDIS_CHECK" = "PONG" ]; then
        echo "✅ Redis connection is healthy"
    else
        echo "⚠️  Redis connection failed"
    fi
fi

# Check Django migrations status
echo "🔍 Checking migrations status..."
UNAPPLIED=$(docker compose exec -T django python manage.py showmigrations --plan | grep -c "\[ \]" || echo "0")

if [ "$UNAPPLIED" -gt 0 ]; then
    echo "⚠️  Warning: $UNAPPLIED unapplied migrations found"
else
    echo "✅ All migrations are applied"
fi

# Final summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Django Health Check Passed"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌐 Application: http://$DJANGO_HOST:$DJANGO_PORT"
echo "⚕️  Health Endpoint: http://$DJANGO_HOST:$DJANGO_PORT$HEALTH_ENDPOINT"
echo "📊 Admin Panel: http://$DJANGO_HOST:$DJANGO_PORT/admin/"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

exit 0
