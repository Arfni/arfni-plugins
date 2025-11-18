# ARFNI 플러그인 개발 가이드

[English](README.md) | **한국어**

ARFNI 플러그인 생태계에 오신 것을 환영합니다! 이 가이드는 ARFNI용 플러그인을 만들고 테스트하는 방법을 설명합니다.

## 빠른 시작

### 1. 플러그인 생성

다음과 같은 폴더 구조를 만드세요:

```
my-plugin/
├── plugin.yaml      # 필수: 플러그인 설정
├── icon.png        # 필수: 128x128 PNG 아이콘
├── README.md       # 필수: 문서
└── templates/      # 선택: 템플릿 파일
    └── Dockerfile.tmpl
```

### 2. plugin.yaml 작성

최소 예제:

```yaml
apiVersion: v0.1
name: my-framework
displayName: My Framework
version: 1.0.0
category: framework  # 선택: framework, database, cache, proxy, cicd, orchestration, monitoring, infrastructure
description: 플러그인에 대한 간단한 설명
author: Your Name
license: MIT
icon: icon.png

provides:
  frameworks:        # 프레임워크 플러그인용
    - my-framework
  # 또는
  service_kinds:     # 서비스 플러그인용 (database, cache 등)
    - db.postgres

inputs:
  port:
    description: "애플리케이션 포트"
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
    description: "노드 설명"
    category: runtime
    ports:
      - name: http
        port: 3000
        protocol: tcp
```

### 3. 플러그인 테스트

**방법 1: 직접 가져오기 (가장 쉬움)**

1. ARFNI GUI 실행
2. **프로젝트** → **플러그인 매니저** 이동
3. **커스텀 플러그인** 섹션 찾기
4. **플러그인 개발 가이드** 버튼 클릭
5. **커스텀 플러그인 가져오기**로 플러그인 폴더 선택
6. 커스텀 플러그인 목록에 플러그인이 나타남

**방법 2: GitHub URL**

1. 플러그인을 GitHub에 푸시
2. 플러그인 매니저에서 GitHub URL 붙여넣기:
   ```
   https://github.com/username/repo/tree/branch/path/to/plugin
   ```
3. **플러그인 설치** 클릭

### 4. 플러그인 제출

