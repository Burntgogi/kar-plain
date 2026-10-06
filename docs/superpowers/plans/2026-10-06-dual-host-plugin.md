# kar-plain 듀얼 호스트 플러그인 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `kar-plain`을 Claude Code와 Codex 양쪽에서 설치·호출할 수 있는 플러그인 마켓플레이스 저장소로 개조한다. 스킬 본문은 한 벌만 유지한다.

**Architecture:** 정본은 `plugins/kar-plain/skills/kar-plain/` 한 곳이다. `.claude/skills/`와 `.agents/skills/`는 그 정본을 가리키는 심링크만 담는다. 호스트별 차이는 `SKILL.md` frontmatter(Claude)와 `agents/openai.yaml`(Codex) 두 메타데이터에 나눠 적고, `scripts/validate.rb`가 두 값의 동기화를 강제한다.

**Tech Stack:** Ruby 4.0(검증), Python 3 + `markdown-it-py`(README 렌더링·링크 검사), GitHub Actions

**Spec:** `docs/superpowers/specs/2026-10-06-dual-host-plugin-design.md`

## Global Constraints

- `SKILL.md` 본문 308단어는 바이트 단위로 보존한다. frontmatter만 변경한다.
- `outputs/**`는 바이트 단위로 보존한다. 보존 자료다.
- `docs/verification.md`의 기존 절은 바이트 단위로 보존한다. 새 절만 덧붙인다.
- `assets/badges/invocation.svg`는 수정하지 않는다.
- 파일 이동은 `git mv`로 한다.
- 플러그인명과 스킬명은 모두 `kar-plain`이다.
- `plugin.json`의 `author.name`은 `Burntgogi`(LICENSE 저작권자), `marketplace.json`의 `owner.name`은 `dovigod`(저장소 소유자)다.
- frontmatter 허용 필드: `name description license compatibility metadata allowed-tools argument-hint disable-model-invocation`
- README에 적히는 본문 단어 수 문자열은 `308`이다. `render_readme.py`가 이 동기화를 검사한다.
- 작업 브랜치는 `feat/dual-host-plugin`이다.

---

### Task 1: 정본 이동과 플러그인 매니페스트

**Files:**
- Create: `.claude-plugin/marketplace.json`
- Create: `plugins/kar-plain/.claude-plugin/plugin.json`
- Move: `kar-plain/SKILL.md` → `plugins/kar-plain/skills/kar-plain/SKILL.md`
- Move: `kar-plain/agents/openai.yaml` → `plugins/kar-plain/skills/kar-plain/agents/openai.yaml`
- Modify: 이동한 `SKILL.md` frontmatter

**Interfaces:**
- Produces: 정본 경로 `plugins/kar-plain/skills/kar-plain` — Task 2의 심링크 대상, Task 3의 `render_readme.py` 상수, Task 6의 `validate.rb` 탐색 루트가 모두 이 경로를 쓴다.
- Produces: frontmatter 키 `disable-model-invocation: true` — Task 6이 `openai.yaml`의 `allow_implicit_invocation: false`와 대조한다.

- [ ] **Step 1: 이동 전 본문 해시를 기록**

```bash
cd /Users/justin/Desktop/kar-plain
md5 -q kar-plain/SKILL.md > /tmp/kar-plain-skill-before.md5
awk '/^---$/{n++; next} n>=2' kar-plain/SKILL.md | md5 -q > /tmp/kar-plain-body-before.md5
cat /tmp/kar-plain-body-before.md5
```

본문 해시는 Task 8에서 다시 대조한다.

- [ ] **Step 2: `git mv`로 정본 이동**

```bash
mkdir -p plugins/kar-plain/skills
git mv kar-plain plugins/kar-plain/skills/kar-plain
git status --short
```

기대: `R  kar-plain/SKILL.md -> plugins/kar-plain/skills/kar-plain/SKILL.md` 와 `openai.yaml` 같은 형태의 rename 2건.

- [ ] **Step 3: `marketplace.json` 작성**

`.claude-plugin/marketplace.json`:

