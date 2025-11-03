# Next Steps - ARFNI Plugin System Automation

## 완료된 작업 ✅

### Phase 1: arfni-plugins 저장소 (GitHub Actions 자동화)

1. **GitHub Actions Workflow 생성**
   - 파일: [.github/workflows/update-registry.yml](.github/workflows/update-registry.yml)
   - 트리거:
     - `plugins/**` 경로 변경 시 자동 실행
     - 수동 실행 지원 (`workflow_dispatch`)
   - 기능:
     - plugin.yaml 파일 자동 검증
     - registry/index.json 자동 생성 및 커밋
     - PR에 변경 사항 자동 코멘트

2. **Registry 생성 스크립트**
   - 파일: [scripts/generate-registry.js](scripts/generate-registry.js)
   - 기능:
     - plugins/** 디렉토리 자동 스캔
     - plugin.yaml 파싱 및 검증
     - registry/index.json 자동 생성
     - 통계 정보 계산 (플러그인 수, 카테고리별 count)
   - 사용법:
     ```bash
     cd scripts
     npm install
     npm run generate      # Registry 생성
     npm run validate      # plugin.yaml 검증만 수행
     ```

3. **테스트 플러그인 정리**
   - 중복된 django 테스트 플러그인 제거 (`plugins/frameworks/test`)
   - 현재 플러그인: Django (framework), PostgreSQL (database)

### Phase 2: arfni_pjt GUI (하드코딩 제거 및 캐싱)

1. **plugin.rs - 24시간 캐싱 시스템 추가**
   - 파일: `arfni-gui/src-tauri/src/commands/plugin.rs`
   - 새로운 함수:
     - `load_plugin_registry()`: 캐시 지원 (24시간 유효)
     - `refresh_plugin_registry()`: 강제 새로고침
     - `clear_registry_cache()`: 캐시 삭제
     - `get_cache_info()`: 캐시 상태 조회
   - 캐시 위치: `{app_data_dir}/cache/plugin_registry.json`
   - 폴백 메커니즘: GitHub 실패 시 만료된 캐시 사용

2. **pluginLoader.ts - 하드코딩 제거**
   - 파일: `arfni-gui/src/services/pluginLoader.ts`
   - 변경 사항:
     - 67-521라인 하드코딩된 10개 플러그인 매니페스트 완전 제거
     - `bundledPluginManifests` 빈 배열로 변경
     - 모든 플러그인은 registry에서 동적으로 로드

3. **PluginManager.tsx - UI 개선**
   - 파일: `arfni-gui/src/pages/projects/ui/PluginManager.tsx`
   - 새로운 기능:
     - 캐시 상태 표시 ("Last synced: X hours ago")
     - Force Refresh 버튼 (캐시 무시하고 GitHub에서 재다운로드)
     - 캐시 유효성 시각적 표시 (green: cached, yellow: stale)

4. **main.rs - 새 커맨드 등록**
   - 파일: `arfni-gui/src-tauri/src/main.rs`
   - 등록된 커맨드:
     - `refresh_plugin_registry`
     - `clear_registry_cache`
     - `get_cache_info`

---

## 앞으로 해야 할 작업 📋

### 1. arfni-plugins 저장소에 커밋 & 푸시

```bash
cd /path/to/arfni-plugins

# 변경사항 확인
git status

# 커밋
git add .github/workflows/update-registry.yml
git add scripts/generate-registry.js
git add scripts/package.json
git add registry/index.json
git commit -m "feat: Add GitHub Actions automation for plugin registry

- Add workflow to auto-update registry on plugin changes
- Add script to generate registry from plugin.yaml files
- Add validation for plugin manifests
- Remove duplicate test plugin
"

# 푸시
git push origin main
```

### 2. GitHub Actions 동작 확인

1. GitHub 저장소 페이지로 이동
2. **Actions** 탭 클릭
3. "Update Plugin Registry" workflow 확인
4. 수동 실행 테스트:
   - Actions > Update Plugin Registry > Run workflow > Run workflow

### 3. arfni_pjt (GUI) 저장소에 커밋 & 푸시

```bash
cd /path/to/arfni_pjt/arfni-gui

# 변경사항 확인
git status

# Rust 백엔드
git add src-tauri/src/commands/plugin.rs
git add src-tauri/src/main.rs

# TypeScript 프론트엔드
git add src/services/pluginLoader.ts
git add src/pages/projects/ui/PluginManager.tsx

# 커밋
git commit -m "feat: Add plugin caching system and remove hardcoded manifests

Backend (Rust):
- Add 24-hour caching for plugin registry
- Add refresh_plugin_registry command
- Add cache_info command for UI
- Fallback to stale cache if GitHub fails

Frontend (TypeScript):
- Remove 454 lines of hardcoded plugin manifests (lines 67-521)
- Add cache status display in PluginManager
- Add Force Refresh button
- Dynamic plugin loading from registry only
"

# 푸시
git push origin main  # 또는 브랜치 이름
```

### 4. 테스트 체크리스트

#### arfni-plugins 저장소

- [ ] 새 플러그인 추가 후 registry 자동 업데이트 확인
  ```bash
  # 1. 새 플러그인 디렉토리 생성
  mkdir -p plugins/cache/redis

  # 2. plugin.yaml 작성
  # 3. git push
  # 4. GitHub Actions에서 자동으로 registry/index.json 업데이트 확인
  ```

- [ ] PR 생성 시 코멘트 자동 생성 확인
- [ ] 잘못된 plugin.yaml 검증 실패 확인

#### arfni_pjt GUI

- [ ] 앱 실행 시 캐시에서 빠른 로딩 확인
  ```bash
  cargo tauri dev
  # Plugin Manager 열기
  # 첫 로딩: GitHub에서 다운로드 (느림)
  # 두 번째 로딩: 캐시 사용 (빠름)
  ```

- [ ] Force Refresh 버튼 동작 확인
  - 버튼 클릭 시 GitHub에서 새로 다운로드
  - 캐시 타임스탬프 업데이트 확인

- [ ] 캐시 상태 표시 확인
  - "Last synced: X hours ago (cached)" - 24시간 이내
  - "Cache expired (X hours old) (stale)" - 24시간 초과

- [ ] 오프라인 모드 테스트
  - 인터넷 연결 끊기
  - 앱 실행
  - 만료된 캐시라도 사용되는지 확인

### 5. 새 플러그인 추가 방법 (기여자 가이드)

#### 1단계: 플러그인 디렉토리 생성

```bash
cd arfni-plugins
mkdir -p plugins/{category}/{plugin-name}
cd plugins/{category}/{plugin-name}
```

예시:
```bash
mkdir -p plugins/cache/redis
cd plugins/cache/redis
```

#### 2단계: plugin.yaml 작성

```yaml
apiVersion: v0.1
name: redis
version: 1.0.0
category: cache
description: In-memory data structure store
author: your-name
homepage: https://github.com/Arfni/arfni-plugins/tree/main/plugins/cache/redis
license: MIT

provides:
  service_kinds:
    - cache.redis

requires:
  arfni_version: ">=0.2.0"
  docker_version: ">=20.10"

inputs:
  redis_version:
    description: "Redis version"
    type: select
    options: ["6", "7"]
    default: "7"
    required: true

contributes:
  services:
    redis:
      kind: docker.container
      spec:
        image: "redis:{{redis_version}}-alpine"
        ports:
          - "6379:6379"
        volumes:
          - host: redis_data
            mount: /data

  volumes:
    - redis_data

tags:
  - cache
  - redis
  - in-memory
```

#### 3단계: 필수 파일 추가

```bash
# icon.png (플러그인 아이콘)
# README.md (플러그인 설명)
# templates/ (필요한 경우)
# frameworks/ (framework 플러그인인 경우)
```

#### 4단계: Git Push

```bash
git add plugins/{category}/{plugin-name}
git commit -m "feat: Add {plugin-name} plugin"
git push origin main
```

#### 5단계: 자동화 확인

- GitHub Actions가 자동으로 실행됩니다
- plugin.yaml 검증
- registry/index.json 자동 업데이트
- 완료!

### 6. 모니터링 및 유지보수

#### GitHub Actions 로그 확인
- 저장소 > Actions 탭
- 실패한 workflow 확인 및 수정

#### Registry 파일 확인
- [registry/index.json](registry/index.json)
- 플러그인 수, 메타데이터 정확성 확인

#### 캐시 관련 이슈
- 사용자가 오래된 정보 보고 시: Force Refresh 안내
- 캐시 무효화 필요 시: 앱 데이터 디렉토리의 `cache/plugin_registry.json` 삭제

---

## 시스템 아키텍처

```
┌─────────────────────────────────────────────────────┐
│  arfni-plugins (GitHub Repository)                  │
│  ├── plugins/frameworks/django/                     │
│  │   ├── plugin.yaml          ← 기여자가 작성       │
│  │   ├── frameworks/django.yaml                     │
│  │   ├── templates/Dockerfile.tmpl                  │
│  │   └── hooks/*.sh                                 │
│  ├── .github/workflows/update-registry.yml          │
│  │   └── 자동 실행: plugins/** 변경 감지            │
│  ├── scripts/generate-registry.js                   │
│  │   └── plugin.yaml 스캔 → registry/index.json    │
│  └── registry/index.json       ← 자동 생성          │
└─────────────────────────────────────────────────────┘
                    │
                    │ HTTPS GET
                    │ raw.githubusercontent.com/.../registry/index.json
                    ▼
┌─────────────────────────────────────────────────────┐
│  arfni-gui (Tauri Application)                      │
│  ┌───────────────────────────────────────────────┐  │
│  │  Rust Backend (plugin.rs)                     │  │
│  │  ├── load_plugin_registry()                   │  │
│  │  │   ├─ 캐시 확인 (24시간 유효)              │  │
│  │  │   ├─ 유효하면 → 캐시에서 로드 (빠름)      │  │
│  │  │   └─ 만료되면 → GitHub에서 다운로드       │  │
│  │  ├── refresh_plugin_registry()                │  │
│  │  │   └─ 캐시 무시, 강제 새로고침             │  │
│  │  └── get_cache_info()                         │  │
│  │      └─ age_hours, valid, last_updated        │  │
│  └───────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────┐  │
│  │  Frontend (PluginManager.tsx)                 │  │
│  │  ├── 캐시 상태 표시                           │  │
│  │  │   "Last synced: 2 hours ago (cached)"     │  │
│  │  ├── Force Refresh 버튼                       │  │
│  │  └── 플러그인 목록 (registry에서 로드)       │  │
│  └───────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────┐  │
│  │  pluginLoader.ts                              │  │
│  │  └── bundledPluginManifests = []  ← 하드코딩  │  │
│  │      제거됨! 이제 registry만 사용             │  │
│  └───────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────┘
```

---

## 주요 개선 사항 요약

### 기여자 경험 ✨
- ❌ 이전: 수동으로 registry 편집, PR 생성
- ✅ 이제: plugin.yaml 작성 후 git push만 하면 끝!

### 개발자 경험 ✨
- ❌ 이전: 454라인 하드코딩, 새 플러그인 추가 시 코드 수정 필요
- ✅ 이제: 하드코딩 완전 제거, registry에서 동적 로딩

### 사용자 경험 ✨
- ❌ 이전: 매번 GitHub에서 다운로드 (느림)
- ✅ 이제: 24시간 캐싱으로 빠른 로딩 + Force Refresh로 최신 유지

### 안정성 ✨
- ❌ 이전: 네트워크 오류 시 플러그인 목록 로드 실패
- ✅ 이제: 만료된 캐시라도 폴백으로 사용

---

## 문의 및 이슈

- GitHub Issues: [arfni-plugins/issues](https://github.com/Arfni/arfni-plugins/issues)
- 플러그인 개발 가이드: [PLUGIN_DEVELOPMENT_GUIDE.md](PLUGIN_DEVELOPMENT_GUIDE.md)
- 기여 가이드: [CONTRIBUTING.md](CONTRIBUTING.md)

---

**생성일**: 2025-11-02
**작성자**: Claude Code Assistant
**버전**: 1.0.0
