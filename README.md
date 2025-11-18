# ARFNI Plugin Development Guide

**English** | [한국어](README.ko.md)

Welcome to the ARFNI plugin ecosystem! This guide shows you how to create and test plugins for ARFNI.

## Quick Start

### 1. Create Your Plugin

Create a folder structure like this:

```
my-plugin/
├── plugin.yaml      # Required: Plugin configuration
├── icon.png        # Required: 128x128 PNG icon
├── README.md       # Required: Documentation
└── templates/      # Optional: Template files
    └── Dockerfile.tmpl
```

### 2. Write plugin.yaml

Here's a minimal example:

```yaml
apiVersion: v0.1
name: my-framework
displayName: My Framework
version: 1.0.0
category: framework  # Choose: framework, database, cache, proxy, cicd, orchestration, monitoring, infrastructure
description: Brief description of your plugin
author: Your Name
license: MIT
icon: icon.png

provides:
  frameworks:        # For framework plugins
    - my-framework
  # OR
  service_kinds:     # For service plugins (database, cache, etc.)
    - db.postgres

inputs:
  port:
    description: "Application port"
    type: number
    default: 3000
    required: true

contributes:
  services:
    app:
      kind: docker.container
      spec:
        build:
          context: "."
          dockerfile: Dockerfile
        ports:
          - "{{port}}:{{port}}"

  canvas:
    nodeType: my-framework
    label: My Framework
    description: "Node description"
    category: runtime
    ports:
      - name: http
        port: 3000
        protocol: tcp
```

### 3. Test Your Plugin

**Method 1: Direct Import (Easiest)**

1. Open ARFNI GUI
2. Go to **Projects** → **Plugin Manager**
3. Find **Custom Plugins** section
4. Click **Plugin Development Guide** button
5. Use **Import Custom Plugin** to select your plugin folder
6. Your plugin appears in the Custom Plugins list

**Method 2: GitHub URL**

1. Push your plugin to GitHub
2. In Plugin Manager, paste your GitHub URL:
   ```
   https://github.com/username/repo/tree/branch/path/to/plugin
   ```
3. Click **Install Plugin**

### 4. Submit Your Plugin