```json
{
  "name": "kar-plain",
  "owner": {
    "name": "dovigod"
  },
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

- [ ] **Step 4: `plugin.json` 작성**

`plugins/kar-plain/.claude-plugin/plugin.json`:

```json
{
  "name": "kar-plain",
  "version": "1.0.0",
  "description": "Explain a topic in Korean or English through prose, a diagram, interactive web content, or an explainer video.",
  "author": {
    "name": "Burntgogi"
  }
}
```

- [ ] **Step 5: `SKILL.md` frontmatter에 두 줄 추가**

`plugins/kar-plain/skills/kar-plain/SKILL.md`의 frontmatter를 아래로 교체한다. 닫는 `---` 아래 본문은 건드리지 않는다.

```yaml
---
name: kar-plain
description: "Explain a topic in Korean or English through prose, a diagram, interactive web content, or an explainer video."
argument-hint: "[글|도해|웹|영상|자동]: 설명할 주제"
disable-model-invocation: true
---
```

- [ ] **Step 6: 본문이 보존됐는지 검사**

```bash
awk '/^---$/{n++; next} n>=2' plugins/kar-plain/skills/kar-plain/SKILL.md | md5 -q > /tmp/kar-plain-body-after.md5
diff /tmp/kar-plain-body-before.md5 /tmp/kar-plain-body-after.md5 && echo "BODY PRESERVED"
```

기대: `BODY PRESERVED`

- [ ] **Step 7: 매니페스트와 frontmatter가 파싱되는지 검사**

```bash
ruby -rjson -ryaml -e '
JSON.parse(File.read(".claude-plugin/marketplace.json"))
JSON.parse(File.read("plugins/kar-plain/.claude-plugin/plugin.json"))
fm = File.read("plugins/kar-plain/skills/kar-plain/SKILL.md").split(/^---\s*$\n/, 3)[1]
meta = YAML.safe_load(fm)
raise "name mismatch" unless meta["name"] == "kar-plain"
raise "not user-only" unless meta["disable-model-invocation"] == true
oy = YAML.safe_load(File.read("plugins/kar-plain/skills/kar-plain/agents/openai.yaml"))
raise "policy out of sync" unless oy.dig("policy", "allow_implicit_invocation") == false
puts "PARSE OK"
'
```

기대: `PARSE OK`

- [ ] **Step 8: 커밋**

```bash
git add -A .claude-plugin plugins
git commit -m "refactor: move the skill into a plugin marketplace layout"
```

---

### Task 2: 로컬 심링크와 저장소 지침

**Files:**
- Create: `.claude/skills/kar-plain` (심링크)
- Create: `.agents/skills/kar-plain` (심링크)
- Create: `CLAUDE.md`
- Create: `AGENTS.md` (심링크 → `CLAUDE.md`)

**Interfaces:**
- Consumes: Task 1의 정본 경로 `plugins/kar-plain/skills/kar-plain`
- Produces: `.claude/skills`, `.agents/skills` 두 디렉터리 — Task 6의 `validate.rb` `LOCAL_SKILLS_ROOTS`가 이 둘을 검사한다.

- [ ] **Step 1: 심링크 생성**

```bash
cd /Users/justin/Desktop/kar-plain
mkdir -p .claude/skills .agents/skills
ln -s ../../plugins/kar-plain/skills/kar-plain .claude/skills/kar-plain
ln -s ../../plugins/kar-plain/skills/kar-plain .agents/skills/kar-plain
ln -s CLAUDE.md AGENTS.md
```

- [ ] **Step 2: 심링크가 정본을 가리키는지 검사**

```bash
for p in .claude/skills/kar-plain .agents/skills/kar-plain; do
  test -L "$p" || { echo "NOT A SYMLINK: $p"; exit 1; }
  test "$(cd "$(dirname "$p")" && cd "$(readlink "$(basename "$p")")" && pwd)" \
     = "$(cd plugins/kar-plain/skills/kar-plain && pwd)" \
     || { echo "WRONG TARGET: $p"; exit 1; }
  test -f "$p/SKILL.md" || { echo "BROKEN: $p"; exit 1; }
done
echo "SYMLINKS OK"
```

기대: `SYMLINKS OK`

- [ ] **Step 3: `CLAUDE.md` 작성**

```markdown
# 저장소 지침

이 저장소는 `kar-plain` 스킬을 Claude Code와 Codex 양쪽에 배포한다. 하나의
마켓플레이스가 두 클라이언트를 모두 담당한다.

## 정본과 링크

- 스킬의 실제 파일은 `plugins/kar-plain/skills/kar-plain/` 한 곳에만 둔다.
- `.claude/skills/<skill>` 과 `.agents/skills/<skill>` 은 그 정본을 가리키는
  심링크다. 복제본을 두지 않는다.
- `AGENTS.md` 는 `CLAUDE.md` 의 심링크다. 두 클라이언트가 같은 지침을 읽는다.

## 스킬 작성

- 스킬 하나는 `SKILL.md` 를 담은 kebab-case 디렉터리 하나다.
- frontmatter 의 `name` 은 디렉터리명과 같아야 한다.
- `description` 은 무엇을 하고 언제 쓰는지 적는다. Agent Skills 의 1,024자
  한도를 넘기지 않는다.
- `SKILL.md` 본문은 호스트 중립으로 쓴다. 클라이언트 전용 도구명을 적지
  않는다. 클라이언트별 설정은 해당 메타데이터 파일에 적는다.
- 호출 정책은 두 곳에서 함께 바꾼다. Claude Code 는 frontmatter 의
  `disable-model-invocation`, Codex 는 `agents/openai.yaml` 의
  `policy.allow_implicit_invocation` 이다. 둘이 어긋나면 검증이 실패한다.

## 보존 대상

- `outputs/**` 는 초기 299단어 지침으로 만든 보존 자료다. 수정하지 않는다.
- `docs/verification.md` 의 기존 절은 수정하지 않는다. 새 확인 내역은 절을
  덧붙여 적는다.

## 배포

- `.claude-plugin/marketplace.json` 은 두 클라이언트가 함께 읽는 마켓플레이스
  매니페스트다. `plugins/` 아래 모든 플러그인을 적는다.
- `plugins/<plugin>/.claude-plugin/plugin.json` 의 `name` 은 디렉터리명과 같아야
  한다.
- 버전은 semver 로 올린다. 수정은 patch, 호환되는 변경이나 스킬 추가는 minor,
  스킬 제거나 이동 같은 파괴적 변경은 major 다.

## 검증

