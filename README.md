<p align="center">
  <img src="assets/kar-plain-banner.svg" alt="Kar-plain: 하나의 질문에서 글, 도해, 웹, 영상으로 이어지는 네 설명 형식" width="100%">
</p>

<h1 align="center">Kar-plain<br>이해할 내용에 맞춰<br>설명 형식을 고릅니다.</h1>

<p align="center">
  글·도해·웹·영상으로 주제를 설명하는 Claude Code·Codex 스킬입니다.<br>
  필요한 순간에 호출하고, 한국어나 영어로 결과물을 만드세요.
</p>

<p align="center">
  안드레이 카파시의 <a href="https://x.com/karpathy/status/2105819303471976479?s=20">원문 트윗</a>에서 영감을 받은 비공식 구현입니다.
</p>

<p align="center">
  <a href="#설치"><img src="assets/badges/host.svg" alt="사용 환경: Codex · Claude"></a>
  <a href="#사용법"><img src="assets/badges/modes.svg" alt="설명 형식: 4가지"></a>
  <a href="#작동-원칙"><img src="assets/badges/language.svg" alt="출력 언어: 한국어 / 영어"></a>
  <a href="plugins/kar-plain/skills/kar-plain/agents/openai.yaml"><img src="assets/badges/invocation.svg" alt="호출 정책: 명시적 호출"></a>
  <a href="plugins/kar-plain/skills/kar-plain/SKILL.md"><img src="assets/badges/body.svg" alt="실행 본문: 영어 308단어"></a>
  <a href="LICENSE"><img src="assets/badges/license.svg" alt="라이선스: MIT"></a>
</p>

<p align="center">
  <strong>한국어</strong> · <a href="README.en.md">English</a> ·
  <a href="#예시">예시</a> · <a href="#설치">설치</a> ·
  <a href="#사용법">사용법</a> · <a href="#확인한-범위">확인한 범위</a>
</p>