1. Fork [github.com/Arfni/arfni-plugins](https://github.com/Arfni/arfni-plugins)
2. Add your plugin to `plugins/{category}/{plugin-name}/`
   - Use lowercase for folder names (e.g., `my-plugin` not `MyPlugin`)
   - Match the folder name with the `name` field in plugin.yaml
3. Test locally: `cd scripts && npm install && node generate-registry.js --validate-only`
4. Create a Pull Request
5. GitHub Actions will automatically validate your plugin
6. Once merged, it's available to all ARFNI users within minutes

## Plugin Categories

- `framework` - Web frameworks (Django, Spring Boot, Express)
- `database` - Databases (PostgreSQL, MySQL, MongoDB)
- `cache` - Caching systems (Redis, Memcached)
- `proxy` - Reverse proxies (Nginx, Traefik)
- `cicd` - CI/CD tools (GitHub Actions, Jenkins)
- `orchestration` - Container orchestration (Kubernetes)
- `monitoring` - Monitoring tools (Prometheus, Grafana)
- `infrastructure` - Infrastructure tools (Terraform, Ansible)

## plugin.yaml Reference

### Required Fields

```yaml
apiVersion: v0.1              # API version (must be v0.1)
name: plugin-id              # Unique identifier (lowercase, no spaces, use hyphens)
displayName: Plugin Name     # Display name in UI
version: 1.0.0              # Semantic version (X.Y.Z format)
category: framework         # Plugin category (must be one of the 8 categories)
description: Description    # Brief description (one line)
author: Your Name          # Author name or organization
license: MIT              # License type
icon: icon.png           # Icon file (exactly 128x128 PNG)
```

### Provides Section

```yaml
# For framework/runtime plugins:
provides:
  frameworks:
    - my-framework

# For service plugins (database, cache, etc.):
provides:
  service_kinds:
    - db.postgres     # Database services
    - cache.redis     # Cache services
    - proxy.nginx     # Proxy services
```

### Input Types

```yaml
inputs:
  text_input:
    type: text
    default: "value"
    placeholder: "Enter value"

  number_input:
    type: number
    default: 8080

  select_input:
    type: select
    options: ["option1", "option2"]
    default: "option1"

  boolean_input:
    type: boolean
    default: true

  secret_input:
    type: secret
    env_var: SECRET_KEY  # Automatically set as environment variable
```

### Service Definition

```yaml
contributes:
  services:
    my-service:
      kind: docker.container
      spec:
        image: "nginx:latest"      # OR
        build:
          context: "."
          dockerfile: Dockerfile
        ports:
          - "8080:80"
        environment:
          ENV_VAR: "{{input_name}}"
        volumes:
          - "data:/var/lib/data"
```

### Canvas Node

```yaml
contributes:
  canvas:
    nodeType: unique-id
    label: Display Name
    description: "Tooltip description"
    category: runtime      # runtime, database, infra
    ports:
      - name: http
        port: 8080
        protocol: tcp
    connections:
      inputs:              # What this node can receive
        - type: database
          name: db
          protocol: any
          env_var: DATABASE_URL
      outputs:             # What this node provides
        - type: api
          name: api
          protocol: http
```

### Auto-Detection (Optional)

```yaml
detection:
  enabled: true
  priority: 10
  required_files:
    - package.json
  file_content_patterns:
    package.json:
      contains: ["express"]
```

### Templates (Optional)

Include template files in a `templates/` folder:

```yaml
templates:
  - source: templates/Dockerfile.tmpl
    target: Dockerfile
    description: "Dockerfile for production"
    overwrite: false
```

Templates use Go template syntax:
```dockerfile
FROM node:{{node_version}}
WORKDIR /app
COPY . .
RUN npm install
EXPOSE {{port}}
CMD ["node", "server.js"]
```

Variables are replaced with user inputs or defaults.

## Examples

Check out existing plugins for reference:
- [Django Plugin](plugins/frameworks/django/)
- [PostgreSQL Plugin](plugins/database/postgresql/)
- [GitHub Actions Plugin](plugins/cicd/github-actions/)

## Validation

Your plugin is automatically validated when you:
1. Import it in ARFNI GUI
2. Submit a Pull Request (GitHub Actions runs validation)

### Local Validation
```bash
cd scripts
npm install
node generate-registry.js --validate-only
```

### Validation Rules
- `apiVersion` must be `v0.1`
- `name` must be lowercase with hyphens (e.g., `my-plugin`)
- `displayName` can have spaces and capitals
- `category` must be one of the 8 valid categories
- `version` must follow semantic versioning (X.Y.Z)
- `provides` must have either `frameworks` or `service_kinds`
- `icon.png` must exist and be 128x128 pixels

## Troubleshooting

### Common Issues

**Plugin not showing up in GUI:**
- Check that all required fields are in plugin.yaml
- Verify icon.png exists and is 128x128 pixels
- Run validation: `node generate-registry.js --validate-only`

**Template variables not working:**
- Use double curly braces: `{{variable_name}}`
- Variable names must match input names exactly
- Check for typos in variable names

**Docker build failing:**
- Ensure Dockerfile template has correct syntax
- Test the generated Dockerfile manually
- Check that all required files are included

## FAQ

**Q: How do I debug my plugin?**
A: Check the ARFNI GUI console (F12) for error messages. Enable debug mode with `RUST_LOG=debug`.

**Q: Can I use private plugins?**
A: Yes, use the Custom Plugins feature or install from your private GitHub repo.

**Q: How do I update my plugin?**
A: Increment the version in `plugin.yaml` and reinstall.

**Q: What's the difference between `frameworks` and `service_kinds`?**
A: `frameworks` is for application frameworks (Django, Spring Boot), `service_kinds` is for services (databases, caches).

**Q: Can I include binary files in my plugin?**
A: Yes, but keep them small. Large binaries should be downloaded during installation.

## Support

- [GitHub Issues](https://github.com/Arfni/arfni-plugins/issues)
- [Discord Community](https://discord.gg/arfni)
- [Documentation](https://arfni.io/docs)

---

Ready to build? Create your first plugin and join the ARFNI ecosystem! 🚀