커밋 전에 `scripts/validate.sh` 를 실행한다. 매니페스트와 frontmatter 파싱,
호출 정책 동기화, 심링크 무결성, 두 README 의 링크를 검사한다.
```

- [ ] **Step 4: `AGENTS.md`가 심링크인지 검사**

```bash
test "$(readlink AGENTS.md)" = "CLAUDE.md" && head -1 AGENTS.md && echo "AGENTS OK"
```

기대: `# 저장소 지침` 출력 후 `AGENTS OK`

- [ ] **Step 5: 커밋**

```bash
git add -A .claude .agents CLAUDE.md AGENTS.md
git commit -m "chore: add local skill links and the shared repository contract"
```

---

### Task 3: `render_readme.py` 경로 복구와 README 링크 수선

**Files:**
- Modify: `scripts/render_readme.py:86`, `scripts/render_readme.py:90`
- Modify: `README.md:20,21,41,133`
- Modify: `README.en.md:20,21,41,133`

**Interfaces:**
- Consumes: Task 1의 정본 경로
- Produces: 통과하는 `python3 scripts/render_readme.py` — Task 4·5가 README와 배지를 고친 뒤 같은 명령으로 회귀를 검사하고, Task 6의 `validate.sh`가 이를 체인에 넣는다.

- [ ] **Step 1: 지금 실패하는지 확인**

```bash
cd /Users/justin/Desktop/kar-plain
python3 scripts/render_readme.py; echo "exit=$?"
```

기대: `FileNotFoundError` 로 비정상 종료. 구 경로 `kar-plain/SKILL.md` 를 읽으려 하기 때문이다.

- [ ] **Step 2: 경로 상수를 파일 상단으로 추출**

`scripts/render_readme.py` 의 `PREVIEWS` 정의 바로 아래에 추가한다.

```python
SKILL_DIR = ROOT / "plugins/kar-plain/skills/kar-plain"
```

- [ ] **Step 3: 하드코딩된 두 줄을 상수로 교체**

`scripts/render_readme.py:86`:

```python
skill = (SKILL_DIR / "SKILL.md").read_text(encoding="utf-8")
```

`scripts/render_readme.py:90`:

```python
assert len(list(SKILL_DIR.rglob("*.*"))) == 2
```

`render_readme.py:89` 의 `assert body_words < 350`, `render_readme.py:92` 의 README 단어 수 검사, `render_readme.py:84` 의 SVG 파싱은 건드리지 않는다.

- [ ] **Step 4: 다시 실행해 다음 실패로 넘어가는지 확인**

```bash
python3 scripts/render_readme.py; echo "exit=$?"
```

기대: `AssertionError: Missing repository link: kar-plain/SKILL.md` 류의 링크 실패. 경로 상수 문제는 해결됐고 이제 README 링크가 걸린 것이다.

- [ ] **Step 5: 두 README의 링크 4곳씩 갱신**

`README.md` 와 `README.en.md` 양쪽에서 아래 문자열을 치환한다.

```bash
for f in README.md README.en.md; do
  perl -pi -e 's{\Qkar-plain/agents/openai.yaml\E}{plugins/kar-plain/skills/kar-plain/agents/openai.yaml}g' "$f"
  perl -pi -e 's{\((?!https)\Qkar-plain/SKILL.md\E\)}{(plugins/kar-plain/skills/kar-plain/SKILL.md)}g' "$f"
  perl -pi -e 's{"\Qkar-plain/SKILL.md\E"}{"plugins/kar-plain/skills/kar-plain/SKILL.md"}g' "$f"
done
grep -n 'kar-plain/SKILL.md\|openai.yaml' README.md README.en.md
```

기대: 모든 결과가 `plugins/kar-plain/skills/kar-plain/` 로 시작한다. 설치 절(line 81 부근)의 디렉터리 그림은 Task 4에서 다시 쓰므로 여기서는 두지 않는다.

- [ ] **Step 6: 통과 확인**

```bash
python3 scripts/render_readme.py
```

기대: `{"readmes": [...], "links": "PASS", "SVG": "PASS", "skill_body_words": 308}` 형태의 JSON 한 줄.

- [ ] **Step 7: 커밋**

```bash
git add scripts/render_readme.py README.md README.en.md docs/README.preview.html docs/README.en.preview.html
git commit -m "fix: point the README renderer and links at the new skill path"
```

---

### Task 4: README 2종 본문 개정

**Files:**
- Modify: `README.md` — 배너 소개문, 선행 호출 예시, 「예시」, 「설치」, 「사용법」, 「작동 원칙」, 배지 alt
- Modify: `README.en.md` — 같은 절의 영문판

**Interfaces:**
- Consumes: Task 3의 `render_readme.py` 검사
- Produces: 두 호스트의 설치·호출 안내 — Task 6의 `validate.rb`가 README에 스킬 `SKILL.md` 링크가 있는지 확인한다.

- [ ] **Step 1: 배너 소개문과 배지 alt 교체 (`README.md`)**

```text
글·도해·웹·영상으로 주제를 설명하는 Codex 스킬입니다.
→ 글·도해·웹·영상으로 주제를 설명하는 Claude Code·Codex 스킬입니다.

alt="사용 환경: Codex"
→ alt="사용 환경: Codex · Claude"
```

- [ ] **Step 2: 선행 호출 예시 교체 (`README.md:33` 부근)**

