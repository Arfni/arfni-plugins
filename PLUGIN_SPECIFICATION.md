# ARFNI Plugin Specification v0.1

This document defines the complete specification for ARFNI plugins, including manifest format, lifecycle hooks, service contributions, and integration patterns.

## Table of Contents

- [Overview](#overview)
- [Plugin Manifest (plugin.yaml)](#plugin-manifest-pluginyaml)
- [Plugin Categories](#plugin-categories)
- [Lifecycle Hooks](#lifecycle-hooks)
- [Service Contributions](#service-contributions)
- [Input Types](#input-types)
- [Template System](#template-system)
- [Framework Plugins Specification](#framework-plugins-specification)
- [Infrastructure Plugins Specification](#infrastructure-plugins-specification)
- [CI/CD Plugins Specification](#cicd-plugins-specification)
- [Orchestration Plugins Specification](#orchestration-plugins-specification)
- [Registry Format](#registry-format)
- [Validation Rules](#validation-rules)

## Overview

ARFNI plugins extend ARFNI's capabilities by adding support for new frameworks, infrastructure services, CI/CD pipelines, and deployment targets. All plugins follow a unified manifest format with category-specific extensions.

### Plugin Structure

```
my-plugin/
├── plugin.yaml              # Required: Plugin manifest
├── README.md                # Required: Documentation
├── LICENSE                  # Required: License file
├── frameworks/              # Framework plugins only
│   └── framework-name.yaml  # GUI framework definition
├── templates/               # Optional: File templates
│   ├── Dockerfile.tmpl
│   └── config.tmpl
├── hooks/                   # Optional: Lifecycle scripts
│   ├── pre_deploy.sh
│   └── post_deploy.sh
└── configs/                 # Optional: Default configs
    └── defaults.yaml
```

## Plugin Manifest (plugin.yaml)

The `plugin.yaml` file is the core definition of every plugin.

### Required Fields

```yaml
apiVersion: v0.1              # Spec version (currently v0.1)
name: plugin-name             # Unique plugin identifier (lowercase, hyphens)
version: 1.0.0                # Semantic version (MAJOR.MINOR.PATCH)
category: framework           # One of: framework, infrastructure, cicd, orchestration
description: Short plugin description  # Max 200 characters
author: author-name           # Plugin author/organization
homepage: https://github.com/... # Plugin homepage URL
license: MIT                  # OSI-approved license (MIT recommended)
```

### Provides Section

Declares what capabilities this plugin adds:

```yaml
provides:
  frameworks: []              # List of framework names (framework plugins)
  service_kinds: []           # List of service kinds (infrastructure/cicd plugins)
  target_types: []            # List of target types (orchestration plugins)
```

**Rules**:
- Framework plugins MUST have non-empty `frameworks` list
- Infrastructure/CI/CD plugins MUST have non-empty `service_kinds` list
- Orchestration plugins MUST have non-empty `target_types` list
- At least one list must be non-empty

### Requires Section

Declares plugin dependencies:

```yaml
requires:
  arfni_version: ">=0.2.0"    # Required ARFNI version (semver range)
  docker_version: ">=20.10"   # Optional: Required Docker version
  kubectl_version: ">=1.25"   # Optional: Required kubectl version
  # Add other tool requirements as needed
```

### Inputs Section

User-configurable inputs displayed in GUI:

```yaml
inputs:
  input_name:
    description: "Input description"  # Shown in GUI
    type: text                        # See Input Types section
    default: "default-value"          # Optional default
    required: true                    # Whether input is required
    env_var: ENV_VAR_NAME            # Optional: Export as environment variable
    options: []                       # For select/multiselect types
```

### Contributes Section

Services and volumes this plugin provides:

```yaml
contributes:
  services:
    service-name:
      kind: docker.container          # Service kind
      target: "{{target}}"            # Deployment target
      spec:
        image: "image:tag"            # Docker image
        build:                        # Or build configuration
          context: "{{project_dir}}"
          dockerfile: Dockerfile
        ports:
          - "8000:8000"
        environment:
          KEY: "value"
        volumes:
          - host: volume_name
            mount: /path/in/container
        health:                       # Optional health check
          httpGet:
            path: /health
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        depends_on:                   # Service dependencies
          - postgres
          - redis

  volumes:                            # Named volumes
    - volume_name
    - another_volume
```

### Hooks Section

Lifecycle hooks executed at different phases:

```yaml
hooks:
  pre_generate:                       # Before stack.yaml generation
    script: hooks/pre-generate.sh
    description: "Hook description"

  post_generate:                      # After stack.yaml generation
    script: hooks/post-generate.sh
    description: "Hook description"

  pre_build:                          # Before Docker build
    script: hooks/pre-build.sh
    description: "Hook description"

  post_build:                         # After Docker build
    script: hooks/post-build.sh
    description: "Hook description"

  pre_deploy:                         # Before deployment
    script: hooks/pre-deploy.sh
    description: "Hook description"

  deploy:                             # Custom deployment
    script: hooks/deploy.sh
    description: "Hook description"

  post_deploy:                        # After deployment
    script: hooks/post-deploy.sh
    description: "Hook description"

  health_check:                       # Health verification
    script: hooks/health-check.sh
    description: "Hook description"
```

### Tags Section

Search and discovery tags:

```yaml
tags:
  - python
  - django
  - backend
  - postgresql
```

**Rules**:
- Use lowercase
- Use hyphens for multi-word tags
- Include relevant technology names
- Include use case keywords (backend, frontend, database, cache, etc.)

## Plugin Categories

### Framework

Plugins that build and containerize application code.

**Examples**: Django, React, Spring Boot, FastAPI, Next.js

**Required**:
- `provides.frameworks` list
- `frameworks/<name>.yaml` file for GUI detection
- Dockerfile template or build configuration

**Optional**:
- Pre/post build hooks
- Database migration hooks
- Static file collection hooks

### Infrastructure

Plugins that add infrastructure services to stacks.

**Examples**: Nginx, PostgreSQL, Redis, Traefik, RabbitMQ

**Required**:
- `provides.service_kinds` list
- Service contribution in `contributes.services`

**Optional**:
- Configuration templates
- Setup hooks
- Health check hooks

### CI/CD

Plugins that integrate CI/CD pipeline tools.

**Examples**: Jenkins, GitLab CI, GitHub Actions, CircleCI

**Required**:
- `provides.service_kinds` list (e.g., `ci.jenkins`)
- Pipeline/job templates

**Optional**:
- Setup hooks
- Plugin installation hooks
- Job configuration hooks

### Orchestration

Plugins that enable deployment to different platforms.

**Examples**: Kubernetes, Docker Swarm, AWS ECS, Nomad

**Required**:
- `provides.target_types` list (e.g., `k8s.cluster`)
- Transformation logic for converting `docker.container` to platform-specific format

**Optional**:
- Pre/post deployment hooks
- Platform validation hooks
- Rollback hooks

## Lifecycle Hooks

Hooks are executable scripts (bash, sh, Python, etc.) that run at specific lifecycle phases.

### Hook Execution Context

Hooks are executed with:
- **Working Directory**: Project root directory
- **Environment Variables**: All plugin inputs exported as environment variables
- **Exit Code**: Non-zero exit code stops the workflow

### Available Hooks

| Hook | Phase | Use Cases |
|------|-------|-----------|
| `pre_generate` | Before stack.yaml generation | Validate project structure, check dependencies |
| `post_generate` | After stack.yaml generation | Modify generated stack.yaml, add custom services |
| `pre_build` | Before Docker build | Generate config files, download dependencies |
| `post_build` | After Docker build | Run tests, security scans |
| `pre_deploy` | Before deployment | Database migrations, backup data |
| `deploy` | Custom deployment | Custom deployment logic (overrides default) |
| `post_deploy` | After deployment | Create admin users, seed data, verify deployment |
| `health_check` | After deployment | Verify service health, run smoke tests |

### Hook Script Template

```bash
#!/bin/bash
# Hook description
# Runs at: [lifecycle phase]

set -e  # Exit on error

echo "🔄 Starting [hook name]..."

# Access plugin inputs via environment variables
echo "Using configuration: $INPUT_NAME"

# Check prerequisites
if ! command -v required-tool &> /dev/null; then
    echo "❌ required-tool not found"
    exit 1
fi

# Perform hook logic
# ...

# Check results
if [ $? -eq 0 ]; then
    echo "✅ [Hook name] completed successfully"
else
    echo "❌ [Hook name] failed"
    exit 1
fi

exit 0
```

### Hook Best Practices

1. **Always use `set -e`** to exit on first error
2. **Provide clear output** with emoji indicators (🔄 ✅ ❌ ⚠️)
3. **Check prerequisites** before performing operations
4. **Use environment variables** for configuration
5. **Make idempotent** - safe to run multiple times
6. **Handle missing services gracefully** - check if service exists before operating
7. **Provide meaningful exit codes** - 0 for success, non-zero for failure

## Service Contributions

Plugins can contribute services that are automatically added to stacks.

### Service Specification

```yaml
contributes:
  services:
    service-name:
      kind: docker.container          # Service kind (extensible)
      target: "{{target}}"            # Deployment target variable
      spec:
        # Docker Compose compatible spec
        image: "postgres:15-alpine"
        ports:
          - "5432:5432"
        environment:
          POSTGRES_DB: "{{db_name}}"
          POSTGRES_USER: "{{db_user}}"
          POSTGRES_PASSWORD: "{{db_password}}"
        volumes:
          - host: postgres_data
            mount: /var/lib/postgresql/data
        health:
          test: ["CMD-SHELL", "pg_isready -U {{db_user}}"]
          interval: 10s
          timeout: 5s
          retries: 5
        depends_on:
          - other-service
```

### Service Kinds

Service kinds define the type of service. Built-in kinds:

- `docker.container` - Standard Docker container

Plugins can define custom kinds:

- `proxy.nginx` - Nginx reverse proxy
- `cache.redis` - Redis cache
- `db.postgres` - PostgreSQL database
- `ci.jenkins` - Jenkins CI server
- `k8s.deployment` - Kubernetes deployment

### Template Variables

Use `{{variable_name}}` syntax for dynamic values:

- `{{project_dir}}` - Absolute path to project directory
- `{{project_name}}` - Project name (from directory name)
- `{{target}}` - Deployment target (e.g., `docker.local`, `k8s.cluster`)
- `{{input_name}}` - Any plugin input value
- `{{env.VAR_NAME}}` - Environment variable

### Filters

Apply filters to transform values:

```yaml
# Default value
port: "{{django_port | default: 8000}}"

# Uppercase
db_name: "{{project_name | uppercase}}"

# Lowercase
username: "{{admin_user | lowercase}}"

# Replace
image_tag: "{{version | replace: '.', '-'}}"
```

## Input Types

Plugin inputs define user-configurable parameters displayed in GUI.

### text

Single-line text input:

```yaml
project_name:
  description: "Project name"
  type: text
  default: "my-project"
  required: true
```

### textarea

Multi-line text input:

```yaml
description:
  description: "Project description"
  type: textarea
  default: ""
  required: false
```

### number

Numeric input:

```yaml
port:
  description: "Server port"
  type: number
  default: 8000
  required: true
```

### boolean

Checkbox input:

```yaml
enable_debug:
  description: "Enable debug mode"
  type: boolean
  default: false
  required: false
```

### select

Dropdown selection:

```yaml
python_version:
  description: "Python version"
  type: select
  options:
    - "3.9"
    - "3.10"
    - "3.11"
    - "3.12"
  default: "3.11"
  required: true
```

### multiselect

Multiple selection:

```yaml
features:
  description: "Features to enable"
  type: multiselect
  options:
    - "authentication"
    - "api"
    - "admin"
    - "celery"
  default: ["authentication", "admin"]
  required: false
```

### secret

Password/secret input (masked in GUI):

```yaml
api_key:
  description: "API key"
  type: secret
  required: true
  env_var: API_KEY
```

### file

File path input:

```yaml
config_file:
  description: "Configuration file path"
  type: file
  default: "./config.yaml"
  required: false
```

## Template System

Plugins can include template files that are processed with variables.

### Template Locations

- `templates/Dockerfile.tmpl` - Dockerfile template
- `templates/config.tmpl` - Configuration file template
- `templates/*.tmpl` - Any custom templates

### Template Syntax

Templates use Go template syntax:

```dockerfile
# Dockerfile.django.tmpl
FROM python:{{python_version}}-slim

WORKDIR /app

# Conditional
{{if enable_redis}}
RUN pip install redis
{{end}}

# Loop
{{range dependencies}}
RUN pip install {{.}}
{{end}}

# Default value
EXPOSE {{port | default: 8000}}

CMD ["gunicorn", "--bind", "0.0.0.0:{{port}}", "{{project_name}}.wsgi"]
```

## Framework Plugins Specification

Framework plugins have additional requirements for GUI integration.

### Framework Definition File

Location: `frameworks/<framework-name>.yaml`

```yaml
name: django
display_name: Django
description: Python web framework
icon: django.svg                    # Optional icon file

# Framework detection rules
detection:
  files:                            # Required files
    - manage.py
    - requirements.txt

  file_content:                     # File content patterns
    - file: requirements.txt
      contains: "Django"
    - file: manage.py
      contains: "django.core.management"

  directories:                      # Required directories
    - "*/settings.py"

# GUI configuration form
properties:
  python_version:
    label: "Python Version"
    type: select
    options: ["3.9", "3.10", "3.11", "3.12"]
    default: "3.11"

  enable_postgres:
    label: "Add PostgreSQL"
    type: boolean
    default: true

  enable_redis:
    label: "Add Redis"
    type: boolean
    default: false

# Dockerfile generation
dockerfile:
  template: |
    FROM python:{{python_version}}-slim
    WORKDIR /app
    COPY requirements.txt .
    RUN pip install -r requirements.txt
    COPY . .
    EXPOSE {{port | default: 8000}}
    CMD ["python", "manage.py", "runserver", "0.0.0.0:{{port | default: 8000}}"]

# Default service configuration
default_service:
  ports:
    - "8000:8000"
  environment:
    DJANGO_SETTINGS_MODULE: "{{project_name}}.settings"
  volumes:
    - host: "."
      mount: /app
```

### Framework Detection

Detection runs when user drags project folder into GUI:

1. Check if all `detection.files` exist
2. Check if all `detection.directories` exist
3. Check if all `detection.file_content` patterns match
4. If all conditions pass, framework is detected

### GUI Property Mapping

Properties defined in framework YAML appear in GUI:

- `label` - Display label in GUI
- `type` - Input widget type
- `options` - For select/multiselect
- `default` - Default value

These map to `plugin.yaml` inputs and are available in templates.

## Infrastructure Plugins Specification

Infrastructure plugins add services with custom service kinds.

### Service Kind Definition

```yaml
provides:
  service_kinds:
    - proxy.nginx
    - cache.redis
    - db.postgres
```

### Service Configuration Schema

Define expected configuration for custom service kinds:

```yaml
service_kind_spec:
  proxy.nginx:
    description: "Nginx reverse proxy"
    required_fields:
      - upstreams

    schema:
      upstreams:
        type: array
        items:
          service: string
          port: number
          path: string

      ssl:
        type: boolean
        default: false

      config_template:
        type: string
        default: "templates/nginx.conf.tmpl"
```

### Example: Nginx Plugin

```yaml
# plugin.yaml
provides:
  service_kinds:
    - proxy.nginx

contributes:
  services:
    nginx:
      kind: proxy.nginx
      spec:
        image: "nginx:{{nginx_version}}-alpine"
        ports:
          - "80:80"
          - "443:443"
        volumes:
          - host: nginx_conf
            mount: /etc/nginx/nginx.conf
          - host: nginx_certs
            mount: /etc/nginx/certs
```

## CI/CD Plugins Specification

CI/CD plugins integrate pipeline tools.

### Pipeline Templates

Location: `templates/pipeline.tmpl`

```yaml
# templates/Jenkinsfile.tmpl
pipeline {
    agent any

    stages {
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

        stage('Deploy') {
            steps {
                sh 'arfni deploy --target {{target}}'
            }
        }
    }
}
```

### Job Configuration

```yaml
contributes:
  jobs:
    build-and-deploy:
      pipeline: templates/Jenkinsfile.tmpl
      triggers:
        - type: scm
          schedule: "H/5 * * * *"
      parameters:
        - name: target
          type: choice
          choices: ["dev", "staging", "prod"]
```

## Orchestration Plugins Specification

Orchestration plugins transform Docker stacks to platform-specific formats.

### Target Type Definition

```yaml
provides:
  target_types:
    - k8s.cluster
    - swarm.cluster
    - ecs.cluster
```

### Transformation Rules

```yaml
transforms:
  docker.container:                   # Source kind
    to: k8s.deployment                # Target kind
    mapping:
      image: spec.template.spec.containers[0].image
      ports: spec.template.spec.containers[0].ports
      env: spec.template.spec.containers[0].env
      volumes: spec.template.spec.volumes
```

### Manifest Generation

```yaml
hooks:
  generate_manifests:
    script: hooks/generate-k8s-manifests.sh
    description: "Generate Kubernetes manifests from stack"
```

Example hook:

```bash
#!/bin/bash
# Generate Kubernetes manifests from Docker Compose stack

set -e

echo "🔄 Generating Kubernetes manifests..."

# Read stack.yaml
STACK_FILE="stack.yaml"
OUTPUT_DIR="k8s-manifests"

mkdir -p "$OUTPUT_DIR"

# Transform each service
yq eval '.services | to_entries[] | .key' "$STACK_FILE" | while read SERVICE; do
    echo "📝 Generating manifest for $SERVICE..."

    # Extract service spec
    IMAGE=$(yq eval ".services.$SERVICE.image" "$STACK_FILE")
    PORTS=$(yq eval ".services.$SERVICE.ports[]" "$STACK_FILE")

    # Generate Deployment
    cat > "$OUTPUT_DIR/$SERVICE-deployment.yaml" <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $SERVICE
spec:
  replicas: 3
  selector:
    matchLabels:
      app: $SERVICE
  template:
    metadata:
      labels:
        app: $SERVICE
    spec:
      containers:
      - name: $SERVICE
        image: $IMAGE
        ports:
        - containerPort: $(echo $PORTS | cut -d: -f2)
EOF

    # Generate Service
    cat > "$OUTPUT_DIR/$SERVICE-service.yaml" <<EOF
apiVersion: v1
kind: Service
metadata:
  name: $SERVICE
spec:
  selector:
    app: $SERVICE
  ports:
  - port: $(echo $PORTS | cut -d: -f1)
    targetPort: $(echo $PORTS | cut -d: -f2)
EOF
done

echo "✅ Kubernetes manifests generated in $OUTPUT_DIR/"
```

## Registry Format

The registry index enables plugin discovery and search.

### registry/index.json

```json
{
  "version": "1.0.0",
  "updated_at": "2024-01-15T10:30:00Z",
  "plugins": [
    {
      "id": "django",
      "name": "Django Framework",
      "category": "framework",
      "version": "1.0.0",
      "description": "Production-ready Django framework with PostgreSQL and Redis support",
      "author": "arfni-community",
      "homepage": "https://github.com/arfni/arfni-plugins/tree/main/plugins/frameworks/django",
      "license": "MIT",
      "path": "plugins/frameworks/django",
      "provides": {
        "frameworks": ["django"],
        "service_kinds": [],
        "target_types": []
      },
      "requires": {
        "arfni_version": ">=0.2.0",
        "docker_version": ">=20.10"
      },
      "tags": [
        "python",
        "django",
        "backend",
        "web",
        "postgresql",
        "redis"
      ],
      "downloads": 1250,
      "stars": 45,
      "last_updated": "2024-01-15T10:30:00Z"
    }
  ]
}
```

### Registry Update

Registry is automatically updated when plugins are added/modified via PR.

## Validation Rules

### Plugin Name

- ✅ Lowercase letters, numbers, hyphens only
- ✅ Must start with letter
- ✅ 3-50 characters
- ❌ No underscores, spaces, special characters

### Version

- ✅ Semantic versioning (MAJOR.MINOR.PATCH)
- ✅ Example: `1.0.0`, `2.1.3`, `0.1.0-beta`
- ❌ No prefixes like `v1.0.0`

### Category

- ✅ One of: `framework`, `infrastructure`, `cicd`, `orchestration`
- ❌ Cannot be empty or custom value

### Description

- ✅ 10-200 characters
- ✅ Clear, concise description
- ❌ No marketing language or excessive punctuation

### License

- ✅ OSI-approved license (MIT, Apache-2.0, GPL-3.0, etc.)
- ✅ LICENSE file must exist
- ❌ Proprietary or custom licenses

### File Structure

- ✅ `plugin.yaml` must exist
- ✅ `README.md` must exist
- ✅ `LICENSE` must exist
- ✅ All hook scripts must be executable
- ✅ All referenced templates must exist

### Hook Scripts

- ✅ Must have shebang (`#!/bin/bash`)
- ✅ Must be executable (`chmod +x`)
- ✅ Must use `set -e` for error handling
- ❌ Cannot contain hardcoded secrets
- ❌ Cannot access sensitive system files

### Security

- ❌ No hardcoded passwords, API keys, tokens
- ❌ No external downloads from untrusted sources
- ❌ No malicious code in hooks
- ❌ No access to sensitive files (`/etc/passwd`, `/etc/shadow`, etc.)

---

**Version**: v0.1
**Last Updated**: 2024-01-15
**Maintainer**: ARFNI Community
