# ARFNI Plugin Use Cases

This document provides real-world use cases and examples for ARFNI plugins across all four categories.

## Table of Contents

- [Framework Plugins](#framework-plugins)
  - [Django Full-Stack Application](#django-full-stack-application)
  - [React + Next.js Frontend](#react--nextjs-frontend)
  - [Spring Boot Microservice](#spring-boot-microservice)
- [Infrastructure Plugins](#infrastructure-plugins)
  - [Nginx Reverse Proxy](#nginx-reverse-proxy)
  - [PostgreSQL Database](#postgresql-database)
  - [Redis Cache Layer](#redis-cache-layer)
- [CI/CD Plugins](#cicd-plugins)
  - [Jenkins Pipeline](#jenkins-pipeline)
  - [GitLab CI Integration](#gitlab-ci-integration)
- [Orchestration Plugins](#orchestration-plugins)
  - [Kubernetes Deployment](#kubernetes-deployment)
  - [Docker Swarm Cluster](#docker-swarm-cluster)
- [Combined Use Cases](#combined-use-cases)
  - [Full Production Stack](#full-production-stack)
  - [Multi-Environment Setup](#multi-environment-setup)

---

## Framework Plugins

### Django Full-Stack Application

**Scenario**: Deploy a production-ready Django application with PostgreSQL database, Redis cache, and Nginx reverse proxy.

#### Installation

```bash
# Install Django plugin
arfni plugin install django

# Or via GUI
# Navigate to Plugins → Install → Search "django" → Install
```

#### Project Setup

```bash
# Navigate to Django project
cd my-django-project

# Initialize ARFNI
arfni init

# ARFNI detects Django automatically via:
# - manage.py file
# - requirements.txt with Django
# - Django app structure
```

#### Generated stack.yaml

```yaml
version: 1.0
project:
  name: my-django-project
  framework: django

services:
  django:
    kind: docker.container
    target: docker.local
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "8000:8000"
    environment:
      DJANGO_SECRET_KEY: ${DJANGO_SECRET_KEY}
      DJANGO_DEBUG: "false"
      DJANGO_ALLOWED_HOSTS: "localhost,127.0.0.1"
      DATABASE_URL: "postgresql://postgres:password@postgres:5432/myapp"
      REDIS_URL: "redis://redis:6379/0"
    volumes:
      - host: ./static
        mount: /app/static
      - host: ./media
        mount: /app/media
    depends_on:
      - postgres
      - redis

  postgres:
    kind: docker.container
    target: docker.local
    image: "postgres:15-alpine"
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - host: postgres_data
        mount: /var/lib/postgresql/data

  redis:
    kind: docker.container
    target: docker.local
    image: "redis:7-alpine"
    volumes:
      - host: redis_data
        mount: /data

volumes:
  - postgres_data
  - redis_data
```

#### Deployment Workflow

```bash
# 1. Build Docker images
arfni build

# 2. Run migrations (pre_deploy hook)
# Automatically executes: python manage.py migrate

# 3. Collect static files (post_build hook)
# Automatically executes: python manage.py collectstatic

# 4. Deploy
arfni deploy

# 5. Create superuser (post_deploy hook)
# Automatically creates admin user with env vars

# 6. Verify health
arfni health
# ✅ Django is healthy (200 OK)
# ✅ PostgreSQL is ready
# ✅ Redis is responding
```

#### Environment Variables

Create `.env` file:

```bash
# Django Configuration
DJANGO_SECRET_KEY=your-secret-key-here
DJANGO_DEBUG=false
DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1,yourdomain.com

# Database
POSTGRES_PASSWORD=secure-password

# Superuser
DJANGO_SUPERUSER_USERNAME=admin
DJANGO_SUPERUSER_EMAIL=admin@yourdomain.com
DJANGO_SUPERUSER_PASSWORD=admin-password
```

#### Access Application

```bash
# Application URL
http://localhost:8000

# Admin panel
http://localhost:8000/admin
# Username: admin
# Password: (from DJANGO_SUPERUSER_PASSWORD)
```

#### Plugin Customization

Modify plugin inputs in GUI or stack.yaml:

```yaml
# Change Python version
python_version: "3.12"

# Disable Redis
enable_redis: false

# Change port
django_port: 8080

# Enable Celery
enable_celery: true
```

---

### React + Next.js Frontend

**Scenario**: Deploy a Next.js application with server-side rendering.

#### Installation

```bash
arfni plugin install nextjs
```

#### Generated Configuration

```yaml
services:
  nextjs:
    kind: docker.container
    target: docker.local
    build:
      context: .
      dockerfile: Dockerfile
      args:
        NODE_VERSION: "20"
    ports:
      - "3000:3000"
    environment:
      NODE_ENV: production
      NEXT_PUBLIC_API_URL: http://api:8000
```

#### Multi-stage Dockerfile

```dockerfile
# Build stage
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

# Production stage
FROM node:20-alpine
WORKDIR /app
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001
COPY --from=builder --chown=nextjs:nodejs /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
USER nextjs
EXPOSE 3000
CMD ["npm", "start"]
```

---

### Spring Boot Microservice

**Scenario**: Deploy a Java Spring Boot microservice with MySQL database.

#### Installation

```bash
arfni plugin install spring-boot
```

#### Generated Configuration

```yaml
services:
  api:
    kind: docker.container
    target: docker.local
    build:
      context: .
      dockerfile: Dockerfile
      args:
        JAVA_VERSION: "17"
        GRADLE_VERSION: "8.5"
    ports:
      - "8080:8080"
    environment:
      SPRING_PROFILES_ACTIVE: production
      SPRING_DATASOURCE_URL: jdbc:mysql://mysql:3306/myapp
      SPRING_DATASOURCE_USERNAME: root
      SPRING_DATASOURCE_PASSWORD: ${MYSQL_ROOT_PASSWORD}
    depends_on:
      - mysql

  mysql:
    kind: docker.container
    target: docker.local
    image: "mysql:8.0"
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: myapp
    volumes:
      - host: mysql_data
        mount: /var/lib/mysql
```

---

## Infrastructure Plugins

### Nginx Reverse Proxy

**Scenario**: Add Nginx as a reverse proxy in front of multiple backend services.

#### Installation

```bash
arfni plugin install nginx
```

#### Configuration

```yaml
services:
  nginx:
    kind: proxy.nginx
    target: docker.local
    spec:
      upstreams:
        - service: django
          port: 8000
          path: /api
        - service: nextjs
          port: 3000
          path: /
      ssl:
        enabled: true
        cert_path: /etc/nginx/certs/cert.pem
        key_path: /etc/nginx/certs/key.pem
    ports:
      - "80:80"
      - "443:443"
```

#### Generated Nginx Config

```nginx
# Auto-generated by ARFNI nginx plugin

upstream django_backend {
    server django:8000;
}

upstream nextjs_backend {
    server nextjs:3000;
}

server {
    listen 80;
    server_name localhost;

    location /api {
        proxy_pass http://django_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location / {
        proxy_pass http://nextjs_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}

server {
    listen 443 ssl;
    server_name localhost;

    ssl_certificate /etc/nginx/certs/cert.pem;
    ssl_certificate_key /etc/nginx/certs/key.pem;

    location /api {
        proxy_pass http://django_backend;
    }

    location / {
        proxy_pass http://nextjs_backend;
    }
}
```

---

### PostgreSQL Database

**Scenario**: Add PostgreSQL database with automatic backup.

#### Installation

```bash
arfni plugin install postgresql
```

#### Configuration

```yaml
services:
  postgres:
    kind: db.postgres
    target: docker.local
    spec:
      version: "15"
      databases:
        - name: myapp_production
          user: app_user
          password: ${DB_PASSWORD}
      backup:
        enabled: true
        schedule: "0 2 * * *"  # Daily at 2 AM
        retention_days: 7
    volumes:
      - host: postgres_data
        mount: /var/lib/postgresql/data
      - host: postgres_backups
        mount: /backups
```

#### Hooks

**Post-deploy backup setup**:

```bash
#!/bin/bash
# hooks/setup-postgres-backup.sh

set -e

echo "🔄 Setting up PostgreSQL backups..."

# Create backup directory
docker compose exec postgres mkdir -p /backups

# Create backup script
cat > /tmp/backup.sh <<'EOF'
#!/bin/bash
BACKUP_FILE="/backups/backup_$(date +%Y%m%d_%H%M%S).sql"
pg_dump -U app_user myapp_production > "$BACKUP_FILE"
gzip "$BACKUP_FILE"
echo "✅ Backup created: $BACKUP_FILE.gz"

# Remove old backups (keep last 7 days)
find /backups -name "backup_*.sql.gz" -mtime +7 -delete
EOF

# Copy to container
docker compose cp /tmp/backup.sh postgres:/usr/local/bin/backup.sh
docker compose exec postgres chmod +x /usr/local/bin/backup.sh

# Setup cron job
echo "0 2 * * * /usr/local/bin/backup.sh" | docker compose exec -T postgres crontab -

echo "✅ PostgreSQL backup configured"
```

---

### Redis Cache Layer

**Scenario**: Add Redis for caching and session storage.

#### Installation

```bash
arfni plugin install redis
```

#### Configuration

```yaml
services:
  redis:
    kind: cache.redis
    target: docker.local
    spec:
      version: "7"
      mode: standalone  # or: cluster, sentinel
      max_memory: 256mb
      max_memory_policy: allkeys-lru
      persistence:
        enabled: true
        type: aof  # or: rdb
    ports:
      - "6379:6379"
```

#### Django Integration

```python
# settings.py

CACHES = {
    'default': {
        'BACKEND': 'django_redis.cache.RedisCache',
        'LOCATION': 'redis://redis:6379/1',
        'OPTIONS': {
            'CLIENT_CLASS': 'django_redis.client.DefaultClient',
        }
    }
}

# Session storage
SESSION_ENGINE = 'django.contrib.sessions.backends.cache'
SESSION_CACHE_ALIAS = 'default'
```

---

## CI/CD Plugins

### Jenkins Pipeline

**Scenario**: Automated CI/CD pipeline with Jenkins.

#### Installation

```bash
arfni plugin install jenkins
```

#### Configuration

```yaml
services:
  jenkins:
    kind: ci.jenkins
    target: docker.local
    spec:
      version: lts
      plugins:
        - git
        - docker-workflow
        - pipeline-stage-view
        - blue-ocean
      jobs:
        - name: build-and-deploy
          pipeline: Jenkinsfile
          triggers:
            - type: scm
              schedule: "H/5 * * * *"
```

#### Jenkinsfile

```groovy
pipeline {
    agent any

    environment {
        DOCKER_REGISTRY = 'myregistry.com'
        IMAGE_NAME = "${env.PROJECT_NAME}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Validate Stack') {
            steps {
                sh 'arfni validate'
            }
        }

        stage('Build') {
            steps {
                sh 'arfni build'
            }
        }

        stage('Test') {
            steps {
                sh 'arfni test'
            }
        }

        stage('Security Scan') {
            steps {
                sh 'trivy image ${IMAGE_NAME}:latest'
            }
        }

        stage('Deploy to Staging') {
            when {
                branch 'develop'
            }
            steps {
                sh 'arfni deploy --target staging'
            }
        }

        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                input message: 'Deploy to production?'
                sh 'arfni deploy --target production'
            }
        }

        stage('Health Check') {
            steps {
                sh 'arfni health'
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        success {
            echo '✅ Pipeline completed successfully'
        }
        failure {
            echo '❌ Pipeline failed'
        }
    }
}
```

#### Webhook Setup

```bash
# Configure GitHub webhook
# URL: http://jenkins:8080/github-webhook/
# Events: push, pull_request

# Configure Jenkins credentials
docker compose exec jenkins jenkins-cli install-plugin credentials-binding
```

---

### GitLab CI Integration

**Scenario**: GitLab CI/CD with automated deployments.

#### Installation

```bash
arfni plugin install gitlab-ci
```

#### Generated .gitlab-ci.yml

```yaml
stages:
  - validate
  - build
  - test
  - deploy

variables:
  DOCKER_DRIVER: overlay2

before_script:
  - arfni version

validate:
  stage: validate
  script:
    - arfni validate
  only:
    - branches

build:
  stage: build
  script:
    - arfni build
  artifacts:
    paths:
      - stack.yaml
      - docker-compose.generated.yaml
    expire_in: 1 week
  only:
    - branches

test:
  stage: test
  script:
    - arfni test
  only:
    - branches

deploy_staging:
  stage: deploy
  script:
    - arfni deploy --target staging
  environment:
    name: staging
    url: https://staging.myapp.com
  only:
    - develop

deploy_production:
  stage: deploy
  script:
    - arfni deploy --target production
  environment:
    name: production
    url: https://myapp.com
  when: manual
  only:
    - main
```

---

## Orchestration Plugins

### Kubernetes Deployment

**Scenario**: Deploy ARFNI stack to Kubernetes cluster.

#### Installation

```bash
arfni plugin install kubernetes
```

#### Configuration

```yaml
targets:
  - name: k8s-production
    type: k8s.cluster
    config:
      kubeconfig: ~/.kube/config
      namespace: production
      create_namespace: true
      replicas: 3
      ingress_class: nginx
      enable_hpa: true
      hpa_config:
        min_replicas: 3
        max_replicas: 10
        target_cpu_utilization: 70
```

#### Generated Kubernetes Manifests

**Deployment**:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: django
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: django
  template:
    metadata:
      labels:
        app: django
    spec:
      containers:
      - name: django
        image: myregistry.com/django:latest
        ports:
        - containerPort: 8000
        env:
        - name: DJANGO_SECRET_KEY
          valueFrom:
            secretKeyRef:
              name: django-secrets
              key: secret-key
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health/
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health/
            port: 8000
          initialDelaySeconds: 5
          periodSeconds: 5
```

**Service**:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: django
  namespace: production
spec:
  selector:
    app: django
  ports:
  - port: 80
    targetPort: 8000
  type: ClusterIP
```

**Ingress**:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: django-ingress
  namespace: production
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - myapp.com
    secretName: django-tls
  rules:
  - host: myapp.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: django
            port:
              number: 80
```

**HorizontalPodAutoscaler**:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: django-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: django
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

#### Deployment

```bash
# Deploy to Kubernetes
arfni deploy --target k8s-production

# Plugin executes:
# 1. Validate cluster access (pre_deploy hook)
# 2. Generate Kubernetes manifests
# 3. Apply manifests with kubectl
# 4. Wait for rollout (post_deploy hook)
# 5. Verify pod health (health_check hook)
```

#### Monitoring

```bash
# Check deployment status
kubectl get deployments -n production

# Check pod status
kubectl get pods -n production

# Check HPA status
kubectl get hpa -n production

# View logs
kubectl logs -f deployment/django -n production
```

---

### Docker Swarm Cluster

**Scenario**: Deploy to Docker Swarm for simple orchestration.

#### Installation

```bash
arfni plugin install docker-swarm
```

#### Configuration

```yaml
targets:
  - name: swarm-production
    type: swarm.cluster
    config:
      manager_node: manager1.example.com
      replicas: 5
      update_config:
        parallelism: 2
        delay: 10s
        failure_action: rollback
```

#### Generated Stack File

```yaml
version: '3.8'

services:
  django:
    image: myregistry.com/django:latest
    deploy:
      replicas: 5
      update_config:
        parallelism: 2
        delay: 10s
        failure_action: rollback
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
      placement:
        constraints:
          - node.role == worker
    networks:
      - app-network
    ports:
      - "8000:8000"

  postgres:
    image: postgres:15-alpine
    deploy:
      replicas: 1
      placement:
        constraints:
          - node.role == manager
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - app-network

networks:
  app-network:
    driver: overlay
    attachable: true

volumes:
  postgres_data:
    driver: local
```

#### Deployment

```bash
# Deploy to Swarm
arfni deploy --target swarm-production

# Plugin executes:
# docker stack deploy -c docker-compose.generated.yaml myapp
```

---

## Combined Use Cases

### Full Production Stack

**Scenario**: Complete production stack with all plugin types.

#### Stack Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Kubernetes Cluster                  │
│                                                       │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────┐ │
│  │   Nginx     │  │   Django     │  │  Next.js   │ │
│  │ (Ingress)   │→│ (Backend API)│  │ (Frontend) │ │
│  └─────────────┘  └──────────────┘  └────────────┘ │
│                           ↓                          │
│                    ┌──────────────┐                 │
│                    │  PostgreSQL  │                 │
│                    └──────────────┘                 │
│                           ↓                          │
│                    ┌──────────────┐                 │
│                    │    Redis     │                 │
│                    └──────────────┘                 │
└─────────────────────────────────────────────────────┘
                           ↑
                   ┌──────────────┐
                   │   Jenkins    │
                   │  (CI/CD)     │
                   └──────────────┘
```

#### Installation

```bash
# Install all required plugins
arfni plugin install django
arfni plugin install nextjs
arfni plugin install nginx
arfni plugin install postgresql
arfni plugin install redis
arfni plugin install jenkins
arfni plugin install kubernetes
```

#### Complete stack.yaml

```yaml
version: 1.0
project:
  name: myapp-production
  frameworks:
    - django
    - nextjs

services:
  # Backend API
  django:
    kind: docker.container
    target: k8s-production
    build:
      context: ./backend
      dockerfile: Dockerfile
    ports:
      - "8000:8000"
    environment:
      DJANGO_SECRET_KEY: ${DJANGO_SECRET_KEY}
      DATABASE_URL: postgresql://postgres:password@postgres:5432/myapp
      REDIS_URL: redis://redis:6379/0
    depends_on:
      - postgres
      - redis

  # Frontend
  nextjs:
    kind: docker.container
    target: k8s-production
    build:
      context: ./frontend
      dockerfile: Dockerfile
    ports:
      - "3000:3000"
    environment:
      NEXT_PUBLIC_API_URL: http://django:8000

  # Reverse Proxy
  nginx:
    kind: proxy.nginx
    target: k8s-production
    spec:
      upstreams:
        - service: django
          port: 8000
          path: /api
        - service: nextjs
          port: 3000
          path: /
      ssl:
        enabled: true
        cert_issuer: letsencrypt-prod
    ports:
      - "80:80"
      - "443:443"

  # Database
  postgres:
    kind: db.postgres
    target: k8s-production
    spec:
      version: "15"
      databases:
        - name: myapp
          user: app_user
          password: ${DB_PASSWORD}
      backup:
        enabled: true
        schedule: "0 2 * * *"

  # Cache
  redis:
    kind: cache.redis
    target: k8s-production
    spec:
      version: "7"
      mode: standalone
      persistence:
        enabled: true

  # CI/CD
  jenkins:
    kind: ci.jenkins
    target: docker.local
    spec:
      version: lts
      jobs:
        - name: deploy-production
          pipeline: Jenkinsfile

targets:
  - name: k8s-production
    type: k8s.cluster
    config:
      kubeconfig: ~/.kube/config
      namespace: production
      replicas: 3
      enable_hpa: true

volumes:
  - postgres_data
  - redis_data
```

#### Deployment Workflow

```bash
# 1. Validate configuration
arfni validate
# ✅ Stack configuration is valid
# ✅ All plugins installed
# ✅ Kubernetes cluster accessible

# 2. Build images
arfni build
# 🔨 Building django...
# 🔨 Building nextjs...

# 3. Run tests
arfni test
# ✅ Django tests passed
# ✅ Next.js build successful

# 4. Deploy to Kubernetes
arfni deploy --target k8s-production
# 🔄 Running database migrations...
# 🔄 Collecting static files...
# 🔄 Generating Kubernetes manifests...
# 🔄 Applying manifests...
# 🔄 Waiting for rollout...
# ✅ Deployment successful

# 5. Verify health
arfni health
# ✅ Django is healthy (200 OK)
# ✅ Next.js is responding
# ✅ PostgreSQL is ready
# ✅ Redis is responding
# ✅ Nginx is proxying correctly
```

---

### Multi-Environment Setup

**Scenario**: Separate development, staging, and production environments.

#### Directory Structure

```
myapp/
├── stack.yaml                 # Base configuration
├── environments/
│   ├── dev.yaml              # Development overrides
│   ├── staging.yaml          # Staging overrides
│   └── production.yaml       # Production overrides
├── backend/                  # Django application
├── frontend/                 # Next.js application
└── .env.example
```

#### Base stack.yaml

```yaml
version: 1.0
project:
  name: myapp
  framework: django

services:
  django:
    kind: docker.container
    build:
      context: ./backend
    ports:
      - "${DJANGO_PORT}:8000"
    environment:
      DJANGO_SECRET_KEY: ${DJANGO_SECRET_KEY}
      DJANGO_DEBUG: "${DJANGO_DEBUG}"

  postgres:
    kind: docker.container
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: myapp
```

#### environments/dev.yaml

```yaml
# Development environment overrides
services:
  django:
    target: docker.local
    environment:
      DJANGO_DEBUG: "true"
      DJANGO_LOG_LEVEL: DEBUG
    volumes:
      - host: ./backend
        mount: /app  # Hot reload

  postgres:
    target: docker.local
    ports:
      - "5432:5432"  # Expose for local access
```

#### environments/staging.yaml

```yaml
# Staging environment overrides
services:
  django:
    target: k8s-staging
    environment:
      DJANGO_DEBUG: "false"
      DJANGO_LOG_LEVEL: INFO
    replicas: 2

  postgres:
    target: k8s-staging
    spec:
      backup:
        enabled: true
        retention_days: 3

targets:
  - name: k8s-staging
    type: k8s.cluster
    config:
      namespace: staging
      replicas: 2
```

#### environments/production.yaml

```yaml
# Production environment overrides
services:
  django:
    target: k8s-production
    environment:
      DJANGO_DEBUG: "false"
      DJANGO_LOG_LEVEL: WARNING
    replicas: 5

  postgres:
    target: k8s-production
    spec:
      backup:
        enabled: true
        retention_days: 30

  nginx:
    kind: proxy.nginx
    target: k8s-production
    spec:
      ssl:
        enabled: true
        cert_issuer: letsencrypt-prod

targets:
  - name: k8s-production
    type: k8s.cluster
    config:
      namespace: production
      replicas: 5
      enable_hpa: true
```

#### Environment-Specific Deployment

```bash
# Deploy to development
arfni deploy --env dev
# Uses: stack.yaml + environments/dev.yaml
# Target: docker.local

# Deploy to staging
arfni deploy --env staging
# Uses: stack.yaml + environments/staging.yaml
# Target: k8s-staging

# Deploy to production (manual approval)
arfni deploy --env production --approve
# Uses: stack.yaml + environments/production.yaml
# Target: k8s-production
```

#### Environment Variables

**.env.dev**:
```bash
DJANGO_SECRET_KEY=dev-secret-key-not-secure
DJANGO_DEBUG=true
DJANGO_PORT=8000
POSTGRES_PASSWORD=dev-password
```

**.env.staging**:
```bash
DJANGO_SECRET_KEY=staging-secret-key-from-vault
DJANGO_DEBUG=false
DJANGO_PORT=8000
POSTGRES_PASSWORD=staging-password-from-vault
```

**.env.production**:
```bash
DJANGO_SECRET_KEY=production-secret-key-from-vault
DJANGO_DEBUG=false
DJANGO_PORT=8000
POSTGRES_PASSWORD=production-password-from-vault
```

---

## Plugin Combination Patterns

### Pattern 1: Monolithic Application

**Plugins**: `django` + `postgresql` + `nginx`

**Use Case**: Traditional monolithic web application

```yaml
services:
  django:
    kind: docker.container
    # Full-stack Django app

  postgres:
    kind: db.postgres
    # Single database

  nginx:
    kind: proxy.nginx
    # Static files + reverse proxy
```

### Pattern 2: Microservices

**Plugins**: `django` + `fastapi` + `nextjs` + `nginx` + `postgresql` + `redis`

**Use Case**: Microservices architecture

```yaml
services:
  api-gateway:
    kind: docker.container
    # FastAPI gateway

  auth-service:
    kind: docker.container
    # Django auth microservice

  user-service:
    kind: docker.container
    # Django user management

  frontend:
    kind: docker.container
    # Next.js UI

  nginx:
    kind: proxy.nginx
    # API gateway routing
```

### Pattern 3: Serverless + Containers

**Plugins**: `django` + `kubernetes` + `redis` + `postgresql`

**Use Case**: Hybrid serverless and containerized

```yaml
services:
  django-api:
    kind: docker.container
    target: k8s-production
    # Containerized API

  django-workers:
    kind: k8s.cronjob
    # Scheduled jobs on K8s

  redis:
    kind: cache.redis
    # Shared cache
```

---

## Best Practices

### 1. Start Simple

Begin with basic framework plugin, add infrastructure as needed:

```bash
# Day 1: Basic Django
arfni plugin install django
arfni init && arfni deploy

# Week 1: Add database
arfni plugin install postgresql
arfni apply  # Update stack

# Month 1: Add caching
arfni plugin install redis
arfni apply

# Month 3: Move to Kubernetes
arfni plugin install kubernetes
arfni deploy --target k8s-production
```

### 2. Use Environment Overrides

Keep base configuration simple, override per environment:

- `stack.yaml` - Shared configuration
- `environments/dev.yaml` - Development settings
- `environments/prod.yaml` - Production settings

### 3. Leverage Hooks

Use plugin hooks for automation:

- **Pre-deploy**: Migrations, backups
- **Post-deploy**: Seed data, create admin users
- **Health check**: Verify deployment

### 4. Version Control Everything

```
.gitignore:
.env
.env.*
*.local
secrets/

Commit:
stack.yaml
environments/*.yaml
plugin.yaml (if custom plugin)
Dockerfile
```

### 5. Monitor Plugin Updates

```bash
# Check for plugin updates
arfni plugin list --updates-available

# Update plugin
arfni plugin update django

# Update all plugins
arfni plugin update --all
```

---

**Need Help?**

- [Plugin Development Guide](CONTRIBUTING.md)
- [Plugin Specification](PLUGIN_SPECIFICATION.md)
- [GitHub Discussions](https://github.com/arfni/arfni/discussions)
- [Discord Community](https://discord.gg/arfni)