```text
설치 후 Claude Code나 Codex에서 주제와 형식을 지정하세요. Codex에서는 `$kar-plain`으로 호출합니다.

```text
/kar-plain 도해: 이 스킬의 작동 과정을 설명해 줘.
```
```

- [ ] **Step 3: 「설치」 절 전면 교체 (`README.md:74`~`README.md:89`)**

````markdown
## 설치

Claude Code와 Codex에서 모두 씁니다. 플러그인으로 설치하면 한 번의 명령으로 설치하고 갱신합니다.

### Claude Code

Claude Code 세션 안에서 실행하세요.

```text
/plugin marketplace add dovigod/kar-plain
/plugin install kar-plain@kar-plain
```

설치 후 `/kar-plain:kar-plain`으로 호출합니다.

### Codex

```bash
codex plugin marketplace add dovigod/kar-plain --ref main
codex plugin add kar-plain@kar-plain
```

설치 후 `$kar-plain:kar-plain`으로 호출합니다.

### 수동 설치

저장소를 내려받아 `plugins/kar-plain/skills/kar-plain` 폴더를 개인 스킬 디렉터리에 복사합니다. 이 방식에서는 접두사 없이 `/kar-plain` 또는 `$kar-plain`으로 호출합니다.

```text
~/.claude/skills/     (Claude Code)
~/.agents/skills/     (Codex, Windows는 %USERPROFILE%\.agents\skills)
└── kar-plain/
    ├── SKILL.md
    └── agents/openai.yaml
```

복사할 파일은 위 두 개입니다. README, 배너와 예시 결과물은 설치 폴더 밖에 둡니다. 사용 중인 클라이언트가 별도 개인 스킬 경로를 제공한다면 그 경로를 사용하세요. 새 스킬이 보이지 않으면 클라이언트를 다시 시작하세요.

스킬 설치에는 별도 API 키나 Python이 필요하지 않습니다. 웹·영상 제작에 필요한 도구는 작업에 따라 달라집니다.
````

- [ ] **Step 4: 「사용법」 절에 접두사 주석 한 줄 추가 (`README.md`)**

호출 예시 표 바로 아래, "모드를 생략하면…" 문단 앞에 넣는다.

```text
표의 호출문은 수동 설치 기준입니다. 플러그인으로 설치했다면 스킬 이름 앞에 `kar-plain:`을 붙입니다 — `/kar-plain:kar-plain 글: …`.
```

- [ ] **Step 5: 「작동 원칙」 첫 문단 교체 (`README.md:107` 부근)**

```text
핵심 실행 본문은 영어 308단어입니다. 두 호스트 모두 스킬을 선택하면 `SKILL.md` 본문 전체를 읽고 요청한 형식을 적용합니다. 명시적 호출 정책은 호스트별 설정 두 곳에 함께 적습니다 — Codex는 `allow_implicit_invocation: false`, Claude Code는 `disable-model-invocation: true`입니다. [Codex 공식 안내](https://learn.chatgpt.com/docs/build-skills) · [Claude Code 공식 안내](https://code.claude.com/docs/en/skills)
```

`308`이라는 문자열이 반드시 남아야 한다. `render_readme.py:92`가 검사한다.

- [ ] **Step 6: 「예시」 절에 표기 기준 한 줄 추가 (`README.md:41` 부근)**

해당 문단 끝에 덧붙인다.

```text
예시 안의 호출문 표기는 수동 설치 기준입니다.
```

- [ ] **Step 7: `README.en.md`에 Step 1~6의 영문판 적용**

```text
A Codex skill for explaining topics through prose, diagrams, web pages and videos.
→ A Claude Code and Codex skill for explaining topics through prose, diagrams, web pages and videos.

alt="Host: Codex"  →  alt="Host: Codex · Claude"

After installation, give Codex a topic and a format.
→ After installation, give Claude Code or Codex a topic and a format. In Codex, invoke it as `$kar-plain`.
  code block:  /kar-plain diagram: Explain how this skill works.
```

「Installation」 절:

````markdown
## Installation

The skill runs in both Claude Code and Codex. Installing it as a plugin gives you one command to install and one to update.

### Claude Code

Run these commands inside a Claude Code session.

```text
/plugin marketplace add dovigod/kar-plain
/plugin install kar-plain@kar-plain
```

Invoke it as `/kar-plain:kar-plain`.

### Codex

```bash
codex plugin marketplace add dovigod/kar-plain --ref main
codex plugin add kar-plain@kar-plain
```

Invoke it as `$kar-plain:kar-plain`.

### Manual installation

Download the repository and copy the `plugins/kar-plain/skills/kar-plain` folder into your personal skills directory. This method keeps the short form, `/kar-plain` or `$kar-plain`.

```text
~/.claude/skills/     (Claude Code)
~/.agents/skills/     (Codex, or %USERPROFILE%\.agents\skills on Windows)
└── kar-plain/
    ├── SKILL.md
    └── agents/openai.yaml
```

Install the two files shown above. Keep the README, banner and example artifacts outside the installed skill folder. If your client provides a different personal skills directory, use that location. Restart the client if the new skill does not appear.

Installing the skill requires no separate API key or Python installation. Tools needed to produce web pages or videos depend on the task.
````

「Usage」 표 아래:

```text
The invocations above use the manual installation form. With the plugin installed, prefix the skill name with `kar-plain:`, for example `/kar-plain:kar-plain prose: ...`.
```

