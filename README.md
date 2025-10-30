# ARFNI Plugins

Central repository for ARFNI framework, infrastructure, CI/CD, and orchestration plugins.

## Overview

ARFNI Plugins provides a unified plugin system to extend ARFNI's capabilities across multiple domains:

- **Framework Plugins**: Build and containerize applications (Django, React, Spring Boot, etc.)
- **Database Plugins**: Relational and NoSQL databases (PostgreSQL, MySQL, MongoDB, etc.)
- **Cache Plugins**: In-memory caching and session storage (Redis, Memcached, etc.)
- **Message Queue Plugins**: Asynchronous messaging (RabbitMQ, Kafka, etc.)
- **Proxy Plugins**: Reverse proxies and load balancers (Nginx, Traefik, HAProxy, etc.)
- **CI/CD Plugins**: Integrate deployment pipelines (Jenkins, GitLab CI, GitHub Actions)
- **Orchestration Plugins**: Deploy to different platforms (Kubernetes, Docker Swarm)

## Plugin Categories

### 🚀 Framework Plugins

Help build and deploy application code.

| Plugin | Description | Status |
|--------|-------------|--------|
| [Django](plugins/frameworks/django/) | Production-ready Django framework | ✅ Ready |
| [React](plugins/frameworks/react/) | React frontend applications | 🚧 Coming Soon |
| [Spring Boot](plugins/frameworks/spring-boot/) | Java enterprise framework | 🚧 Coming Soon |
| [FastAPI](plugins/frameworks/fastapi/) | Modern Python API framework | 🚧 Coming Soon |

**What they do**:
- Detect project type from source code
- Generate optimized Dockerfiles
- Configure build processes
- Multi-stage build optimization

### 🗄️ Database Plugins

Persistent data storage solutions.

| Plugin | Description | Service Kind | Status |
|--------|-------------|--------------|--------|
| [PostgreSQL](plugins/database/postgresql/) | Production-grade relational database | `db.postgres` | ✅ Ready |
| [MySQL](plugins/database/mysql/) | Popular relational database | `db.mysql` | 🚧 Coming Soon |
| [MongoDB](plugins/database/mongodb/) | Document-oriented NoSQL database | `db.mongodb` | 🚧 Coming Soon |

**What they do**:
- Manage database containers
- Configure persistent storage
- Handle connection URLs
- Set up authentication

### 💾 Cache Plugins

High-speed in-memory data stores.

| Plugin | Description | Service Kind | Status |
|--------|-------------|--------------|--------|
| [Redis](plugins/cache/redis/) | In-memory cache and session store | `cache.redis` | ✅ Ready |
| [Memcached](plugins/cache/memcached/) | Distributed memory caching | `cache.memcached` | 🚧 Coming Soon |

**What they do**:
- Provide in-memory caching
- Session storage
- Rate limiting
- Temporary data storage

### 📬 Message Queue Plugins

Asynchronous messaging between services.

| Plugin | Description | Service Kind | Status |
|--------|-------------|--------------|--------|
| [RabbitMQ](plugins/message_queue/rabbitmq/) | Robust message broker | `queue.rabbitmq` | 🚧 Coming Soon |
| [Apache Kafka](plugins/message_queue/kafka/) | Distributed streaming platform | `queue.kafka` | 🚧 Coming Soon |

**What they do**:
- Enable pub/sub messaging
- Task queues
- Event streaming
- Microservice communication

### 🔌 Proxy Plugins

Reverse proxies and load balancers.

| Plugin | Description | Service Kind | Status |
|--------|-------------|--------------|--------|
| [Nginx](plugins/proxy/nginx/) | High-performance web server | `proxy.nginx` | 🚧 Coming Soon |
| [Traefik](plugins/proxy/traefik/) | Modern reverse proxy | `proxy.traefik` | 🚧 Coming Soon |

**What they do**:
- Route HTTP traffic
- Load balancing
- SSL/TLS termination
- Rate limiting

### 🔧 CI/CD Plugins

Integrate deployment into CI/CD pipelines.

| Plugin | Description | Service Kind |
|--------|-------------|--------------|
| [Jenkins](plugins/cicd/jenkins/) | Automation server | `ci.jenkins` |
| [GitLab CI](plugins/cicd/gitlab-ci/) | GitLab integrated CI/CD | N/A |

**What they do**:
- Generate pipeline definitions
- Configure deployment triggers
- Manage artifacts and credentials
- Create deployment jobs

### ☸️ Orchestration Plugins

Deploy to different orchestration platforms.

