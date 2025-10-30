# Contributing to ARFNI Plugins

Thank you for your interest in contributing! This guide will help you add new plugins to the ARFNI ecosystem.

## Plugin Categories

Choose the appropriate category for your plugin:

- **Framework** (`framework`): Helps build/containerize application code
  - Examples: Django, React, Spring Boot, FastAPI

- **Infrastructure** (`infrastructure`): Adds infrastructure services
  - Examples: Nginx, Redis, PostgreSQL, Traefik

- **CI/CD** (`cicd`): CI/CD pipeline integration
  - Examples: Jenkins, GitLab CI, GitHub Actions

- **Orchestration** (`orchestration`): Deployment platform support
  - Examples: Kubernetes, Docker Swarm

## How to Add a Plugin

### Step 1: Fork & Clone

```bash
# Fork this repository on GitHub

# Clone your fork
git clone https://github.com/yourusername/arfni-plugins.git
cd arfni-plugins
```

### Step 2: Create Plugin Directory

```bash
# Choose the appropriate category
# For framework plugins:
mkdir -p plugins/frameworks/my-plugin

# For infrastructure plugins:
mkdir -p plugins/infrastructure/my-plugin

# For CI/CD plugins:
mkdir -p plugins/cicd/my-plugin

# For orchestration plugins:
mkdir -p plugins/orchestration/my-plugin
```

### Step 3: Create Required Files

Every plugin MUST have these files:

#### plugin.yaml (Required)

```yaml
apiVersion: v0.1
name: my-plugin
version: 1.0.0
category: framework  # or: infrastructure, cicd, orchestration
description: Short description of what your plugin does
author: your-name
homepage: https://github.com/yourusername/arfni-plugins/tree/main/plugins/...
license: MIT

provides:
  frameworks: [my-framework]  # For framework plugins
  # OR
  service_kinds: [my.service]  # For infrastructure/cicd plugins
  # OR
  target_types: [my.target]  # For orchestration plugins

requires:
  arfni_version: ">=0.2.0"
  docker_version: ">=20.10"

tags:
  - relevant
  - search
  - keywords
```

#### README.md (Required)

```markdown
# My Plugin

Description of your plugin.

## Installation

\`\`\`bash
arfni plugin install my-plugin
\`\`\`

## Usage

\`\`\`yaml
# stack.yaml example
\`\`\`

## Configuration

...

## Requirements

- ARFNI >= 0.2.0
- Docker >= 20.10

## License

MIT
```

#### LICENSE (Required)

Use MIT license (recommended) or another OSI-approved license.

### Step 4: Add Plugin Files

Depending on your plugin type, add:

**Framework Plugins**:
- `frameworks/<name>.yaml` - Framework definition for GUI
- `templates/Dockerfile.<name>.tmpl` - Dockerfile template
- `hooks/` - Lifecycle scripts (optional)

**Infrastructure Plugins**:
- `templates/config.tmpl` - Service configuration templates
- `hooks/` - Setup and health check scripts
- `configs/` - Default configuration files

**CI/CD Plugins**:
- `templates/pipeline.tmpl` - Pipeline definition templates
- `hooks/` - Setup scripts

**Orchestration Plugins**:
- `transforms/` - Transformation logic
- `templates/` - Platform-specific manifests
- `hooks/` - Deployment scripts

### Step 5: Test Locally

```bash
# Install plugin locally
arfni plugin install ./plugins/<category>/<my-plugin>

# Test with a real project
cd /path/to/test-project
arfni init --plugin my-plugin
arfni apply

# Verify everything works
```

### Step 6: Validate Plugin

```bash
# Run validation script
./scripts/validate-plugin.sh plugins/<category>/<my-plugin>

# Should output:
# ✅ plugin.yaml is valid
# ✅ README.md exists
# ✅ LICENSE exists
# ✅ All required fields present
```

### Step 7: Commit & Push

```bash
# Create feature branch
git checkout -b add-my-plugin

# Add files
git add plugins/<category>/<my-plugin>

# Commit with clear message
git commit -m "feat: add <my-plugin> plugin

- Add <my-plugin> plugin for <category>
- Includes documentation and examples
- Tested with ARFNI 0.2.0"

# Push to your fork
git push origin add-my-plugin
```