「How it works」 첫 문단:

```text
The core instruction body contains 308 English words. In both hosts, selecting the skill reads the full `SKILL.md` body and applies the requested format. The explicit-invocation policy is recorded in two host settings: `allow_implicit_invocation: false` for Codex and `disable-model-invocation: true` for Claude Code. [Official Codex guide](https://learn.chatgpt.com/docs/build-skills) · [Official Claude Code guide](https://code.claude.com/docs/en/skills).
```

「Examples」 문단 끝:

```text
Invocations shown in the examples use the manual installation form.
```

- [ ] **Step 8: 링크·앵커·단어 수 검사**

```bash
python3 scripts/render_readme.py
```

기대: `"links": "PASS"`, `"skill_body_words": 308`. 목차 앵커가 깨지면 여기서 `Missing anchor` 로 잡힌다.

- [ ] **Step 9: 커밋**

```bash
git add README.md README.en.md docs/README.preview.html docs/README.en.preview.html
git commit -m "docs: document Claude Code and Codex installation in both READMEs"
```

---

### Task 5: `host.svg` 배지 개정

**Files:**
- Modify: `assets/badges/host.svg`

**Interfaces:**
- Consumes: Task 4의 README alt 텍스트 `사용 환경: Codex · Claude` / `Host: Codex · Claude`
- Produces: 유효한 XML — `render_readme.py:84`가 `assets/**/*.svg`를 전부 `ET.parse`한다.

- [ ] **Step 1: 기하값 계산 근거**

현재 `host.svg`는 `width=78`, 라벨부 `0~34`(텍스트 `x=17`), 값부 `34~78`(폭 44, `Codex` 5자, 텍스트 `x=56`)이다. 문자당 폭은 `(44 - 10) / 5 = 6.8`px.

`Codex · Claude`는 14자이므로 값부 폭은 `14 × 6.8 + 10 = 105.2` → `105`. 전체 폭 `34 + 105 = 139`, 값 텍스트 `x = 34 + 105 / 2 = 86.5`.

- [ ] **Step 2: `assets/badges/host.svg` 전체 교체**

```xml
<svg xmlns="http://www.w3.org/2000/svg" width="139" height="20" viewBox="0 0 139 20" role="img" aria-label="host: Codex · Claude">
<title>host: Codex · Claude</title><clipPath id="r"><rect width="139" height="20" rx="3"/></clipPath><g clip-path="url(#r)"><path fill="#555" d="M0 0h34v20H0z"/><path fill="#315bff" d="M34 0h105v20H34z"/></g><g fill="#fff" text-anchor="middle" font-family="Verdana,Arial,sans-serif" font-size="11"><text x="17.0" y="14">host</text><text x="86.5" y="14">Codex · Claude</text></g></svg>
```

- [ ] **Step 3: XML 유효성과 기하값 검사**

```bash
python3 -c "
import xml.etree.ElementTree as ET
r = ET.parse('assets/badges/host.svg').getroot()
assert r.get('width') == '139', r.get('width')
assert r.get('viewBox') == '0 0 139 20', r.get('viewBox')
assert 'Codex · Claude' in r.get('aria-label')
print('SVG OK')
"
```

기대: `SVG OK`

- [ ] **Step 4: 렌더러 회귀 검사**

```bash
python3 scripts/render_readme.py
```

기대: `"SVG": "PASS"`

- [ ] **Step 5: 커밋**

```bash
git add assets/badges/host.svg docs/README.preview.html docs/README.en.preview.html
git commit -m "docs: widen the host badge to Codex and Claude"
```

---

### Task 6: `validate.rb` 와 `validate.sh`

**Files:**
- Create: `scripts/validate.rb`
- Create: `scripts/validate.sh`

**Interfaces:**
- Consumes: Task 1~5가 만든 구조 전부
- Produces: `scripts/validate.sh` — Task 7의 CI가 이 한 줄을 실행한다.

- [ ] **Step 1: `scripts/validate.rb` 작성**

```ruby
#!/usr/bin/env ruby

require "json"
require "pathname"
require "yaml"

ROOT = Pathname.new(__dir__).join("..").realpath
PLUGINS_ROOT = ROOT.join("plugins")
LOCAL_SKILLS_ROOTS = [ROOT.join(".claude/skills"), ROOT.join(".agents/skills")].freeze
READMES = %w[README.md README.en.md].freeze
STANDARD_FIELDS = %w[name description license compatibility metadata allowed-tools].freeze
CLAUDE_FIELDS = %w[argument-hint disable-model-invocation].freeze
NONPORTABLE_BODY_PATTERNS = {
  "AskUserQuestion" => /\bAskUserQuestion\b/,
  "Claude shell prefix" => /`! (?:argocd|aws|gh|git|kubectl)\b/,
  "Claude ToolSearch" => /\bToolSearch\b/,
  "generated Claude MCP name" => /mcp__claude_ai_/,
  "Claude-only session link" => /Claude-Session/
}.freeze

errors = []

def load_json(path, errors)
  JSON.parse(path.read)
rescue JSON::ParserError => e
  errors << "#{path.relative_path_from(ROOT)}: invalid JSON (#{e.message})"
  {}
end

def load_yaml(path, errors)
  YAML.safe_load(path.read, permitted_classes: [], aliases: false) || {}
