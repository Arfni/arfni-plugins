# ARFNI Plugin Contribution Guide

**English** | [한국어](README.ko.md)

Welcome to the ARFNI plugin repository! This guide explains how to contribute new plugins to the ARFNI ecosystem.

## Table of Contents

- [What is a Plugin?](#what-is-a-plugin)
- [Plugin Categories](#plugin-categories)
- [Plugin Structure](#plugin-structure)
- [Writing plugin.yaml](#writing-pluginyaml)
- [Template Files](#template-files)
- [Lifecycle Hooks](#lifecycle-hooks)
- [Plugin Development Steps](#plugin-development-steps)
- [Validation and Testing](#validation-and-testing)
- [Testing Your Plugin in ARFNI GUI](#testing-your-plugin-in-arfni-gui)
- [Submitting Your Plugin](#submitting-your-plugin)

## What is a Plugin?

An ARFNI plugin is an extension module that adds new frameworks, databases, and services to the ARFNI platform. With plugins, you can:

- Add support for new frameworks (Django, Express, Spring, etc.)
- Integrate databases and cache services
- Enable automatic project detection and configuration
- Auto-generate Docker containers
- Support visual connections in the GUI canvas

## Plugin Categories

Plugins are organized into 8 categories:

| Category | Description | Examples |
|----------|-------------|----------|
| `framework` | Application frameworks | Django, Express, Spring Boot |
| `database` | Database systems | PostgreSQL, MySQL, MongoDB |
| `cache` | In-memory caches | Redis, Memcached |
| `message_queue` | Message queue systems | RabbitMQ, Kafka |
| `proxy` | Reverse proxies/load balancers | Nginx, Traefik |
| `cicd` | CI/CD pipelines | GitHub Actions, Jenkins |
| `orchestration` | Deployment platforms | Kubernetes, Docker Swarm |
| `infrastructure` | Infrastructure tools | Terraform, Ansible |

## Plugin Structure

A plugin follows this directory structure:

```
plugins/{category}/{plugin-name}/
├── plugin.yaml              # Plugin manifest (required)
├── README.md                # Plugin documentation (required)
├── icon.png                 # Plugin icon (required)
├── LICENSE                  # License file (optional)
├── CHANGELOG.md             # Version history (optional)
├── templates/               # Template files directory
│   ├── Dockerfile.tmpl
│   └── config.tmpl
├── hooks/                   # Lifecycle hook scripts
│   ├── pre-deploy.sh
│   ├── post-deploy.sh
│   └── health-check.sh
├── frameworks/              # GUI configuration (for framework plugins)
│   └── {framework}.yaml
└── examples/                # Example projects
    └── basic-example/
```

### Required Files

1. **plugin.yaml** - Plugin metadata and configuration
2. **README.md** - Usage instructions and documentation
3. **icon.png** - Icon displayed in GUI (recommended size: 128x128px)

### Optional Files

- **templates/** - File templates to be generated in user projects
- **hooks/** - Scripts executed at lifecycle events
- **frameworks/** - GUI configuration for framework plugins
- **examples/** - Reference example projects

## Writing plugin.yaml

The `plugin.yaml` file is the core manifest of your plugin. Let's explain each section using the Django plugin as reference.

### 1. Metadata (Required)

```yaml
apiVersion: v0.1              # API version (currently v0.1)
name: django                  # Plugin ID (lowercase, no spaces)
displayName: Django           # Display name
version: 1.0.0               # Semantic versioning
category: framework          # Plugin category
description: Production-ready Django web framework
author: arfni-community      # Author name
homepage: https://github.com/Arfni/arfni-plugins/tree/main/plugins/frameworks/django
license: MIT                 # License type
icon: icon.png              # Icon file path
```

### 2. Auto-Detection (Optional)

Define rules for automatic project detection:

```yaml
detection:
  enabled: true
  priority: 15                # Detection priority (higher = first)
  required_files:
    - manage.py               # Required files list
    - requirements.txt
  file_content_patterns:      # File content patterns
    requirements.txt:
      contains: ["django", "Django"]
```

### 3. Provides (Required)

Declare what your plugin provides:

```yaml
provides:
  frameworks:                 # Framework plugins
    - django
  service_kinds:              # Database plugins (e.g., PostgreSQL)
    - db.postgres
```

### 4. Requirements (Optional)

```yaml
requires:
  arfni_version: ">=0.2.0"
  docker_version: ">=20.10"
```

### 5. User Inputs (Required)

Parameters that users can configure:

```yaml
inputs:
  python_version:
    description: "Python runtime version"
    type: select              # Types: select, text, number, boolean, secret
    options:
      - "3.9"
      - "3.10"
      - "3.11"
      - "3.12"
    default: "3.11"
    required: true

  django_port:
    description: "Django application port"
    type: number
    default: 8000
    required: true

  django_secret_key:
    description: "Django SECRET_KEY"
    type: secret              # Use secret type for sensitive data
    required: true
    env_var: DJANGO_SECRET_KEY  # Automatically set as environment variable

  database_url:
    description: "Database connection URL"
    type: text
    placeholder: "postgresql://user:pass@postgres:5432/dbname"
    required: false
    env_var: DATABASE_URL     # Auto-set when connected in canvas
```

**Input Types:**
- `select` - Dropdown selection
- `text` - Text input
- `number` - Numeric input
- `boolean` - Checkbox
- `secret` - Password/token (encrypted)

### 6. Contributes (Required)

Service definitions to be added to stack.yaml:

```yaml
contributes:
  services:
    django:
      kind: docker.container
      target: "{{target}}"
      spec:
        build:
          context: "{{project_dir}}"
          dockerfile: Dockerfile
        ports:
          - "{{django_port}}:8000"
        health:
          httpGet:
            path: /health/
            port: 8000
          initialDelaySeconds: 30
          periodSeconds: 10
        volumes:
          - host: ./media
            mount: /app/media
          - host: ./static
            mount: /app/static

  canvas:                     # GUI canvas configuration
    nodeType: django
    label: Django
    description: "Python web framework"
    category: runtime
    ports:
      - name: http
        port: 8000
        protocol: tcp
    connections:
      inputs:                 # Connections this node can receive
        - type: database
          name: database
          protocol: any
          env_var: DATABASE_URL
        - type: cache
          name: redis
          protocol: tcp
          env_var: REDIS_URL
      outputs:                # Connections this node can provide
        - type: api
          name: api
          protocol: http

  volumes:                    # Persistent volumes
    - postgres_data
```

### 7. Lifecycle Hooks (Optional)

Scripts executed at specific lifecycle stages:

```yaml
hooks:
  pre_generate:
    script: hooks/validate-project.sh
    description: "Validate project structure"

  post_build:
    script: hooks/collect-static.sh
    description: "Collect static files"

  pre_deploy:
    script: hooks/migrate-database.sh
    description: "Run database migrations"

  post_deploy:
    script: hooks/create-superuser.sh
    description: "Create superuser"

  health_check:
    script: hooks/health-check.sh
    description: "Verify application health"
```

**Available Hooks:**
- `pre_generate` - Before config generation
- `post_generate` - After config generation
- `pre_build` - Before Docker build
- `post_build` - After Docker build
- `pre_deploy` - Before deployment
- `post_deploy` - After deployment
- `health_check` - Health verification

### 8. Templates (Optional)

Files to be generated in user projects:

```yaml
templates:
  - source: templates/Dockerfile.django.tmpl
    target: "{{project_dir}}/Dockerfile"
    description: "Multi-stage Dockerfile for Django"
    overwrite: false          # Don't overwrite existing files

  - source: templates/settings_production.py.tmpl
    target: "{{project_dir}}/settings_production.py"
    description: "Production settings"
    overwrite: false
```

### 9. Documentation (Optional)

```yaml
documentation:
  readme: README.md
  getting_started: docs/getting-started.md
  troubleshooting: docs/troubleshooting.md
```

### 10. Tags (Optional)

Tags for search and discovery:

```yaml
tags:
  - python
  - django
  - backend
  - web-framework
  - orm
  - rest-api
```

### 11. Examples (Optional)

```yaml
examples:
  - name: basic-blog
    description: "Simple Django blog application"
    path: examples/basic-blog/

  - name: rest-api
    description: "Django REST API with JWT"
    path: examples/rest-api/
```

### 12. Changelog (Optional)

```yaml
changelog: CHANGELOG.md
```

## Template Files

Template files use Go template syntax for variable substitution.

### Using Variables

```dockerfile
# templates/Dockerfile.tmpl
FROM python:{{python_version}}-slim

WORKDIR /app

# Use default value
ENV WORKERS={{default "4" .gunicorn_workers}}

EXPOSE {{django_port}}

CMD ["gunicorn", "--workers", "{{gunicorn_workers}}", "--bind", "0.0.0.0:8000"]
```

### Available Variables

- All variables defined in `inputs`
- `{{project_dir}}` - Project directory path
- `{{target}}` - Build target
- `{{default "default_value" .variable_name}}` - Specify default values

## Lifecycle Hooks

Hook scripts are written in Bash and executed at specific event points.

### Example: Database Migration Hook

```bash
#!/bin/bash
# hooks/migrate-database.sh

set -e

echo "Waiting for database to be ready..."
python manage.py wait_for_db

echo "Running Django migrations..."
python manage.py migrate --noinput

echo "Migrations completed successfully!"
```

### Example: Health Check Hook

```bash
#!/bin/bash
# hooks/health-check.sh

set -e

# Check HTTP endpoint
curl -f http://localhost:8000/health/ || exit 1

# Check database connection
python manage.py check --database default || exit 1

echo "Health check passed!"
```

### Hook Script Best Practices

1. **Execute permissions**: Grant execute permissions (`chmod +x hooks/*.sh`)
2. **Error handling**: Use `set -e` to exit on errors
3. **Output**: Clearly output progress information
4. **Environment variables**: Use variables defined with `env_var`
5. **Exit codes**: Return 0 on success, 1 on failure

## Plugin Development Steps

### Step 1: Create Plugin Directory

```bash
# Choose appropriate category
mkdir -p plugins/frameworks/myframework
cd plugins/frameworks/myframework
```

### Step 2: Write plugin.yaml

```bash
# Copy basic template (refer to Django plugin)
cp -r ../django/plugin.yaml .
# Modify contents
```

### Step 3: Write README.md

Write documentation for users:

```markdown
# MyFramework Plugin

A plugin for using MyFramework with ARFNI.

## Usage

1. Install ARFNI CLI
2. Run `arfni init` in project directory
3. Select MyFramework

## Requirements

- MyFramework 2.0+
- Docker 20.10+

## Configuration

...
```

### Step 4: Add Icon

Save a 128x128px PNG icon as `icon.png`.

### Step 5: Write Templates (if needed)

```bash
mkdir templates
# Write Dockerfile, config files, etc.
```

### Step 6: Write Hook Scripts (if needed)

```bash
mkdir hooks
# Write lifecycle scripts
chmod +x hooks/*.sh
```

### Step 7: Local Testing

```bash
# Test with ARFNI CLI locally
arfni plugin validate ./plugins/frameworks/myframework
```

## Validation and Testing

### Automatic Validation

When you commit a plugin, GitHub Actions automatically validates:

- `apiVersion` format check (v0.1)
- Required fields existence
- Category validity
- Version format (semantic versioning)
- `provides` structure validation

### Manual Testing

1. **Local Validation**
   ```bash
   node scripts/generate-registry.js
   ```

2. **Real Project Testing**
   ```bash
   cd /path/to/test-project
   arfni init
   # Select and test plugin
   ```

3. **Docker Build Testing**
   ```bash
   docker build -t test-image .
   docker run -p 8000:8000 test-image
   ```

### Checklist

Check before submitting your plugin:

- [ ] All required fields in `plugin.yaml` completed
- [ ] README.md written (including usage and requirements)
- [ ] icon.png added (128x128px)
- [ ] Template file variable substitution tested
- [ ] Hook script execute permissions verified
- [ ] Local plugin validation successful
- [ ] Tested in real project
- [ ] No typos in documentation

## Testing Your Plugin in ARFNI GUI

After developing your plugin locally, you should test it in the ARFNI GUI before submitting. This ensures your plugin works correctly in the actual user environment.

### Interactive Testing Tutorial

ARFNI GUI provides an interactive plugin testing tutorial page at `/plugin-test`. This page includes:

- **Step-by-step testing guide** - Walk through the entire plugin testing process
- **Testing checklist** - Ensure you've validated all aspects of your plugin
- **Common issues and solutions** - Troubleshooting guide for frequent problems
- **Best practices** - Tips for creating reliable plugins

To access the tutorial:

1. Start ARFNI GUI in development mode
2. Navigate to `http://localhost:1420/plugin-test` (or use the navigation menu)
3. Follow the interactive steps to test your plugin

### Quick Testing Steps

#### 1. Link Your Plugin Directory

Configure ARFNI to load plugins from your local development directory:

**Option A: Environment Variable (Recommended)**
```bash
# Set the plugin directory path
export ARFNI_PLUGIN_DIR="/path/to/arfni-plugins"

# Start ARFNI GUI
cd arfni-gui
npm run tauri dev
```

**Option B: Symlink Method**
```bash
# Create a symbolic link
ln -s /path/to/arfni-plugins/plugins ~/.arfni/plugins
```

**Option C: Configuration File**
```bash
# Edit ~/.arfni/config.json
{
  "pluginDirectory": "/path/to/arfni-plugins/plugins"
}
```

#### 2. Validate Plugin Loading

```bash
# Run the registry generation script
cd scripts
npm install
node generate-registry.js

# Check for your plugin in the output
# Your plugin should appear without validation errors
```

#### 3. Test in GUI

1. **Start ARFNI GUI**
   ```bash
   cd arfni-gui
   npm run tauri dev
   ```

2. **Create Test Project**
   - Go to Projects page
   - Create a new project
   - Your plugin should appear in the available plugins list

3. **Add Plugin to Canvas**
   - Open the canvas editor
   - Drag your plugin from the sidebar
   - Configure it with test values

4. **Generate Files**
   - Use the "Generate" feature
   - Verify that template files are created correctly
   - Check that variables are substituted properly

5. **Test Deployment**
   - Deploy the project
   - Verify lifecycle hooks execute successfully
   - Check that the application runs without errors

### Testing Checklist

Before submitting your plugin, verify:

#### File Structure
- [ ] `plugin.yaml` exists and is valid
- [ ] `README.md` with clear documentation
- [ ] `icon.png` is exactly 128x128 pixels
- [ ] All template files use correct Go template syntax
- [ ] Hook scripts have execute permissions (`chmod +x`)

#### plugin.yaml Validation
- [ ] `apiVersion` follows v0.1 format
- [ ] Version uses semantic versioning (X.Y.Z)
- [ ] Category is one of the 8 valid categories
- [ ] Has either `frameworks` or `service_kinds` in `provides`
- [ ] Author information is complete
- [ ] All required environment variables are documented

#### Functional Testing
- [ ] Plugin loads in ARFNI GUI without errors
- [ ] Plugin appears in the correct category
- [ ] Icon displays correctly in GUI
- [ ] Configuration inputs render properly
- [ ] Template files generate with correct values
- [ ] Lifecycle hooks execute successfully
- [ ] Works with different input combinations

#### Deployment Testing
- [ ] Generated Docker container builds successfully
- [ ] Application runs without errors
- [ ] Health checks pass (if implemented)
- [ ] Port mappings work correctly
- [ ] Environment variables are set properly

### Common Testing Issues

#### Plugin Not Appearing in GUI
- Verify `ARFNI_PLUGIN_DIR` is set correctly
- Run `generate-registry.js` and check for validation errors
- Restart ARFNI GUI after adding the plugin
- Check browser console for loading errors

#### Template Not Generating Correctly
- Verify Go template syntax (use `{{ .VariableName }}`)
- Check that variable names match `contributes.environment`
- Test templates with minimal values first

#### Hook Script Failing
- Ensure script has execute permissions (`chmod +x`)
- Add `#!/bin/bash` shebang at the top
- Test script independently before integration
- Check Tauri backend logs for detailed error messages

### Debug Mode

For detailed debugging information:

```bash
# Enable debug logging
export ARFNI_DEBUG=true
export RUST_LOG=debug

# Start ARFNI GUI
npm run tauri dev
```

This will show detailed logs about plugin loading, validation, and execution.

## Submitting Your Plugin

### 1. Fork and Clone

```bash
# Fork repository (on GitHub)
git clone https://github.com/{your-username}/arfni-plugins.git
cd arfni-plugins
```

### 2. Create Branch

```bash
git checkout -b add-myframework-plugin
```

### 3. Add Plugin

```bash
# Write plugin files
git add plugins/frameworks/myframework/
git commit -m "feat: add MyFramework plugin"
```

### 4. Push and Pull Request

```bash
git push origin add-myframework-plugin
# Create Pull Request on GitHub
```

### Pull Request Template

```markdown
## Plugin Information

- Name: MyFramework
- Category: framework
- Version: 1.0.0

## Description

Plugin for MyFramework. Supports the following features:
- Automatic project detection
- Automatic Dockerfile generation
- Production configuration

## Testing Complete

- [x] Local validation passed
- [x] Tested in real project
- [x] Docker build successful
- [x] Documentation complete

## Checklist

- [x] plugin.yaml written
- [x] README.md written
- [x] icon.png added
- [x] Templates tested
- [x] Hook scripts tested
```

### 5. Review and Merge

- Maintainers conduct code review
- Modifications requested if needed
- Merged to main branch after approval
- GitHub Actions automatically updates registry

## Additional Resources

- [ARFNI Official Documentation](https://arfni.io/docs)
- [Django Plugin Example](plugins/frameworks/django/)
- [PostgreSQL Plugin Example](plugins/database/postgres/)
- [Issue Tracker](https://github.com/Arfni/arfni-plugins/issues)

## Need Help?

- Post questions in GitHub Issues
- Join Discord community
- Refer to existing plugin code

---

Thank you for contributing to the ARFNI plugin ecosystem! 🚀
