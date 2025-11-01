#!/bin/bash
# Django superuser creation hook
# Runs after deployment to create initial admin user

set -e

echo "👤 Creating Django superuser..."

# Check if Django service exists
if ! docker compose ps django &> /dev/null; then
    echo "⚠️  Django service not found, skipping superuser creation"
    exit 0
fi

# Check if superuser already exists
echo "🔍 Checking if superuser already exists..."
SUPERUSER_EXISTS=$(docker compose exec -T django python manage.py shell -c "from django.contrib.auth import get_user_model; User = get_user_model(); print(User.objects.filter(is_superuser=True).exists())" 2>/dev/null || echo "False")

if [ "$SUPERUSER_EXISTS" = "True" ]; then
    echo "✅ Superuser already exists, skipping creation"
    exit 0
fi

# Create superuser using environment variables
echo "📝 Creating superuser..."

# Check for required environment variables
if [ -z "$DJANGO_SUPERUSER_USERNAME" ]; then
    echo "⚠️  DJANGO_SUPERUSER_USERNAME not set, using default: admin"
    export DJANGO_SUPERUSER_USERNAME="admin"
fi

if [ -z "$DJANGO_SUPERUSER_EMAIL" ]; then
    echo "⚠️  DJANGO_SUPERUSER_EMAIL not set, using default: admin@localhost"
    export DJANGO_SUPERUSER_EMAIL="admin@localhost"
fi

if [ -z "$DJANGO_SUPERUSER_PASSWORD" ]; then
    echo "⚠️  DJANGO_SUPERUSER_PASSWORD not set, generating random password"
    export DJANGO_SUPERUSER_PASSWORD=$(openssl rand -base64 12)
    echo "📝 Generated password: $DJANGO_SUPERUSER_PASSWORD"
    echo "⚠️  Please save this password!"
fi

# Create superuser
docker compose exec -T django python manage.py createsuperuser --noinput

if [ $? -eq 0 ]; then
    echo "✅ Superuser created successfully"
    echo "   Username: $DJANGO_SUPERUSER_USERNAME"
    echo "   Email: $DJANGO_SUPERUSER_EMAIL"
    if [ -n "$DJANGO_SUPERUSER_PASSWORD" ]; then
        echo "   Password: (set via environment variable)"
    fi
else
    echo "❌ Superuser creation failed"
    exit 1
fi

echo "✅ Superuser creation hook completed"
exit 0