rescue Psych::Exception => e
  errors << "#{path.relative_path_from(ROOT)}: invalid YAML (#{e.message})"
  {}
end

def frontmatter(path, errors)
  parts = path.read.split(/^---\s*$\n/, 3)
  unless parts.length == 3 && parts.first.empty?
    errors << "#{path.relative_path_from(ROOT)}: missing YAML frontmatter"
    return {}
  end

  YAML.safe_load(parts[1], permitted_classes: [], aliases: false) || {}
rescue Psych::Exception => e
  errors << "#{path.relative_path_from(ROOT)}: invalid frontmatter (#{e.message})"
  {}
end

marketplace = load_json(ROOT.join(".claude-plugin/marketplace.json"), errors)
marketplace_entries = marketplace["plugins"] || []

plugin_dirs = PLUGINS_ROOT.children.select(&:directory?).sort
plugin_manifests = {}

plugin_dirs.each do |plugin_dir|
  manifest_path = plugin_dir.join(".claude-plugin/plugin.json")
  unless manifest_path.file?
    errors << "#{plugin_dir.relative_path_from(ROOT)}: missing .claude-plugin/plugin.json"
    next
  end

  manifest = load_json(manifest_path, errors)
  plugin_name = plugin_dir.basename.to_s
  errors << "#{plugin_name}: manifest name must match the plugin directory" unless manifest["name"] == plugin_name
  plugin_manifests[plugin_name] = manifest

  entry = marketplace_entries.find { |candidate| candidate["name"] == plugin_name }
  if entry.nil?
    errors << "#{plugin_name}: missing from the marketplace manifest"
  elsif entry["source"] != "./plugins/#{plugin_name}"
    errors << "#{plugin_name}: marketplace source must be ./plugins/#{plugin_name}"
  end
end

marketplace_entries.each do |entry|
  name = entry["name"].to_s
  errors << "marketplace plugin #{name}: no matching directory under plugins/" unless plugin_manifests.key?(name)
end

agents_path = ROOT.join("AGENTS.md")
unless agents_path.symlink? && agents_path.readlink.to_s == "CLAUDE.md"
  errors << "AGENTS.md must be a symbolic link to CLAUDE.md"
end

readmes = READMES.to_h { |name| [name, ROOT.join(name).read] }
skill_dirs_by_name = {}

plugin_dirs.each do |plugin_dir|
  plugin_name = plugin_dir.basename.to_s
  skills_root = plugin_dir.join("skills")
  unless skills_root.directory?
    errors << "#{plugin_name}: missing skills directory"
    next
  end

  skills_root.children.select(&:directory?).sort.each do |skill_dir|
    skill_path = skill_dir.join("SKILL.md")
    unless skill_path.file?
      errors << "#{skill_dir.relative_path_from(ROOT)}: missing SKILL.md"
      next
    end

    metadata = frontmatter(skill_path, errors)
    name = metadata["name"].to_s
    description = metadata["description"].to_s
    skill_dirs_by_name[name] = skill_dir unless name.empty?

    errors << "#{name}: directory name must match frontmatter name" unless name == skill_dir.basename.to_s
    errors << "#{name}: name must be kebab-case and at most 64 characters" unless name.match?(/\A[a-z0-9]+(?:-[a-z0-9]+)*\z/) && name.length <= 64
    errors << "#{name}: description must be 1..1024 characters" unless description.length.between?(1, 1024)
    errors << "#{name}: description cannot contain angle brackets" if description.match?(/[<>]/)

    unknown = metadata.keys.map(&:to_s) - STANDARD_FIELDS - CLAUDE_FIELDS
    errors << "#{name}: unsupported frontmatter fields: #{unknown.join(", ")}" unless unknown.empty?

    openai_path = skill_dir.join("agents/openai.yaml")
    unless openai_path.file?
      errors << "#{name}: missing agents/openai.yaml"
      next
    end

    openai = load_yaml(openai_path, errors)
    interface = openai["interface"] || {}
    short_description = interface["short_description"].to_s
    default_prompt = interface["default_prompt"].to_s
    errors << "#{name}: interface.display_name is required" if interface["display_name"].to_s.empty?
    errors << "#{name}: short_description must be 25..64 characters" unless short_description.length.between?(25, 64)
    errors << "#{name}: default_prompt must mention $#{name}" unless default_prompt.include?("$#{name}")

    claude_user_only = metadata["disable-model-invocation"] == true
    codex_user_only = openai.dig("policy", "allow_implicit_invocation") == false
    unless claude_user_only == codex_user_only
      errors << "#{name}: Claude and Codex invocation policies are out of sync"
    end

    body = skill_path.read
    NONPORTABLE_BODY_PATTERNS.each do |label, pattern|
      errors << "#{name}: contains nonportable #{label}" if body.match?(pattern)
    end

    link = "plugins/#{plugin_name}/skills/#{name}/SKILL.md"
    readmes.each do |readme_name, text|
      errors << "#{name}: missing from #{readme_name}" unless text.include?(link)
    end
  end
end

