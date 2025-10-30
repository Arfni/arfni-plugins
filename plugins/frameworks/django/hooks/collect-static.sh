#!/bin/bash
# Django static files collection hook
# Runs after build to collect all static files

set -e

echo "🎨 Collecting Django static files..."

# Check if Django service exists
if ! docker compose ps django &> /dev/null; then
    echo "⚠️  Django service not found, skipping static collection"
    exit 0
fi

# Collect static files
echo "📦 Running collectstatic..."
docker compose run --rm django python manage.py collectstatic --noinput --clear

# Check status
if [ $? -eq 0 ]; then
    echo "✅ Static files collected successfully"
else
    echo "❌ Static collection failed"
    exit 1
fi

# Show collected files info
echo "📊 Static files summary:"
docker compose run --rm django python manage.py collectstatic --noinput --dry-run | tail -5

echo "✅ Static collection hook completed"
exit 0