1. [github.com/Arfni/arfni-plugins](https://github.com/Arfni/arfni-plugins) Fork
2. `plugins/{category}/{plugin-name}/`에 플러그인 추가
   - 폴더 이름은 소문자 사용 (예: `my-plugin`이 아닌 `MyPlugin`)
   - 폴더 이름과 plugin.yaml의 `name` 필드를 일치시킴
3. 로컬 테스트: `cd scripts && npm install && node generate-registry.js --validate-only`
4. Pull Request 생성
5. GitHub Actions가 자동으로 플러그인 검증
6. 머지되면 몇 분 내에 모든 ARFNI 사용자가 사용 가능

## 플러그인 카테고리

- `framework` - 웹 프레임워크 (Django, Spring Boot, Express)
- `database` - 데이터베이스 (PostgreSQL, MySQL, MongoDB)
- `cache` - 캐싱 시스템 (Redis, Memcached)
- `proxy` - 리버스 프록시 (Nginx, Traefik)
- `cicd` - CI/CD 도구 (GitHub Actions, Jenkins)
- `orchestration` - 컨테이너 오케스트레이션 (Kubernetes)
- `monitoring` - 모니터링 도구 (Prometheus, Grafana)
- `infrastructure` - 인프라 도구 (Terraform, Ansible)

## plugin.yaml 레퍼런스

### 필수 필드

```yaml
apiVersion: v0.1              # API 버전
name: plugin-id              # 고유 식별자 (소문자, 공백 없음)
displayName: Plugin Name     # UI에 표시될 이름
version: 1.0.0              # 시맨틱 버전
category: framework         # 플러그인 카테고리
description: 설명           # 간단한 설명
author: Your Name          # 작성자 이름
license: MIT              # 라이선스 타입
icon: icon.png           # 아이콘 파일 (128x128 PNG)
```

### 입력 타입

```yaml
inputs:
  text_input:
    type: text
    default: "value"
    placeholder: "값 입력"

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
    env_var: SECRET_KEY  # 자동으로 환경변수로 설정
```

### 서비스 정의

```yaml
contributes:
  services:
    my-service:
      kind: docker.container
      spec:
        image: "nginx:latest"      # 또는
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

### 캔버스 노드

```yaml
contributes:
  canvas:
    nodeType: unique-id
    label: 표시 이름
    description: "툴팁 설명"
    category: runtime      # runtime, database, infra
    ports:
      - name: http
        port: 8080
        protocol: tcp
    connections:
      inputs:              # 이 노드가 받을 수 있는 것
        - type: database
          name: db
          protocol: any
          env_var: DATABASE_URL
      outputs:             # 이 노드가 제공하는 것
        - type: api
          name: api
          protocol: http
```

### 자동 감지 (선택사항)

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

### 템플릿 (선택사항)

`templates/` 폴더에 템플릿 파일 포함:

```yaml
templates:
  - source: templates/Dockerfile.tmpl
    target: Dockerfile
    description: "프로덕션용 Dockerfile"
    overwrite: false
```

템플릿은 Go 템플릿 문법 사용:
```dockerfile
FROM node:{{node_version}}
EXPOSE {{port}}
```

## 예제

참고할 수 있는 기존 플러그인:
- [Django 플러그인](plugins/frameworks/django/)
- [PostgreSQL 플러그인](plugins/database/postgresql/)
- [GitHub Actions 플러그인](plugins/cicd/github-actions/)

## 검증

플러그인은 다음 경우에 자동으로 검증됩니다:
1. ARFNI GUI에서 가져올 때
2. Pull Request 제출 시 (GitHub Actions가 검증 실행)

### 로컬 검증
```bash
cd scripts
npm install
node generate-registry.js --validate-only
```

### 검증 규칙
- `apiVersion`은 `v0.1`이어야 함
- `name`은 소문자와 하이픈 사용 (예: `my-plugin`)
- `displayName`은 공백과 대문자 사용 가능
- `category`는 8개 유효 카테고리 중 하나여야 함
- `version`은 시맨틱 버전(X.Y.Z) 형식
- `provides`는 `frameworks` 또는 `service_kinds` 중 하나 필요
- `icon.png`는 존재하고 128x128 픽셀이어야 함

## 문제 해결

### 흔한 문제들

**플러그인이 GUI에 나타나지 않음:**
- plugin.yaml의 모든 필수 필드 확인
- icon.png가 존재하고 128x128 픽셀인지 확인
- 검증 실행: `node generate-registry.js --validate-only`

**템플릿 변수가 작동하지 않음:**
- 이중 중괄호 사용: `{{variable_name}}`
- 변수 이름이 input 이름과 정확히 일치해야 함
- 변수 이름의 오타 확인

**Docker 빌드 실패:**
- Dockerfile 템플릿의 문법 확인
- 생성된 Dockerfile을 수동으로 테스트
- 모든 필수 파일이 포함되었는지 확인

## FAQ

**Q: 플러그인을 디버그하려면?**
A: ARFNI GUI 콘솔(F12)에서 오류 메시지를 확인하세요. `RUST_LOG=debug`로 디버그 모드를 활성화하세요.

**Q: 비공개 플러그인을 사용할 수 있나요?**
A: 네, 커스텀 플러그인 기능을 사용하거나 비공개 GitHub 레포에서 설치하세요.

**Q: 플러그인을 업데이트하려면?**
A: `plugin.yaml`의 버전을 증가시키고 재설치하세요.

**Q: `frameworks`와 `service_kinds`의 차이는?**
A: `frameworks`는 애플리케이션 프레임워크(Django, Spring Boot)용, `service_kinds`는 서비스(데이터베이스, 캐시)용입니다.

**Q: 플러그인에 바이너리 파일을 포함할 수 있나요?**
A: 네, 하지만 작게 유지하세요. 큰 바이너리는 설치 중에 다운로드하도록 하세요.

## 지원

- [GitHub Issues](https://github.com/Arfni/arfni-plugins/issues)
- [Discord 커뮤니티](https://discord.gg/arfni)
- [문서](https://arfni.io/docs)

---

준비되셨나요? 첫 플러그인을 만들고 ARFNI 생태계에 참여하세요! 🚀