| Plugin | Description | Target Type |
|--------|-------------|-------------|
| [Kubernetes](plugins/orchestration/kubernetes/) | Container orchestration | `k8s.cluster` |
| [Docker Swarm](plugins/orchestration/docker-swarm/) | Docker native orchestration | `swarm.cluster` |

**What they do**:
- Transform stacks to platform format
- Manage cluster resources
- Configure auto-scaling
- Handle rolling updates

## Quick Start

### Installing a Plugin

**Using ARFNI CLI**:
```bash
# Install by name (from central registry)
arfni plugin install django

# Install from GitHub
arfni plugin install github.com/arfni/arfni-plugins/plugins/frameworks/django
```

**Using ARFNI GUI**:
1. Open Settings > Plugins
2. Enter plugin name or GitHub URL
3. Click Install
4. Plugin appears in NodePalette

### Using a Plugin

**Framework Plugin (Django)**:
```yaml
# stack.yaml
apiVersion: v0.1
name: my-django-app
targets:
  local:
    type: docker-desktop

services:
  api:
    kind: docker.container
    target: local
    spec:
      build: ./backend  # Django project detected automatically
      ports: ["8000:8000"]
      env:
        SECRET_KEY: ${DJANGO_SECRET_KEY}
```

**Infrastructure Plugin (Nginx)**:
```yaml
services:
  api:
    kind: docker.container
    spec:
      build: ./backend
      # Internal port only

  nginx:
    kind: proxy.nginx  # Nginx plugin service kind
    spec:
      upstreams:
        - service: api
          port: 8000
      ssl:
        enabled: true
      ports: ["80:80", "443:443"]
```

## Plugin Structure

Every plugin follows this structure:

```
plugin-name/
├── plugin.yaml          # Plugin manifest (required)
├── README.md            # Documentation (required)
├── LICENSE              # License file (required)
├── frameworks/          # Framework definitions (framework plugins)
├── templates/           # File templates
├── hooks/               # Lifecycle scripts
├── configs/             # Default configurations
└── examples/            # Example projects
```

### Minimal Plugin

```yaml
# plugin.yaml
name: my-plugin
version: 1.0.0
category: framework  # or: infrastructure, cicd, orchestration
description: My awesome plugin
author: your-name

provides:
  frameworks: [my-framework]  # or service_kinds, target_types

hooks:
  pre_deploy: hooks/setup.sh
```

## Contributing

We welcome contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for details.

### Adding a New Plugin

1. **Fork this repository**

2. **Create plugin directory**:
   ```bash
   mkdir -p plugins/frameworks/my-plugin
   cd plugins/frameworks/my-plugin
   ```

3. **Create required files**:
   - `plugin.yaml` - Plugin manifest
   - `README.md` - Usage documentation
   - `LICENSE` - MIT recommended

4. **Test locally**:
   ```bash
   arfni plugin install ./plugins/frameworks/my-plugin
   ```

5. **Submit Pull Request**:
   - Clear description of plugin functionality
   - Include usage examples
   - Ensure tests pass

### Plugin Categories

Choose the appropriate category for your plugin:

- **`framework`**: Helps build/containerize application code
  - Example: Django, React, Spring Boot

- **`infrastructure`**: Adds infrastructure services
  - Example: Nginx, Redis, PostgreSQL

- **`cicd`**: CI/CD pipeline integration
  - Example: Jenkins, GitLab CI

- **`orchestration`**: Deployment platform support
  - Example: Kubernetes, Docker Swarm

## Plugin Registry

All plugins are indexed in [`registry/index.json`](registry/index.json) for discovery and search.

**Search plugins**:
```bash
arfni plugin search <keyword>
```

**Browse registry**:
https://raw.githubusercontent.com/arfni/arfni-plugins/main/registry/index.json

## Documentation

- **[Plugin Specification](../UNIFIED_PLUGIN_SPECIFICATION.md)** - Complete plugin reference
- **[Use Cases](../PLUGIN_USE_CASES.md)** - Real-world scenarios
- **[Contributing Guide](CONTRIBUTING.md)** - How to contribute

## Community

- **GitHub Discussions**: [Ask questions, share plugins](https://github.com/arfni/arfni/discussions)
- **Discord**: [Join our community](https://discord.gg/arfni)
- **Issues**: [Report bugs, request features](https://github.com/arfni/arfni-plugins/issues)

## License

MIT License - see individual plugin directories for specific licenses.

## Acknowledgments

Special thanks to all contributors who have helped build this plugin ecosystem!

---

**Made with ❤️ by the ARFNI Community**
