# ARFNI 플러그인 개발 가이드

> 기여자들을 위한 플러그인 개발 실전 가이드

## 📋 목차

- [플러그인이란?](#플러그인이란)
- [Django 플러그인 분석](#django-플러그인-분석)
- [개발에 필요한 것](#개발에-필요한-것)
- [파일 구조 이해하기](#파일-구조-이해하기)
- [단계별 개발 가이드](#단계별-개발-가이드)
- [실전 예제](#실전-예제)

---

## 플러그인이란?

ARFNI 플러그인은 **새로운 프레임워크나 인프라를 추가**하기 위한 패키지입니다.

### 핵심 개념

**코드를 짜는 게 아니라, 설정 파일을 작성합니다!**

- ❌ Go, Rust, React 코드 작성 필요 없음
- ✅ YAML 설정 파일 작성
- ✅ Bash 스크립트 작성 (선택)
- ✅ Dockerfile 템플릿 작성 (선택)

ARFNI가 이 설정들을 읽어서 자동으로 처리해줍니다.

---

## Django 플러그인 분석

실제 Django 플러그인을 보면서 이해해봅시다.

### 📁 파일 구조

```
plugins/frameworks/django/
├── plugin.yaml                    # 1️⃣ 메인 설정 파일 (필수)
├── README.md                      # 2️⃣ 사용 설명서 (필수)
├── LICENSE                        # 3️⃣ 라이선스 (필수)
├── frameworks/
│   └── django.yaml               # 4️⃣ GUI 자동 감지 설정 (Framework만)
├── templates/
│   └── Dockerfile.django.tmpl    # 5️⃣ Dockerfile 템플릿 (선택)
└── hooks/
    ├── migrate-database.sh        # 6️⃣ 자동화 스크립트들 (선택)
    ├── collect-static.sh
    ├── create-superuser.sh
    └── health-check.sh
```

### 필수 파일 vs 선택 파일

| 파일 | 필수? | 용도 |
|------|-------|------|
| `plugin.yaml` | ✅ 필수 | 플러그인 메타데이터 & 서비스 정의 |
| `README.md` | ✅ 필수 | 사용 설명서 |
| `LICENSE` | ✅ 필수 | 라이선스 (MIT 권장) |
| `frameworks/*.yaml` | ⚠️ Framework만 | GUI 자동 감지용 |
| `templates/*.tmpl` | ❌ 선택 | 파일 템플릿 (Dockerfile 등) |
| `hooks/*.sh` | ❌ 선택 | 자동화 스크립트 |

---

## 개발에 필요한 것

### 필수 지식

1. **YAML 문법** - 설정 파일 작성용
2. **Bash 스크립트** - 자동화 훅 작성용 (기본만 알아도 됨)
3. **Docker 기초** - 컨테이너 이해
4. **해당 프레임워크 지식** - Django, React 등

### 필요한 도구

- 텍스트 에디터 (VS Code 추천)
- Docker Desktop
- Git
- ARFNI CLI (테스트용)

---

## 파일 구조 이해하기

### 1️⃣ plugin.yaml - 메인 설정 파일

플러그인의 핵심! 모든 것이 여기 정의됩니다.

```yaml
# ========================================
# 기본 정보 (필수)
# ========================================
apiVersion: v0.1
name: django                     # 플러그인 이름 (소문자, 하이픈만)
version: 1.0.0                   # 버전 (시맨틱 버저닝)
category: framework              # 카테고리: framework, infrastructure, cicd, orchestration
description: Django 웹 프레임워크
author: arfni-community
homepage: https://github.com/arfni/arfni-plugins
license: MIT

# ========================================
# 제공 기능 (필수)
# ========================================
provides:
  frameworks:                    # Framework 플러그인만
    - django
  service_kinds: []              # Infrastructure/CI/CD 플러그인만
  target_types: []               # Orchestration 플러그인만

# ========================================
# 요구사항 (선택)
# ========================================
requires:
  arfni_version: ">=0.2.0"
  docker_version: ">=20.10"

# ========================================
# 사용자 입력 (선택)
# ========================================
inputs:
  python_version:
    description: "Python 버전 선택"
    type: select                 # 드롭다운
    options: ["3.9", "3.10", "3.11", "3.12"]
    default: "3.11"
    required: true

  django_port:
    description: "Django 서버 포트"
    type: number                 # 숫자 입력
    default: 8000
    required: true

  django_secret_key:
    description: "Django SECRET_KEY"
    type: secret                 # 비밀번호 입력 (마스킹됨)
    required: true
    env_var: DJANGO_SECRET_KEY   # 환경 변수로 내보냄

  enable_redis:
    description: "Redis 캐시 사용"
    type: boolean                # 체크박스
    default: false

# ========================================
# 서비스 정의 (핵심!)
# ========================================
contributes:
  services:
    # Django 앱 컨테이너
    django:
      kind: docker.container
      target: "{{target}}"
      spec:
        build:
          context: "{{project_dir}}"
          dockerfile: Dockerfile
        ports:
          - "{{django_port}}:8000"
        environment:
          DJANGO_SECRET_KEY: "{{django_secret_key}}"
          DATABASE_URL: "postgresql://postgres:{{postgres_password}}@postgres:5432/{{db_name}}"
        volumes:
          - host: django_static
            mount: /app/static
        depends_on:
          - postgres
        health:
          httpGet:
            path: /health/
            port: 8000
          initialDelaySeconds: 30

    # PostgreSQL 데이터베이스
    postgres:
      kind: docker.container
      target: "{{target}}"
      spec:
        image: "postgres:15-alpine"
        environment:
          POSTGRES_DB: "{{db_name}}"
          POSTGRES_PASSWORD: "{{postgres_password}}"
        volumes:
          - host: postgres_data
            mount: /var/lib/postgresql/data

  # 볼륨 정의
  volumes:
    - postgres_data
    - django_static

# ========================================
# 라이프사이클 훅 (선택)
# ========================================
hooks:
  pre_deploy:                    # 배포 전
    script: hooks/migrate-database.sh
    description: "데이터베이스 마이그레이션"

  post_build:                    # 빌드 후
    script: hooks/collect-static.sh
    description: "정적 파일 수집"

  post_deploy:                   # 배포 후
    script: hooks/create-superuser.sh
    description: "관리자 계정 생성"

  health_check:                  # 헬스 체크
    script: hooks/health-check.sh
    description: "서비스 헬스 체크"

# ========================================
# 검색 태그 (선택)
# ========================================
tags:
  - python
  - django
  - backend
  - postgresql
  - redis
```

### 2️⃣ frameworks/django.yaml - GUI 자동 감지

**Framework 카테고리 플러그인만 필요합니다!**

GUI에서 프로젝트 폴더를 드래그하면, ARFNI가 이 파일을 보고 자동으로 프레임워크를 감지합니다.

```yaml
name: django
display_name: Django
description: Python 웹 프레임워크
icon: django.svg                # 선택: 아이콘 파일

# ========================================
# 자동 감지 규칙
# ========================================
detection:
  # 이 파일들이 있으면 Django로 인식
  files:
    - manage.py
    - requirements.txt

  # 파일 내용도 체크
  file_content:
    - file: requirements.txt
      contains: "Django"          # requirements.txt에 "Django"가 있어야 함

  # 디렉토리 패턴
  directories:
    - "*/settings.py"             # settings.py가 어딘가에 있어야 함

# ========================================
# GUI 속성 폼
# ========================================
properties:
  python_version:
    label: "Python 버전"
    type: select
    options: ["3.9", "3.10", "3.11", "3.12"]
    default: "3.11"

  enable_postgres:
    label: "PostgreSQL 추가"
    type: boolean
    default: true

# ========================================
# Dockerfile 템플릿 (GUI용)
# ========================================
dockerfile:
  template: |
    FROM python:{{python_version}}-slim
    WORKDIR /app
    COPY requirements.txt .
    RUN pip install -r requirements.txt
    COPY . .
    EXPOSE {{port | default: 8000}}
    CMD ["python", "manage.py", "runserver", "0.0.0.0:{{port | default: 8000}}"]
```

### 3️⃣ templates/Dockerfile.django.tmpl - Dockerfile 템플릿

더 복잡한 Dockerfile이 필요하면 별도 파일로 분리합니다.

```dockerfile
# ========================================
# 빌드 스테이지
# ========================================
FROM python:{{python_version}}-slim AS build

WORKDIR /app

# 시스템 패키지 설치
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Python 의존성 설치
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ========================================
# 프로덕션 스테이지
# ========================================
FROM python:{{python_version}}-slim

WORKDIR /app

# 런타임 패키지만 설치
RUN apt-get update && apt-get install -y \
    libpq5 \
    && rm -rf /var/lib/apt/lists/*

# 빌드 스테이지에서 복사
COPY --from=build /usr/local/lib/python{{python_version}}/site-packages /usr/local/lib/python{{python_version}}/site-packages
COPY --from=build /usr/local/bin /usr/local/bin

# 애플리케이션 코드 복사
COPY . .

# non-root 사용자 생성
RUN useradd -m -u 1000 django && \
    chown -R django:django /app

USER django

EXPOSE {{django_port | default: 8000}}

CMD ["gunicorn", "--bind", "0.0.0.0:{{django_port | default: 8000}}", "{{project_name}}.wsgi:application"]
```

**템플릿 변수 사용법:**

- `{{variable_name}}` - 변수 삽입
- `{{variable | default: 8000}}` - 기본값 설정
- `{{if condition}}...{{end}}` - 조건문
- `{{range items}}...{{end}}` - 반복문

### 4️⃣ hooks/*.sh - 자동화 스크립트

각 단계에서 실행될 Bash 스크립트입니다.

**hooks/migrate-database.sh** (pre_deploy):

```bash
#!/bin/bash
set -e  # 에러 발생시 중단

echo "🔄 데이터베이스 마이그레이션 중..."

# PostgreSQL이 준비될 때까지 대기
until docker compose exec -T postgres pg_isready; do
    echo "⏳ PostgreSQL 준비 대기 중..."
    sleep 1
done

# 마이그레이션 실행
docker compose run --rm django python manage.py migrate --noinput

echo "✅ 마이그레이션 완료"
```

**hooks/collect-static.sh** (post_build):

```bash
#!/bin/bash
set -e

echo "🔄 정적 파일 수집 중..."

# collectstatic 실행
docker compose run --rm django python manage.py collectstatic --noinput --clear

echo "✅ 정적 파일 수집 완료"
```

**hooks/create-superuser.sh** (post_deploy):

```bash
#!/bin/bash
set -e

echo "👤 관리자 계정 생성 중..."

# 환경 변수 체크
if [ -z "$DJANGO_SUPERUSER_USERNAME" ]; then
    export DJANGO_SUPERUSER_USERNAME="admin"
fi

if [ -z "$DJANGO_SUPERUSER_EMAIL" ]; then
    export DJANGO_SUPERUSER_EMAIL="admin@example.com"
fi

if [ -z "$DJANGO_SUPERUSER_PASSWORD" ]; then
    # 비밀번호 자동 생성
    export DJANGO_SUPERUSER_PASSWORD=$(openssl rand -base64 12)
    echo "📝 자동 생성된 비밀번호: $DJANGO_SUPERUSER_PASSWORD"
fi

# 슈퍼유저 생성 (이미 있으면 스킵)
docker compose exec -T django python manage.py createsuperuser \
    --noinput \
    --username "$DJANGO_SUPERUSER_USERNAME" \
    --email "$DJANGO_SUPERUSER_EMAIL" \
    2>/dev/null || echo "⚠️  관리자 계정이 이미 존재합니다"

echo "✅ 관리자 계정 준비 완료"
```

**hooks/health-check.sh** (health_check):

```bash
#!/bin/bash
set -e

echo "🏥 헬스 체크 중..."

# HTTP 상태 코드 체크
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health/ || echo "000")

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Django가 정상 작동 중입니다"
    exit 0
else
    echo "❌ Django가 응답하지 않습니다 (HTTP $HTTP_CODE)"
    exit 1
fi
```

**훅 실행 타이밍:**

| 훅 | 실행 시점 |
|---------|----------|
| `pre_generate` | stack.yaml 생성 전 |
| `post_generate` | stack.yaml 생성 후 |
| `pre_build` | Docker 빌드 전 |
| `post_build` | Docker 빌드 후 |
| `pre_deploy` | 배포 전 |
| `deploy` | 배포 (커스텀 배포 로직) |
| `post_deploy` | 배포 후 |
| `health_check` | 헬스 체크 |

---

## 단계별 개발 가이드

### Step 1: 플러그인 폴더 생성

```bash
cd plugins/frameworks/
mkdir fastapi
cd fastapi
```

### Step 2: 필수 파일 3개 생성

#### plugin.yaml

```yaml
apiVersion: v0.1
name: fastapi
version: 1.0.0
category: framework
description: FastAPI 웹 프레임워크
author: your-name
homepage: https://github.com/arfni/arfni-plugins
license: MIT

provides:
  frameworks:
    - fastapi

inputs:
  python_version:
    description: "Python 버전"
    type: select
    options: ["3.9", "3.10", "3.11", "3.12"]
    default: "3.11"

  api_port:
    description: "API 포트"
    type: number
    default: 8000

contributes:
  services:
    fastapi:
      kind: docker.container
      target: "{{target}}"
      spec:
        build:
          context: "{{project_dir}}"
          dockerfile: Dockerfile
        ports:
          - "{{api_port}}:8000"
        environment:
          PYTHONUNBUFFERED: "1"

tags:
  - python
  - fastapi
  - api
```

#### README.md

```markdown
# FastAPI Plugin

FastAPI 웹 프레임워크를 위한 ARFNI 플러그인입니다.

## 설치

```bash
arfni plugin install fastapi
```

## 사용법

```bash
cd my-fastapi-project
arfni init
arfni build
arfni deploy
```

## 요구사항

- Python 3.9+
- FastAPI
- Uvicorn
```

#### LICENSE

```
MIT License

Copyright (c) 2024 [Your Name]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction...
```

### Step 3: Framework 자동 감지 추가 (Framework만)

```bash
mkdir frameworks
```

**frameworks/fastapi.yaml:**

```yaml
name: fastapi
display_name: FastAPI
description: FastAPI 웹 프레임워크

detection:
  files:
    - main.py
    - requirements.txt

  file_content:
    - file: requirements.txt
      contains: "fastapi"
    - file: main.py
      contains: "from fastapi import"

properties:
  python_version:
    label: "Python 버전"
    type: select
    options: ["3.9", "3.10", "3.11", "3.12"]
    default: "3.11"

dockerfile:
  template: |
    FROM python:{{python_version}}-slim
    WORKDIR /app
    COPY requirements.txt .
    RUN pip install -r requirements.txt
    COPY . .
    EXPOSE 8000
    CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Step 4: 훅 추가 (선택)

필요하면 자동화 스크립트 추가:

```bash
mkdir hooks
```

**hooks/health-check.sh:**

```bash
#!/bin/bash
set -e

echo "🏥 FastAPI 헬스 체크..."

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health)

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ FastAPI 정상"
    exit 0
else
    echo "❌ FastAPI 오류"
    exit 1
fi
```

```bash
chmod +x hooks/health-check.sh
```

### Step 5: 로컬 테스트

```bash
# 로컬에서 플러그인 설치
arfni plugin install ./plugins/frameworks/fastapi

# 테스트 프로젝트에서 사용
cd ~/test-fastapi-project
arfni init
arfni build
arfni deploy
```

### Step 6: PR 제출

```bash
git checkout -b feat/add-fastapi-plugin
git add plugins/frameworks/fastapi/
git commit -m "feat: FastAPI 플러그인 추가"
git push origin feat/add-fastapi-plugin
```

GitHub에서 PR 생성!

---

## 실전 예제

### 예제 1: 간단한 React 플러그인

**plugin.yaml만으로 충분:**

```yaml
apiVersion: v0.1
name: react
version: 1.0.0
category: framework
description: React 프론트엔드 프레임워크
author: arfni-community
homepage: https://github.com/arfni/arfni-plugins
license: MIT

provides:
  frameworks:
    - react

inputs:
  node_version:
    description: "Node.js 버전"
    type: select
    options: ["18", "20", "21"]
    default: "20"

  dev_port:
    description: "개발 서버 포트"
    type: number
    default: 3000

contributes:
  services:
    react:
      kind: docker.container
      target: "{{target}}"
      spec:
        build:
          context: "{{project_dir}}"
          dockerfile: Dockerfile
        ports:
          - "{{dev_port}}:3000"
        volumes:
          - host: "{{project_dir}}"
            mount: /app
        environment:
          NODE_ENV: development

tags:
  - javascript
  - react
  - frontend
```

**frameworks/react.yaml:**

```yaml
name: react
display_name: React
description: React 프론트엔드 라이브러리

detection:
  files:
    - package.json

  file_content:
    - file: package.json
      contains: "react"

  directories:
    - src
    - public

properties:
  node_version:
    label: "Node.js 버전"
    type: select
    options: ["18", "20", "21"]
    default: "20"

dockerfile:
  template: |
    FROM node:{{node_version}}-alpine
    WORKDIR /app
    COPY package*.json ./
    RUN npm install
    COPY . .
    EXPOSE 3000
    CMD ["npm", "start"]
```

### 예제 2: PostgreSQL 인프라 플러그인

**plugin.yaml:**

```yaml
apiVersion: v0.1
name: postgresql
version: 1.0.0
category: infrastructure
description: PostgreSQL 데이터베이스
author: arfni-community
homepage: https://github.com/arfni/arfni-plugins
license: MIT

provides:
  service_kinds:
    - db.postgres

inputs:
  postgres_version:
    description: "PostgreSQL 버전"
    type: select
    options: ["13", "14", "15", "16"]
    default: "15"

  db_name:
    description: "데이터베이스 이름"
    type: text
    default: "myapp"

  db_password:
    description: "데이터베이스 비밀번호"
    type: secret
    required: true
    env_var: POSTGRES_PASSWORD

contributes:
  services:
    postgres:
      kind: db.postgres
      target: "{{target}}"
      spec:
        image: "postgres:{{postgres_version}}-alpine"
        ports:
          - "5432:5432"
        environment:
          POSTGRES_DB: "{{db_name}}"
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: "{{db_password}}"
        volumes:
          - host: postgres_data
            mount: /var/lib/postgresql/data
        health:
          test: ["CMD-SHELL", "pg_isready -U postgres"]
          interval: 10s
          timeout: 5s
          retries: 5

  volumes:
    - postgres_data

tags:
  - database
  - postgresql
  - sql
```

**hooks/create-backup.sh:**

```bash
#!/bin/bash
set -e

echo "💾 PostgreSQL 백업 생성 중..."

BACKUP_FILE="/backups/backup_$(date +%Y%m%d_%H%M%S).sql"

docker compose exec -T postgres pg_dump -U postgres {{db_name}} > "$BACKUP_FILE"

gzip "$BACKUP_FILE"

echo "✅ 백업 완료: $BACKUP_FILE.gz"
```

---

## 핵심 정리

### ✅ 기여자가 해야 할 일

1. **YAML 파일 작성** - plugin.yaml, frameworks/*.yaml
2. **Bash 스크립트 작성** (선택) - hooks/*.sh
3. **문서 작성** - README.md
4. **테스트** - 로컬에서 플러그인 설치 및 테스트
5. **PR 제출** - GitHub에 Pull Request

### ❌ 기여자가 하지 않아도 되는 일

- Go 코드 수정 (ARFNI CLI)
- Rust 코드 수정 (ARFNI GUI)
- React 코드 수정 (ARFNI GUI)
- 복잡한 프로그래밍

### 🎯 개발 흐름

```
1. YAML 파일 작성 (설정)
   ↓
2. Bash 스크립트 작성 (자동화)
   ↓
3. 로컬 테스트
   ↓
4. PR 제출
   ↓
5. 리뷰 받기
   ↓
6. 머지되면 자동으로 레지스트리 업데이트
```

---

## 자주 묻는 질문

### Q: 프로그래밍을 잘 못하는데 기여할 수 있나요?

**A:** 네! YAML과 Bash 기초만 알면 됩니다. 복잡한 프로그래밍은 필요 없어요.

### Q: Dockerfile을 꼭 만들어야 하나요?

**A:** 아니요. `frameworks/*.yaml`에 간단한 템플릿만 넣어도 됩니다. 복잡한 경우에만 별도 템플릿 파일을 만들면 돼요.

### Q: 훅(hooks)을 꼭 만들어야 하나요?

**A:** 아니요. 선택사항입니다. 자동화가 필요 없으면 만들지 않아도 됩니다.

### Q: 내가 만든 플러그인이 제대로 작동하는지 어떻게 확인하나요?

**A:**
```bash
# 로컬 설치
arfni plugin install ./my-plugin

# 테스트 프로젝트에서 사용
cd test-project
arfni init
arfni build
arfni deploy
```

### Q: 플러그인 업데이트는 어떻게 하나요?

**A:** `plugin.yaml`의 `version`을 올리고 다시 PR 제출하면 됩니다.

---

## 도움말

- **문서**: [CONTRIBUTING.md](CONTRIBUTING.md), [PLUGIN_SPECIFICATION.md](PLUGIN_SPECIFICATION.md)
- **예제**: [plugins/frameworks/django/](plugins/frameworks/django/)
- **질문**: GitHub Issues 또는 Discussions

---

**행운을 빕니다! 🚀**