LOCAL_SKILLS_ROOTS.each do |local_root|
  unless local_root.directory? && !local_root.symlink?
    errors << "#{local_root.relative_path_from(ROOT)}: must be a directory of per-skill symlinks"
    next
  end

  local_entries = local_root.children.sort
  local_names = local_entries.map { |entry| entry.basename.to_s }

  (skill_dirs_by_name.keys - local_names).each do |missing|
    errors << "#{local_root.relative_path_from(ROOT)}/#{missing}: missing local link to #{skill_dirs_by_name[missing].relative_path_from(ROOT)}"
  end

  local_entries.each do |entry|
    name = entry.basename.to_s
    canonical = skill_dirs_by_name[name]
    if canonical.nil?
      errors << "#{entry.relative_path_from(ROOT)}: stale local link with no canonical skill"
      next
    end

    unless entry.symlink?
      errors << "#{entry.relative_path_from(ROOT)}: must be a symlink to #{canonical.relative_path_from(ROOT)}"
      next
    end

    begin
      unless entry.realpath == canonical.realpath
        errors << "#{entry.relative_path_from(ROOT)}: must point to #{canonical.relative_path_from(ROOT)}"
      end
    rescue Errno::ENOENT
      errors << "#{entry.relative_path_from(ROOT)}: broken local skill link"
    end
  end
end

if errors.empty?
  versions = plugin_manifests.map { |name, manifest| "#{name} #{manifest["version"]}" }.join(", ")
  puts "Validation passed for #{skill_dirs_by_name.length} skills across #{plugin_manifests.length} plugins (#{versions})."
  exit 0
end

warn "Validation failed:"
errors.each { |error| warn "- #{error}" }
exit 1
```

- [ ] **Step 2: `scripts/validate.sh` 작성**

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

# A set LESS suppresses git's default LESS=FRX, so the pager blocks on empty
# output. Never page: this script must run unattended.
export GIT_PAGER=cat

git --no-pager diff --check

ruby scripts/validate.rb
python3 scripts/render_readme.py
```

```bash
chmod +x scripts/validate.sh
```

- [ ] **Step 3: 통과하는지 확인**

```bash
./scripts/validate.sh
```

기대: `Validation passed for 1 skills across 1 plugins (kar-plain 1.0.0).` 다음 줄에 `render_readme.py` 의 JSON.

- [ ] **Step 4: 호출 정책 동기화 검사가 실제로 잡는지 확인 (red)**

```bash
cp plugins/kar-plain/skills/kar-plain/SKILL.md /tmp/kar-plain-SKILL.md.bak
perl -pi -e 's/^disable-model-invocation: true$/disable-model-invocation: false/' plugins/kar-plain/skills/kar-plain/SKILL.md
ruby scripts/validate.rb; echo "exit=$?"
```

기대: `- kar-plain: Claude and Codex invocation policies are out of sync` 와 `exit=1`

- [ ] **Step 5: 심링크 검사가 실제로 잡는지 확인 (red)**

```bash
cp /tmp/kar-plain-SKILL.md.bak plugins/kar-plain/skills/kar-plain/SKILL.md
rm .claude/skills/kar-plain
ruby scripts/validate.rb; echo "exit=$?"
```

기대: `- .claude/skills/kar-plain: missing local link to plugins/kar-plain/skills/kar-plain` 와 `exit=1`

- [ ] **Step 6: 원상 복구하고 green 재확인**

```bash
ln -s ../../plugins/kar-plain/skills/kar-plain .claude/skills/kar-plain
./scripts/validate.sh
git diff --stat
```

기대: 검증 통과, `git diff --stat` 에 `SKILL.md` 변경 없음.

- [ ] **Step 7: 커밋**

```bash
git add scripts/validate.rb scripts/validate.sh
git commit -m "ci: validate manifests, invocation policy sync, and local skill links"
```

---

### Task 7: GitHub Actions

**Files:**
- Create: `.github/workflows/validate.yml`

**Interfaces:**
- Consumes: Task 6의 `scripts/validate.sh`

- [ ] **Step 1: 워크플로 작성**

```yaml
name: validate

on:
  push:
  pull_request:

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: "3.3"

      - uses: actions/setup-python@v5
        with:
          python-version: "3.12"

      - run: pip install -r scripts/requirements-preview.txt

      - run: ./scripts/validate.sh

      - name: Fail if the rendered previews drifted
        run: git --no-pager diff --exit-code -- docs/README.preview.html docs/README.en.preview.html
```

마지막 단계는 `render_readme.py` 가 생성하는 미리보기 HTML이 커밋된 내용과 일치하는지 본다. README를 고치고 미리보기를 갱신하지 않은 커밋을 잡는다.

- [ ] **Step 2: YAML 파싱 확인**

```bash
python3 -c "
import sys
try:
    import yaml
except ImportError:
    sys.exit(0)
yaml.safe_load(open('.github/workflows/validate.yml'))
print('WORKFLOW OK')
"
ruby -ryaml -e "YAML.safe_load_file('.github/workflows/validate.yml', aliases: true); puts 'WORKFLOW OK'"
```

기대: `WORKFLOW OK`

- [ ] **Step 3: 커밋**

```bash
git add .github/workflows/validate.yml
git commit -m "ci: run validation on push and pull request"
```

---

### Task 8: 검증 기록과 최종 점검

**Files:**
- Modify: `docs/verification.md` (끝에 절 추가)

**Interfaces:**
- Consumes: Task 1~7 전부

- [ ] **Step 1: 보존 대상이 변경되지 않았는지 확인**

