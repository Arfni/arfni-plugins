# ARFNI 플러그인 기여 가이드

[English](README.md) | **한국어**

ARFNI 플러그인 레포지토리에 오신 것을 환영합니다! 이 가이드는 ARFNI 생태계에 새로운 플러그인을 기여하는 방법을 설명합니다.

## 목차

- [플러그인이란?](#플러그인이란)
- [플러그인 카테고리](#플러그인-카테고리)
- [플러그인 구조](#플러그인-구조)
- [plugin.yaml 작성하기](#pluginyaml-작성하기)
- [템플릿 파일](#템플릿-파일)
- [라이프사이클 훅](#라이프사이클-훅)
- [플러그인 개발 단계](#플러그인-개발-단계)
- [검증 및 테스트](#검증-및-테스트)
- [제출하기](#제출하기)

## 플러그인이란?

ARFNI 플러그인은 ARFNI 플랫폼에 새로운 프레임워크, 데이터베이스, 서비스를 추가할 수 있게 해주는 확장 모듈입니다. 플러그인을 통해:

- 새로운 프레임워크(Django, Express, Spring 등) 지원 추가
- 데이터베이스 및 캐시 서비스 통합
- 프로젝트 자동 감지 및 설정
- Docker 컨테이너 자동 생성
- GUI 캔버스에서 시각적 연결 지원

## 플러그인 카테고리

플러그인은 8가지 카테고리로 분류됩니다:

| 카테고리 | 설명 | 예시 |
|---------|------|------|
| `framework` | 애플리케이션 프레임워크 | Django, Express, Spring Boot |
| `database` | 데이터베이스 시스템 | PostgreSQL, MySQL, MongoDB |
| `cache` | 인메모리 캐시 | Redis, Memcached |
| `message_queue` | 메시지 큐 시스템 | RabbitMQ, Kafka |
| `proxy` | 리버스 프록시/로드밸런서 | Nginx, Traefik |
| `cicd` | CI/CD 파이프라인 | GitHub Actions, Jenkins |
| `orchestration` | 배포 플랫폼 | Kubernetes, Docker Swarm |
| `infrastructure` | 인프라 도구 | Terraform, Ansible |

## 플러그인 구조

플러그인은 다음과 같은 디렉토리 구조를 가집니다:

```
plugins/{category}/{plugin-name}/
├── plugin.yaml              # 플러그인 매니페스트 (필수)
├── README.md                # 플러그인 문서 (필수)
├── icon.png                 # 플러그인 아이콘 (필수)
├── LICENSE                  # 라이선스 파일 (선택)
├── CHANGELOG.md             # 변경 이력 (선택)
├── templates/               # 템플릿 파일 디렉토리
│   ├── Dockerfile.tmpl
│   └── config.tmpl
├── hooks/                   # 라이프사이클 훅 스크립트
│   ├── pre-deploy.sh
│   ├── post-deploy.sh
│   └── health-check.sh
├── frameworks/              # GUI 설정 (프레임워크 플러그인용)
│   └── {framework}.yaml
└── examples/                # 예제 프로젝트
    └── basic-example/
```

### 필수 파일

1. **plugin.yaml** - 플러그인의 메타데이터와 설정
2. **README.md** - 사용법과 설명
3. **icon.png** - GUI에 표시될 아이콘 (권장 크기: 128x128px)

### 선택 파일

- **templates/** - 사용자 프로젝트에 생성될 파일 템플릿
- **hooks/** - 라이프사이클 이벤트 시 실행될 스크립트
- **frameworks/** - 프레임워크 플러그인의 GUI 설정
- **examples/** - 참고할 수 있는 예제 프로젝트

## plugin.yaml 작성하기

`plugin.yaml`은 플러그인의 핵심 매니페스트 파일입니다. Django 플러그인을 참고하여 각 섹션을 설명합니다.

### 1. 메타데이터 (필수)

```yaml
apiVersion: v0.1              # API 버전 (현재 v0.1)
name: django                  # 플러그인 ID (소문자, 공백 없이)
displayName: Django           # 표시될 이름
version: 1.0.0               # 시맨틱 버저닝
category: framework          # 플러그인 카테고리
description: Production-ready Django web framework
author: arfni-community      # 작성자
homepage: https://github.com/Arfni/arfni-plugins/tree/main/plugins/frameworks/django
license: MIT                 # 라이선스
icon: icon.png              # 아이콘 파일 경로
```

### 2. 자동 감지 (선택)

프로젝트를 자동으로 감지하는 규칙을 정의합니다:

```yaml
detection:
  enabled: true
  priority: 15                # 감지 우선순위 (높을수록 먼저)
  required_files:
    - manage.py               # 필수 파일 목록
    - requirements.txt
  file_content_patterns:      # 파일 내용 패턴
    requirements.txt:
      contains: ["django", "Django"]
```

### 3. 제공 항목 (필수)

플러그인이 제공하는 항목을 선언합니다:

```yaml
provides:
  frameworks:                 # 프레임워크 플러그인
    - django
  service_kinds:              # 데이터베이스 플러그인 (예: PostgreSQL)
    - db.postgres
```

### 4. 요구사항 (선택)

```yaml
requires:
  arfni_version: ">=0.2.0"
  docker_version: ">=20.10"
```

### 5. 사용자 입력 (필수)

사용자가 설정할 수 있는 파라미터:

```yaml
inputs:
  python_version:
    description: "Python runtime version"
    type: select              # 타입: select, text, number, boolean, secret
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
    type: secret              # 비밀 정보는 secret 타입 사용
    required: true
    env_var: DJANGO_SECRET_KEY  # 자동으로 환경변수로 설정됨

  database_url:
    description: "Database connection URL"
    type: text
    placeholder: "postgresql://user:pass@postgres:5432/dbname"
    required: false
    env_var: DATABASE_URL     # 캔버스에서 연결 시 자동 설정
```

**입력 타입:**
- `select` - 드롭다운 선택
- `text` - 텍스트 입력
- `number` - 숫자 입력
- `boolean` - 체크박스
- `secret` - 비밀번호/토큰 (암호화됨)

### 6. 기여 항목 (필수)

stack.yaml에 추가될 서비스 정의:

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

  canvas:                     # GUI 캔버스 설정
    nodeType: django
    label: Django
    description: "Python web framework"
    category: runtime
    ports:
      - name: http
        port: 8000
        protocol: tcp
    connections:
      inputs:                 # 이 노드가 받을 수 있는 연결
        - type: database
          name: database
          protocol: any
          env_var: DATABASE_URL
        - type: cache
          name: redis
          protocol: tcp
          env_var: REDIS_URL
      outputs:                # 이 노드가 제공하는 연결
        - type: api
          name: api
          protocol: http

  volumes:                    # 영구 볼륨
    - postgres_data
```

### 7. 라이프사이클 훅 (선택)

특정 시점에 실행될 스크립트:

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

**사용 가능한 훅:**
- `pre_generate` - 설정 생성 전
- `post_generate` - 설정 생성 후
- `pre_build` - Docker 빌드 전
- `post_build` - Docker 빌드 후
- `pre_deploy` - 배포 전
- `post_deploy` - 배포 후
- `health_check` - 헬스 체크

### 8. 템플릿 (선택)

사용자 프로젝트에 생성될 파일:

```yaml
templates:
  - source: templates/Dockerfile.django.tmpl
    target: "{{project_dir}}/Dockerfile"
    description: "Multi-stage Dockerfile for Django"
    overwrite: false          # 기존 파일 덮어쓰지 않음

  - source: templates/settings_production.py.tmpl
    target: "{{project_dir}}/settings_production.py"
    description: "Production settings"
    overwrite: false
```

### 9. 문서 (선택)

```yaml
documentation:
  readme: README.md
  getting_started: docs/getting-started.md
  troubleshooting: docs/troubleshooting.md
```

### 10. 태그 (선택)

검색 및 발견을 위한 태그:

```yaml
tags:
  - python
  - django
  - backend
  - web-framework
  - orm
  - rest-api
```

### 11. 예제 (선택)

```yaml
examples:
  - name: basic-blog
    description: "Simple Django blog application"
    path: examples/basic-blog/

  - name: rest-api
    description: "Django REST API with JWT"
    path: examples/rest-api/
```

### 12. 변경 이력 (선택)

```yaml
changelog: CHANGELOG.md
```

## 템플릿 파일

템플릿 파일은 Go 템플릿 문법을 사용하여 변수를 치환합니다.

### 변수 사용

```dockerfile
# templates/Dockerfile.tmpl
FROM python:{{python_version}}-slim

WORKDIR /app

# 기본값 사용
ENV WORKERS={{default "4" .gunicorn_workers}}

EXPOSE {{django_port}}

CMD ["gunicorn", "--workers", "{{gunicorn_workers}}", "--bind", "0.0.0.0:8000"]
```

### 사용 가능한 변수

- `inputs`에 정의된 모든 변수
- `{{project_dir}}` - 프로젝트 디렉토리 경로
- `{{target}}` - 빌드 타겟
- `{{default "기본값" .변수명}}` - 기본값 지정

## 라이프사이클 훅

훅 스크립트는 Bash로 작성되며, 특정 이벤트 시점에 실행됩니다.

### 예시: 데이터베이스 마이그레이션 훅

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

### 예시: 헬스 체크 훅

```bash
#!/bin/bash
# hooks/health-check.sh

set -e

# HTTP 엔드포인트 체크
curl -f http://localhost:8000/health/ || exit 1

# 데이터베이스 연결 체크
python manage.py check --database default || exit 1

echo "Health check passed!"
```

### 훅 스크립트 작성 시 주의사항

1. **실행 권한**: 스크립트에 실행 권한 부여 (`chmod +x hooks/*.sh`)
2. **에러 처리**: `set -e`로 에러 시 중단
3. **출력**: 진행 상황을 명확히 출력
4. **환경변수**: `env_var`로 정의된 변수 사용 가능
5. **종료 코드**: 성공 시 0, 실패 시 1 반환

## 플러그인 개발 단계

### 1단계: 플러그인 디렉토리 생성

```bash
# 적절한 카테고리 선택
mkdir -p plugins/frameworks/myframework
cd plugins/frameworks/myframework
```

### 2단계: plugin.yaml 작성

```bash
# 기본 템플릿 복사 (Django 플러그인 참고)
cp -r ../django/plugin.yaml .
# 내용 수정
```

### 3단계: README.md 작성

사용자를 위한 문서를 작성합니다:

```markdown
# MyFramework Plugin

MyFramework를 ARFNI에서 사용하기 위한 플러그인입니다.

## 사용법

1. ARFNI CLI 설치
2. 프로젝트 디렉토리에서 `arfni init` 실행
3. MyFramework 선택

## 요구사항

- MyFramework 2.0+
- Docker 20.10+

## 설정

...
```

### 4단계: 아이콘 추가

128x128px PNG 아이콘을 `icon.png`로 저장합니다.

### 5단계: 템플릿 작성 (필요한 경우)

```bash
mkdir templates
# Dockerfile, 설정 파일 등 작성
```

### 6단계: 훅 스크립트 작성 (필요한 경우)

```bash
mkdir hooks
# 라이프사이클 스크립트 작성
chmod +x hooks/*.sh
```

### 7단계: 로컬 테스트

```bash
# ARFNI CLI로 로컬 테스트
arfni plugin validate ./plugins/frameworks/myframework
```

## 검증 및 테스트

### 자동 검증

플러그인을 커밋하면 GitHub Actions가 자동으로 검증합니다:

- `apiVersion` 형식 확인 (v0.1)
- 필수 필드 존재 확인
- 카테고리 유효성 검증
- 버전 형식 검증 (시맨틱 버저닝)
- `provides` 구조 검증

### 수동 테스트

1. **로컬 검증**
   ```bash
   node scripts/generate-registry.js
   ```

2. **실제 프로젝트 테스트**
   ```bash
   cd /path/to/test-project
   arfni init
   # 플러그인 선택 및 테스트
   ```

3. **Docker 빌드 테스트**
   ```bash
   docker build -t test-image .
   docker run -p 8000:8000 test-image
   ```

### 체크리스트

플러그인 제출 전 확인사항:

- [ ] `plugin.yaml`의 모든 필수 필드 작성
- [ ] README.md 작성 (사용법, 요구사항 포함)
- [ ] icon.png 추가 (128x128px)
- [ ] 템플릿 파일 변수 치환 테스트
- [ ] 훅 스크립트 실행 권한 확인
- [ ] 로컬에서 플러그인 검증 성공
- [ ] 실제 프로젝트에서 동작 테스트
- [ ] 문서에 오타 없음

## 제출하기

### 1. Fork 및 Clone

```bash
# 레포지토리 Fork (GitHub에서)
git clone https://github.com/{your-username}/arfni-plugins.git
cd arfni-plugins
```

### 2. 브랜치 생성

```bash
git checkout -b add-myframework-plugin
```

### 3. 플러그인 추가

```bash
# 플러그인 파일 작성
git add plugins/frameworks/myframework/
git commit -m "feat: add MyFramework plugin"
```

### 4. Push 및 Pull Request

```bash
git push origin add-myframework-plugin
# GitHub에서 Pull Request 생성
```

### Pull Request 템플릿

```markdown
## 플러그인 정보

- 이름: MyFramework
- 카테고리: framework
- 버전: 1.0.0

## 설명

MyFramework를 위한 플러그인입니다. 다음 기능을 지원합니다:
- 프로젝트 자동 감지
- Dockerfile 자동 생성
- 프로덕션 설정

## 테스트 완료

- [x] 로컬 검증 통과
- [x] 실제 프로젝트에서 테스트
- [x] Docker 빌드 성공
- [x] 문서 작성 완료

## 체크리스트

- [x] plugin.yaml 작성
- [x] README.md 작성
- [x] icon.png 추가
- [x] 템플릿 테스트
- [x] 훅 스크립트 테스트
```

### 5. 리뷰 및 병합

- 메인테이너가 코드 리뷰 진행
- 필요한 경우 수정 요청
- 승인 후 main 브랜치에 병합
- GitHub Actions가 레지스트리 자동 업데이트

## 추가 리소스

- [ARFNI 공식 문서](https://arfni.io/docs)
- [Django 플러그인 예시](plugins/frameworks/django/)
- [PostgreSQL 플러그인 예시](plugins/database/postgres/)
- [이슈 트래커](https://github.com/Arfni/arfni-plugins/issues)

## 도움이 필요하신가요?

- GitHub Issues에 질문 남기기
- Discord 커뮤니티 참여
- 기존 플러그인 코드 참고

---

ARFNI 플러그인 생태계에 기여해주셔서 감사합니다! 🚀
