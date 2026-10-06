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

## 줄바꿈

- 이 저장소의 기존 텍스트 파일은 CRLF 를 쓴다. 기존 파일을 고칠 때 줄바꿈을
  바꾸지 않는다.
- 실행 스크립트(`scripts/*.sh`, `scripts/*.rb`)는 LF 로 쓴다. shebang 줄에
  `\r` 이 붙으면 인터프리터를 찾지 못한다.

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