### Step 8: Create Pull Request

1. Go to https://github.com/arfni/arfni-plugins
2. Click "New Pull Request"
3. Select your fork and branch
4. Fill in the PR template:

```markdown
## Plugin: my-plugin

### Category
- [ ] Framework
- [ ] Infrastructure
- [ ] CI/CD
- [ ] Orchestration

### Description
Brief description of what this plugin does.

### Testing
- [ ] Tested locally with ARFNI 0.2.0
- [ ] Documentation is complete
- [ ] Examples are provided
- [ ] All hooks are tested

### Checklist
- [ ] plugin.yaml is valid
- [ ] README.md is complete
- [ ] LICENSE file included
- [ ] No sensitive data (API keys, passwords)
- [ ] Tags are relevant
```

5. Submit PR
6. Wait for review

## PR Review Process

Your PR will be reviewed for:

### 1. File Structure ✅
- [ ] `plugin.yaml` exists and is valid
- [ ] `README.md` exists and is complete
- [ ] `LICENSE` file exists

### 2. plugin.yaml Validation ✅
- [ ] `name` is unique (no conflicts)
- [ ] `version` follows semver (1.0.0, 1.1.0, etc.)
- [ ] `description` is clear and concise
- [ ] `category` is correct
- [ ] All required fields are present
- [ ] `tags` are relevant

### 3. Security ✅
- [ ] No hardcoded passwords or API keys
- [ ] No malicious code in hooks
- [ ] No external downloads from untrusted sources
- [ ] Hooks don't access sensitive system files

### 4. Testing ✅
- [ ] Plugin installs without errors
- [ ] Generated configurations are valid
- [ ] Hooks execute successfully
- [ ] Example projects work

### 5. Documentation ✅
- [ ] README has clear installation instructions
- [ ] Usage examples are provided
- [ ] Configuration options are documented
- [ ] Troubleshooting section exists (if needed)

## Guidelines

### DO ✅

- Write clear documentation
- Provide usage examples
- Use meaningful variable names
- Add comments to complex hooks
- Follow semver for versioning
- Test thoroughly before submitting
- Use MIT license (recommended)

### DON'T ❌

- Hardcode sensitive data
- Add malicious code
- Copy copyrighted code without attribution
- Submit incomplete plugins
- Use offensive language
- Modify other plugins without permission

## Plugin Development Tips

### Framework Plugins

```yaml
# Good framework detection
detection:
  files:
    - manage.py  # Django-specific file
    - requirements.txt
  file_content:
    - file: requirements.txt
      contains: "Django"

# Good Dockerfile generation
dockerfile:
  template: |
    FROM python:{{python_version}}
    WORKDIR /app
    COPY requirements.txt .
    RUN pip install -r requirements.txt
    COPY . .
    CMD ["python", "manage.py", "runserver"]
```

### Infrastructure Plugins

```yaml
# Good service kind definition
service_kind_spec:
  proxy.nginx:
    description: "Nginx reverse proxy"
    required_fields:
      - upstreams
    upstream_schema:
      service: string
      port: number
```

### Hook Scripts

```bash
#!/bin/bash
set -e  # Exit on error

echo "🔄 Running setup..."

# Check prerequisites
if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found"
    exit 1
fi

# Do work
echo "✅ Setup complete"
```

## Getting Help

- **Questions**: [GitHub Discussions](https://github.com/arfni/arfni/discussions)
- **Bugs**: [GitHub Issues](https://github.com/arfni/arfni-plugins/issues)
- **Chat**: [Discord](https://discord.gg/arfni)

## Code of Conduct

### Our Standards

- Be respectful and inclusive
- Welcome newcomers
- Focus on constructive feedback
- Assume good intentions

### Unacceptable Behavior

- Harassment or discrimination
- Trolling or insulting comments
- Publishing others' private information
- Other unprofessional conduct

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for contributing to ARFNI! 🎉**
