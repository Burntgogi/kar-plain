# kar-plain 듀얼 호스트 플러그인 설계

작성일: 2026-10-06
대상 저장소: `dovigod/kar-plain` (upstream `Burntgogi/kar-plain`의 fork)
참조 구현: `mvlchain/mvl-skills` (private)

## 1. 목적

`kar-plain`은 현재 Codex 전용 스킬이다. 이를 **Claude Code와 Codex 양쪽에서 쓸 수 있는 플러그인 마켓플레이스 저장소**로 개조한다. 스킬 본문은 한 벌만 유지하고, 호스트별 차이는 메타데이터와 심링크로 흡수한다.

구조는 `mvl-skills`의 레이아웃을 그대로 따른다.

## 2. 용어

| 용어 | 출처 | 정의 |
| --- | --- | --- |
| `SKILL.md` | `kar-plain/SKILL.md` | 스킬 실행 본문. frontmatter + 영문 308단어 |
| `openai.yaml` | `kar-plain/agents/openai.yaml` | Codex 전용 호출 설정 |
| `allow_implicit_invocation` | `openai.yaml`, [Codex 문서](https://learn.chatgpt.com/docs/build-skills) | Codex 자동 호출 허용 여부. 현재 `false` |
| `disable-model-invocation` | [Claude Code 문서](https://code.claude.com/docs/en/skills) | Claude 자동 호출 차단 frontmatter 플래그 |
| `marketplace.json` | `.claude-plugin/marketplace.json` | 플러그인 목록 매니페스트. 두 호스트가 공용 |
| `plugin.json` | `plugins/<plugin>/.claude-plugin/plugin.json` | 플러그인 단위 매니페스트 |
| 정본 | `plugins/kar-plain/skills/kar-plain/` | 스킬의 유일한 실제 파일 위치 |
| 로컬 링크 | `.claude/skills/`, `.agents/skills/` | 정본을 가리키는 per-skill 심링크. 복제본이 아님 |

## 3. 근거 — 참조 구현에서 확인한 사실

### 3.1 공용 frontmatter에 Claude 전용 키를 넣어도 Codex가 거부하지 않는다

`mvl-skills/scripts/validate.rb:11-12`가 두 호스트 공용 `SKILL.md`의 허용 필드를 이렇게 정의한다.

```ruby
STANDARD_FIELDS = %w[name description license compatibility metadata allowed-tools].freeze
CLAUDE_FIELDS   = %w[argument-hint disable-model-invocation].freeze
```

`mvl-skills`는 이 상태로 Claude Code와 Codex 양쪽에 18개 스킬을 배포 중이다. 따라서 **호스트별로 `SKILL.md`를 복제할 필요가 없다.**

### 3.2 호출 정책 동기화는 검사로 강제한다

`mvl-skills/scripts/validate.rb:133-137`:

```ruby
claude_user_only = metadata["disable-model-invocation"] == true
codex_user_only  = openai.dig("policy", "allow_implicit_invocation") == false
unless claude_user_only == codex_user_only
  errors << "#{name}: Claude and Codex invocation policies are out of sync"
end
```

`kar-plain`의 `invoke: explicit` 배지가 두 호스트 모두에서 참임을 CI가 보증하게 된다.

### 3.3 플러그인 스킬의 호출문은 `/<plugin>:<skill>`

[Claude Code 플러그인 문서](https://code.claude.com/docs/en/plugins)가 명시한다. 플러그인명과 스킬명이 모두 `kar-plain`이므로 호출문은 `/kar-plain:kar-plain`이 된다. 수동 복사 설치에서는 `/kar-plain`이 유지된다. 두 경로를 README에 모두 기록한다.

## 4. 목표 구조

```text
kar-plain/
├── .claude-plugin/marketplace.json          [신규]
├── plugins/kar-plain/
│   ├── .claude-plugin/plugin.json           [신규]
│   └── skills/kar-plain/
│       ├── SKILL.md                         [git mv + frontmatter 2줄]
│       └── agents/openai.yaml               [git mv, 내용 무수정]
├── .claude/skills/kar-plain   → ../../plugins/kar-plain/skills/kar-plain
├── .agents/skills/kar-plain   → ../../plugins/kar-plain/skills/kar-plain
├── CLAUDE.md                                [신규]
├── AGENTS.md → CLAUDE.md                    [신규 심링크]
├── .github/workflows/validate.yml           [신규]
├── scripts/
│   ├── validate.sh                          [신규]
│   ├── validate.rb                          [신규]
│   ├── render_readme.py                     [개정 — 하드코딩 경로 2곳]
│   └── requirements-preview.txt             [유지]
├── README.md · README.en.md                 [개정]
├── assets/badges/host.svg                   [개정]
├── docs/verification.md                     [절 추가]
├── docs/superpowers/specs/                  [이 문서]
└── outputs/** · assets/(badges 외)          [무수정]
```

파일 이동은 `git mv`로 수행해 `SKILL.md`의 커밋 이력을 보존한다.

## 5. 파일별 설계

### 5.1 `.claude-plugin/marketplace.json` (신규)

```json
{
  "name": "kar-plain",
  "owner": { "name": "dovigod" },
  "metadata": {
    "description": "Korean/English explainers in prose, diagram, web, or video."
  },
  "plugins": [
    {
      "name": "kar-plain",
      "source": "./plugins/kar-plain",
      "description": "Explain a topic in Korean or English through prose, a diagram, interactive web content, or an explainer video."
    }
  ]
}
```

### 5.2 `plugins/kar-plain/.claude-plugin/plugin.json` (신규)

```json
{
  "name": "kar-plain",
  "version": "1.0.0",
  "description": "Explain a topic in Korean or English through prose, a diagram, interactive web content, or an explainer video.",
  "author": { "name": "Burntgogi" }
}
```

`author`는 `LICENSE`의 저작권자 표기(`Copyright (c) 2026 Burntgogi`)를 따른다.

버전은 `1.0.0`에서 시작한다. 이후 semver: 수정은 patch, 호환되는 워크플로 변경이나 스킬 추가는 minor, 스킬 제거·이동 같은 파괴적 변경은 major.

### 5.3 `plugins/kar-plain/skills/kar-plain/SKILL.md`

frontmatter만 변경한다. 본문 308단어는 한 글자도 바꾸지 않는다.

```yaml
---
name: kar-plain
description: "Explain a topic in Korean or English through prose, a diagram, interactive web content, or an explainer video."
argument-hint: "[글|도해|웹|영상|자동]: 설명할 주제"
disable-model-invocation: true
---
```

`body: 308 English words` 배지는 그대로 유효하다.

### 5.4 `plugins/kar-plain/skills/kar-plain/agents/openai.yaml`

**내용 무수정.** 현재 값이 5.6의 검사를 모두 통과한다.

| 검사 | 현재 값 | 결과 |
| --- | --- | --- |
| `interface.display_name` 필수 | `"Kar-plain"` | 통과 |
| `interface.short_description` 25~64자 | `"Korean/English explainers: prose, diagram, web, or video."` (57자) | 통과 |
| `interface.default_prompt`에 `$kar-plain` 포함 | 포함 | 통과 |
| 정책 동기화 | `allow_implicit_invocation: false` ↔ `disable-model-invocation: true` | 통과 |

`default_prompt`는 `mvl-skills`의 관례(`"Use $commit to ..."` — 플러그인 접두사 없음)를 따라 현재 형태를 유지한다.

### 5.5 로컬 링크와 저장소 지침

```bash
mkdir -p .claude/skills .agents/skills
ln -s ../../plugins/kar-plain/skills/kar-plain .claude/skills/kar-plain
ln -s ../../plugins/kar-plain/skills/kar-plain .agents/skills/kar-plain
ln -s CLAUDE.md AGENTS.md
```

`CLAUDE.md`는 저장소 지침의 단일 진실 원천이다. `AGENTS.md`는 그 심링크로, 두 호스트가 같은 지침을 읽는다. 내용은 `mvl-skills/CLAUDE.md`를 단일 스킬 저장소에 맞게 줄여 작성한다. 담을 항목:

- 정본 위치와 심링크 규칙
- frontmatter 작성 규칙 (`name` == 디렉터리명, `description` 1,024자 한도)
- `SKILL.md` 본문은 호스트 중립 — 클라이언트 전용 도구명 금지
- 호출 정책을 두 메타데이터 파일에서 함께 바꿔야 한다는 규칙
- `outputs/**`는 보존 자료이므로 수정 금지
- 커밋 전 `scripts/validate.sh` 실행

### 5.6 `scripts/validate.rb` (신규)

`mvl-skills/scripts/validate.rb`를 단일 스킬 저장소에 맞게 축약 이식한다.

**가져오는 검사**

1. `marketplace.json` 파싱, 각 항목의 `source`가 `./plugins/<name>`인지, `plugins/` 하위 디렉터리와 1:1 대응하는지
2. `plugin.json` 파싱, `name` == 디렉터리명
3. `SKILL.md` frontmatter 파싱 — `name` == 디렉터리명, kebab-case 64자 이하, `description` 1~1024자, 꺾쇠 금지
4. frontmatter 미지 필드 금지 — 허용 집합은 3.1의 `STANDARD_FIELDS + CLAUDE_FIELDS`
5. `agents/openai.yaml` 존재 및 5.4 표의 세 항목
6. **호출 정책 동기화** (3.2)
7. `NONPORTABLE_BODY_PATTERNS` — `AskUserQuestion`, `ToolSearch`, `mcp__claude_ai_`, Claude 셸 접두사, Claude 전용 세션 링크가 본문에 섞이는 것 차단
8. `.claude/skills/`, `.agents/skills/`의 심링크 무결성 — 정본을 가리키는지, 끊긴 링크나 고아 링크가 없는지
9. `AGENTS.md`가 `CLAUDE.md` 심링크인지
10. `README.md`에 스킬 `SKILL.md` 링크가 존재하는지

**제외하는 검사**

- `plugins/*/skills/*/tests/*.test.mjs` 실행 — `kar-plain`은 안전 경계를 강제하는 실행 코드를 싣지 않는다
- 스킬명 중복 검사 — 스킬이 하나다

### 5.7 `scripts/validate.sh` (신규)

```bash
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
export GIT_PAGER=cat
git --no-pager diff --check
ruby scripts/validate.rb
python3 scripts/render_readme.py
```

`render_readme.py`를 체인에 넣는 이유: 이 변경은 `SKILL.md`와 `openai.yaml`의 경로를 바꾸므로 README의 상대 링크 33개 중 최소 4곳이 깨진다. `render_readme.py`는 두 README를 렌더링하면서 저장소 링크를 검사하므로, 이 작업에서 가장 깨지기 쉬운 지점을 정확히 잡아낸다.

`render_readme.py`는 `markdown-it-py`를 요구한다(`scripts/requirements-preview.txt`). CI에서 설치한다.

### 5.7a `scripts/render_readme.py` 개정 (필수)

이 스크립트는 구 경로를 하드코딩하고 있어 구조 이동과 동시에 반드시 고쳐야 한다. 안 고치면 `AssertionError`로 빌드가 멈춘다.

| 줄 | 현재 | 변경 |
| --- | --- | --- |
| `render_readme.py:86` | `skill = (ROOT / "kar-plain/SKILL.md").read_text(...)` | `ROOT / "plugins/kar-plain/skills/kar-plain/SKILL.md"` |
| `render_readme.py:90` | `assert len(list((ROOT / "kar-plain").rglob("*.*"))) == 2` | 대상 디렉터리를 `plugins/kar-plain/skills/kar-plain`으로. 파일 수 2는 유지(`SKILL.md` + `agents/openai.yaml`) |

변경하지 않는 것:

- `render_readme.py:89`의 `assert body_words < 350` — 본문 308단어 그대로라 통과한다. frontmatter에 2줄을 더해도 `skill.split("---", 2)[2]`가 집계하는 본문은 바뀌지 않는다.
- `render_readme.py:92`의 README 단어 수 동기화 검사 — 본문이 그대로라 `308`이 유지된다.
- `render_readme.py:84`의 `assets/**/*.svg` XML 파싱 — 5.10의 `host.svg` 수정이 유효한 XML이어야 한다는 뜻이다.

경로 상수는 파일 상단에 변수로 추출해 다음 이동 때 한 곳만 고치게 한다.

### 5.8 `.github/workflows/validate.yml` (신규)

- 트리거: `push`, `pull_request`
- 단계: checkout(심링크 보존) → Ruby 설치 → Python 설치 + `pip install -r scripts/requirements-preview.txt` → `scripts/validate.sh`

### 5.9 README 2종 개정

**「설치」 절 전면 재작성.** 세 경로를 기록한다.

```text
Claude Code — 플러그인
  /plugin marketplace add dovigod/kar-plain
  /plugin install kar-plain@kar-plain
  → /kar-plain:kar-plain 도해: …

Codex — 플러그인
  codex plugin marketplace add dovigod/kar-plain --ref main
  codex plugin add kar-plain@kar-plain
  → $kar-plain:kar-plain 도해: …

수동 복사 (두 호스트 공통)
  plugins/kar-plain/skills/kar-plain/ →
    ~/.claude/skills/kar-plain/   (Claude Code)
    ~/.agents/skills/kar-plain/   (Codex)
  → /kar-plain 도해: …   또는   $kar-plain 도해: …
```

디렉터리 그림의 `~/.agents/skills/`도 두 경로를 병기한다.

**「사용법」 절.** 호출 예시 표 5행은 수동 설치 기준 표기를 유지하고, 표 아래에 플러그인 설치 시 `kar-plain:` 접두사가 붙는다는 한 줄을 추가한다. 표를 두 배로 늘리지 않는다.

**「작동 원칙」 / "How it works" 절.** `allow_implicit_invocation: false` 설명 옆에 `disable-model-invocation: true`를 병기하고, Claude Code 문서 링크를 Codex 문서 링크 옆에 둔다.

**「예시」 절.** `outputs/**`의 호출문 표기가 수동 설치 기준이라는 한 줄을 추가한다(5.11).

**배너 소개문.** "Codex 스킬입니다" → 두 호스트를 가리키는 문장으로. 영문판 "A Codex skill for ..."도 같이.

**링크 4곳 경로 갱신** (README.md:20, 21, 41, 133 / README.en.md:20, 21, 41, 133):
`kar-plain/SKILL.md` → `plugins/kar-plain/skills/kar-plain/SKILL.md`
`kar-plain/agents/openai.yaml` → `plugins/kar-plain/skills/kar-plain/agents/openai.yaml`

### 5.10 `assets/badges/host.svg` 개정

`host: Codex` → `host: Codex · Claude`. 현재 SVG는 width 78, 라벨부 0~34, 값부 34~78이다. 값 텍스트가 길어지므로 `width`, `viewBox`, `clipPath` rect, 값부 `path` 좌표, 두 `<text>`의 `x`를 함께 재계산한다. `aria-label`과 `<title>`도 갱신한다.

`assets/badges/invocation.svg`는 **무수정**. `invoke: explicit`은 두 호스트 모두에서 참이고 5.6의 검사 6번이 이를 보증한다.

### 5.11 `outputs/**` — 무수정

`$kar-plain` 표기가 14곳 남는다. 이 파일들은 README가 이미 "초기 299단어 지침으로 만든 자료"로 표시한 **보존 자료**이고, `docs/verification.md`가 그 보존 사실을 기록하고 있다. 수정하면 그 기록이 거짓이 된다.

대신 README 「예시」 절에 호출문 표기 기준을 밝히는 한 줄을 추가한다.

### 5.12 `docs/verification.md` 절 추가

기존 Codex 검증 기록은 **한 글자도 수정하지 않는다.** 문서 끝에 "듀얼 호스트 플러그인 이식" 절을 새로 추가하고, 이번 작업에서 실제로 확인한 것만 적는다.

- `scripts/validate.sh` 통과 결과
- 두 README의 링크·이미지 검사 결과 (`render_readme.py`)
- 심링크가 정본을 가리키는지 확인
- 실제 Claude Code에 설치해 `/kar-plain:kar-plain` 또는 `/kar-plain` 호출이 동작하는지 확인한 범위
- Codex 설치를 확인하지 못했다면 **확인하지 못했다고 명시**한다

## 6. 범위 밖

- `outputs/**` 재생성 — 보존 자료
- GitHub 저장소 소개문 변경 — 외부에 보이는 값이므로 수정안만 제시하고 실행하지 않는다
- upstream `Burntgogi/kar-plain`에 PR 생성 — 작업 완료 후 별도 판단
- 음성 나레이션, 신규 모드, 본문 308단어 변경

## 7. 완료 조건

1. `scripts/validate.sh`가 통과한다
2. 두 README의 상대 링크 검사가 통과한다
3. `.claude/skills/kar-plain`, `.agents/skills/kar-plain`이 정본을 가리킨다
4. `AGENTS.md`가 `CLAUDE.md` 심링크다
5. 호출 정책이 두 메타데이터 파일에서 일치한다
6. `SKILL.md` 본문 308단어가 변경 전과 바이트 단위로 같다
7. `outputs/**`가 변경 전과 바이트 단위로 같다
8. `docs/verification.md`의 기존 절이 변경 전과 같다
9. GitHub 저장소 소개문 수정안을 사용자에게 전달했다