설치 후 Claude Code나 Codex에서 주제와 형식을 지정하세요. 아래는 Claude Code 플러그인 설치 기준입니다. 설치 방식에 따라 앞부분이 달라지므로 [호출 이름](#호출-이름)을 확인하세요.

```text
/kar-plain:kar-plain 도해: 이 스킬의 작동 과정을 설명해 줘.
```

## 예시

이 스킬을 적용해 스킬 자체를 설명하는 글, 도해, 웹, 영상을 만들었습니다. 아래는 한국어 예시입니다. [영어 예시](README.en.md#examples)도 별도로 제공합니다.

아래 네 형식 예시는 299단어 본문으로 제작한 초기 자료입니다. 글 모드 수정 전후의 A/B/C 결과와 분석은 [비교 기록](docs/prose-comparison.txt)에 있습니다. 현재 지침은 [SKILL.md](plugins/kar-plain/skills/kar-plain/SKILL.md)를 확인하세요. 예시 결과물은 Codex용으로 제작해 호출문이 `$kar-plain` 형식입니다.

| 형식 | 살펴볼 내용 | 결과물 |
| --- | --- | --- |
| 글 | 목적, 호출 방법과 의미 보존 원칙 | [소개 글](outputs/article.txt) |
| 도해 | 호출부터 형식 선택, 검증과 완료까지 | [SVG](outputs/diagram.svg) · [Mermaid 원본](outputs/diagram.mmd) |
| 웹 | 목적, 출력 언어와 주제를 바꾸면 달라지는 호출문 | [단일 HTML](outputs/index.html) |
| 영상 | 설명 형식과 완료 조건을 순서대로 보기 | [60초 MP4](outputs/kar-plain.mp4) · [SRT 자막](outputs/kar-plain.srt) |

### 글로 읽기

> Kar-plain은 Codex에서 주제를 한국어나 영어로 설명할 때 쓰는 스킬이다. 정확한 내용을 읽어야 하면 글을 쓰고, 관계를 봐야 하면 도해를 만든다. 값을 바꾸며 살펴볼 때는 웹을, 순서대로 따라 볼 때는 영상을 선택한다.

[소개 글 전문 읽기](outputs/article.txt)

### 도해로 보기

<p align="center">
  <a href="outputs/diagram.svg"><img src="outputs/diagram.svg" alt="명시적 호출, 공통 지침, 네 형식 선택, 원문 대조와 모드별 확인을 거쳐 완료 결과 또는 부분 결과로 이어지는 흐름도" width="760"></a>
</p>

### 웹에서 직접 선택하기

[![목적 버튼과 주제 입력에 따라 형식, 결과물과 호출문을 표시하는 웹 화면](assets/web-preview.jpg)](outputs/index.html)

`index.html`을 내려받아 브라우저에서 여세요. 목적 버튼, 출력 언어와 주제 입력을 바꾸면 추천 형식과 호출문이 달라집니다. 이 페이지는 형식 선택을 체험하는 예시입니다. 실제 생성은 표시된 호출문을 Codex에 입력해 실행합니다. Claude Code에서는 앞부분을 [호출 이름](#호출-이름)에 맞게 바꾸세요. 도해와 영상도 HTML 안에 포함돼 있습니다.

### 영상으로 따라 보기

[![60초 영상 중 글, 도해, 웹, 영상으로 분기하는 장면의 움직이는 미리보기](assets/video-preview.gif)](outputs/kar-plain.mp4)

위 이미지는 전체 영상 중 18초 구간입니다. [60초 MP4](outputs/kar-plain.mp4)를 내려받아 재생하세요. 영상은 1280×720·24fps이며, 한국어 자막이 화면에 표시됩니다. 음성 나레이션은 없습니다.

## 설치

Claude Code와 Codex에서 모두 씁니다. Claude Code는 플러그인으로, Codex는 수동 설치로 쓰는 방법을 권장합니다.

### Claude Code

Claude Code 세션 안에서 실행하세요. 운영체제와 관계없이 같습니다.

```text
/plugin marketplace add Burntgogi/kar-plain
/plugin install kar-plain@kar-plain
```

새 버전은 `/plugin` 메뉴나 터미널의 `claude plugin update kar-plain@kar-plain`으로 받습니다. 적용하려면 Claude Code를 다시 시작하세요.

### Codex

Codex는 `$kar-plain`을 그대로 쓰는 [수동 설치](#수동-설치)를 권장합니다. Codex는 Claude 형식 마켓플레이스도 읽도록 안내하지만, 아래 플러그인 설치는 아직 실제 Codex에서 시험하지 않았습니다.

```bash
codex plugin marketplace add Burntgogi/kar-plain --ref main
codex plugin add kar-plain@kar-plain
```

### 수동 설치

`plugins/kar-plain/skills/kar-plain` 폴더를 개인 스킬 디렉터리에 복사합니다. 설치할 파일은 아래 두 개입니다. README, 배너와 예시 결과물은 설치 폴더 밖에 둡니다.

```text
kar-plain/
├── SKILL.md
└── agents/openai.yaml
```

macOS·Linux:

```bash
git clone https://github.com/Burntgogi/kar-plain.git
mkdir -p ~/.claude/skills
cp -R kar-plain/plugins/kar-plain/skills/kar-plain ~/.claude/skills/
```

Windows PowerShell:

```powershell
git clone https://github.com/Burntgogi/kar-plain.git
New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude\skills" | Out-Null
Copy-Item -Recurse kar-plain\plugins\kar-plain\skills\kar-plain "$env:USERPROFILE\.claude\skills\"
```

위 명령은 Claude Code용입니다. Codex에서는 `.claude\skills`와 `.claude/skills`를 `.agents\skills`와 `.agents/skills`로 바꾸세요. 사용 중인 클라이언트가 별도 개인 스킬 경로를 제공한다면 그 경로를 사용하세요. 새 스킬이 보이지 않으면 클라이언트를 다시 시작하세요.

### 호출 이름

| 설치 방식 | Claude Code | Codex |
| --- | --- | --- |
| 플러그인 | `/kar-plain:kar-plain` | `$kar-plain:kar-plain` (미검증) |
| 수동 설치 | `/kar-plain` | `$kar-plain` |

스킬 설치에는 별도 API 키나 Python이 필요하지 않습니다. 웹·영상 제작에 필요한 도구는 작업에 따라 달라집니다.

## 사용법

아래 호출문은 Codex 수동 설치 기준입니다. 다른 방식에서는 `$kar-plain`을 [호출 이름](#호출-이름)의 해당 칸으로 바꾸세요. 예를 들어 Claude Code 플러그인에서는 `/kar-plain:kar-plain 글: …`입니다.

| 필요 | 호출 예시 |
| --- | --- |
| 정확한 내용 읽기 | `$kar-plain 글: 이 안내문의 조건과 예외를 설명해 줘.` |
| 관계와 순서 보기 | `$kar-plain 도해: 이 절차의 분기와 예외를 보여 줘.` |
| 값을 바꾸며 탐색하기 | `$kar-plain 웹: 복리 계산에서 금리와 기간을 바꿔 볼 수 있는 HTML을 만들어 줘.` |
| 순서대로 시청하기 | `$kar-plain 영상: 이 과정의 변화를 한국어 자막이 있는 60초 영상으로 만들어 줘.` |
| 형식 선택 맡기기 | `$kar-plain 자동: 다음 주제를 이해하기 쉽게 설명해 줘.` |

모드를 생략하면 요청에 맞는 형식 하나를 고릅니다. 여러 형식이 필요하면 함께 요청하세요. 출력 언어는 지정한 언어, 에이전트에 전달된 언어 선호, 현재 요청의 언어 순으로 고릅니다. 인용한 원문이 영어라는 이유로 영어를 선택하지 않습니다. 한국어로 요청하면서 영어 출력을 지정할 수도 있습니다. 음성 나레이션은 따로 요청하세요.

```text
$kar-plain 도해: 이 과정을 영어로 설명해 줘.
```

## 작동 원칙

핵심 실행 본문은 영어 308단어입니다. 두 호스트 모두 스킬을 선택하면 `SKILL.md` 본문 전체를 읽고 요청한 형식을 적용합니다. 명시적 호출 정책은 호스트별 설정 두 곳에 함께 적습니다 — Codex는 `allow_implicit_invocation: false`, Claude Code는 `disable-model-invocation: true`입니다. [Codex 공식 안내](https://learn.chatgpt.com/docs/build-skills) · [Claude Code 공식 안내](https://code.claude.com/docs/en/skills)

형식이 달라져도 조건, 부정, 수치, 의무와 가능성의 차이를 보존합니다. 원자료의 사실과 추가한 예시·가정을 구별합니다. 영어 절차문과 기술 설명에는 ASD-STE100을 작성 기준으로 삼고, 한국어와 그 밖의 영어 글에는 STE-inspired clarity를 적용합니다. 전문용어를 풀고 주장 강도와 논리 연결을 보존하며, 절차의 행동을 분리합니다. 선택한 언어로 자연스럽게 쓰고 검증된 표준 준수를 주장하지 않습니다.

도해는 관계와 방향을, 웹은 주요 조작을, 영상은 재생과 장면 시간을 확인합니다. 완성 영상을 요청한 경우 재생 가능한 파일까지 만들어야 합니다. 필요한 도구를 사용할 수 없으면 막힌 이유와 부분 결과를 밝힙니다.

## 확인한 범위

스킬 파일 구조를 검사하고 한국어와 영어로 네 형식의 결과물을 각각 만들었습니다. 웹의 네 모드 전환, 출력 언어 선택, 주제 입력, 빈 입력 처리와 모바일 배치를 확인했습니다. 두 영상은 전체 파일 디코딩과 브라우저 재생을 확인했습니다. Claude Code에서는 플러그인 설치와 명시적 호출을 확인했으며, Codex 플러그인 설치는 아직 확인하지 않았습니다.

글 모드는 수정 전후 24개 결과를 두 차례 익명 비교했습니다. 첫 C는 채택하지 않았으며, 보강한 C2를 기존 A/B와 다시 비교해 최종 지침을 선택했습니다. 총 32개의 서로 다른 결과가 있고 A/B의 이전 결과는 그대로 보존했습니다. 평가는 독립 에이전트의 원문 대조와 언어학적 검토이며 인간 독자의 이해도 시험은 아닙니다.

이 기록은 이번 제작 사례의 확인 범위입니다. 다른 주제의 설명 품질이나 모든 환경의 동작을 평가한 결과는 아닙니다. README는 로컬과 GitHub에서 렌더링해 확인했습니다. [검증 기록](docs/verification.md)

## 라이선스

[MIT 라이선스](LICENSE) · Copyright (c) 2026 Burntgogi

## 출처와 문서

이 스킬은 [안드레이 카파시의 원문 트윗](https://x.com/karpathy/status/2105819303471976479?s=20)에서 영감을 받았습니다. 글, 도해, 웹과 영상으로 이해를 돕자는 제안을 한국어와 영어 Claude Code·Codex 작업에 적용한 비공식 구현입니다.

[AI Slop 탈곡기](https://github.com/Burntgogi/ai-slop-thresher)의 배너·가운데 정렬 소개·배지·언어 전환·예시 배치를 참고했습니다. 배너와 문서는 이 저장소용으로 새로 작성했습니다.

[스킬 지침](plugins/kar-plain/skills/kar-plain/SKILL.md) · [호출 설정](plugins/kar-plain/skills/kar-plain/agents/openai.yaml) · [README 설계와 참고 자료](docs/readme-design.md)