```bash
cd /Users/justin/Desktop/kar-plain
BASE=$(git merge-base HEAD main)
echo "--- outputs/ 변경 (기대: 없음) ---"
git diff --stat "$BASE" HEAD -- outputs/
echo "--- verification.md 기존 내용 변경 (기대: 없음) ---"
git diff "$BASE" HEAD -- docs/verification.md
echo "--- invocation.svg 변경 (기대: 없음) ---"
git diff --stat "$BASE" HEAD -- assets/badges/invocation.svg
echo "--- SKILL.md 본문 해시 ---"
awk '/^---$/{n++; next} n>=2' plugins/kar-plain/skills/kar-plain/SKILL.md | md5 -q
cat /tmp/kar-plain-body-before.md5
```

기대: 앞의 세 diff가 모두 빈 출력, 마지막 두 해시가 일치.

- [ ] **Step 2: 전체 검증 재실행**

```bash
./scripts/validate.sh
```

기대: 통과.

- [ ] **Step 3: `docs/verification.md` 끝에 절 추가**

기존 절은 수정하지 않는다. 아래를 파일 끝에 붙이고, 실제 실행 결과에 맞춰 내용을 채운다. **확인하지 못한 항목은 확인하지 못했다고 적는다.**

```markdown
## 듀얼 호스트 플러그인 이식

2026년 10월 6일 저장소를 Claude Code와 Codex가 함께 쓰는 플러그인 마켓플레이스 구조로 옮겼다. 스킬 본문은 그대로 두고 배치와 메타데이터만 바꿨다.

| 대상 | 확인 내용 |
| --- | --- |
| 구조 | 정본은 `plugins/kar-plain/skills/kar-plain` 한 곳; `.claude/skills`와 `.agents/skills`는 그 정본을 가리키는 심링크 |
| 본문 보존 | `SKILL.md`의 frontmatter 아래 본문이 이동 전후 해시 일치, 영문 308단어 유지 |
| 호출 정책 | Claude의 `disable-model-invocation: true`와 Codex의 `allow_implicit_invocation: false`가 일치; `scripts/validate.rb`가 불일치를 오류로 처리 |
| 검증 | `scripts/validate.sh` 통과 — 매니페스트 파싱, frontmatter 필드, 심링크 무결성, `AGENTS.md` 심링크, 두 README의 스킬 링크 |
| 검증 자체 시험 | 호출 정책을 일부러 어긋나게 하고 심링크를 지워 두 검사가 각각 실패를 보고하는 것을 확인한 뒤 원복 |
| README | 두 README의 상대 링크와 이미지 검사 통과, 본문 단어 수 동기화 확인 |
| 배지 | `host.svg`를 `Codex · Claude`로 다시 그리고 XML 파싱 확인; `invocation.svg`는 무수정 |
| 보존 자료 | `outputs/**`와 기존 검증 기록은 바이트 단위로 무수정 |

확인하지 않은 것: 실제 Claude Code와 Codex 클라이언트에 마켓플레이스를 등록해 설치·호출하는 시험은 이 기록 시점에 수행하지 않았다. 구조와 메타데이터 검사만 통과한 상태다.
```

- [ ] **Step 4: 커밋**

```bash
git add docs/verification.md
git commit -m "docs: record the dual-host plugin migration scope"
```

- [ ] **Step 5: 변경 전체 요약**

```bash
git --no-pager diff --stat "$(git merge-base HEAD main)" HEAD
git --no-pager log --oneline "$(git merge-base HEAD main)"..HEAD
```

---

## Self-Review

**Spec coverage**

| 스펙 절 | 담당 Task |
| --- | --- |
| 5.1 `marketplace.json` | Task 1 Step 3 |
| 5.2 `plugin.json` | Task 1 Step 4 |
| 5.3 `SKILL.md` frontmatter | Task 1 Step 5 |
| 5.4 `openai.yaml` 무수정 | Task 1 Step 7(검사만) |
| 5.5 로컬 링크와 `CLAUDE.md`/`AGENTS.md` | Task 2 |
| 5.6 `validate.rb` | Task 6 Step 1 |
| 5.7 `validate.sh` | Task 6 Step 2 |
| 5.7a `render_readme.py` | Task 3 |
| 5.8 CI | Task 7 |
| 5.9 README 2종 | Task 3(링크) + Task 4(본문) |
| 5.10 `host.svg` | Task 5 |
| 5.11 `outputs/**` 무수정 | Task 8 Step 1(검사) |
| 5.12 `docs/verification.md` | Task 8 Step 3 |
| 7. 완료 조건 1~8 | Task 8 Step 1~2 |
| 7. 완료 조건 9 (저장소 소개문) | 계획 밖 — 사용자에게 이미 수정안 전달 |

**Placeholder scan:** 없음. 모든 파일 내용이 실제 값으로 적혀 있다.

**Type consistency:** 정본 경로 `plugins/kar-plain/skills/kar-plain`가 Task 1·2·3·6에서 동일하게 쓰인다. `validate.rb`의 README 링크 검사 문자열 `plugins/kar-plain/skills/kar-plain/SKILL.md`가 Task 3 Step 5의 치환 결과와 일치한다. 배지 기하값 `139 / 105 / 86.5`가 Task 5 Step 1의 계산과 Step 2의 SVG, Step 3의 검사에서 일치한다.
