# README 설계와 참고 자료

한국어 `README.md`와 영어 `README.en.md`는 같은 순서로 구성했다. 영어판은 한국어 기본 출력과 한국어 예시를 영어로 안내한다.

스킬의 아이디어는 [안드레이 카파시의 원문 트윗](https://x.com/karpathy/status/2105819303471976479?s=20)에서 영감을 받았다. 글, 도해, 웹과 영상으로 이해를 돕자는 제안을 한국어 Codex 작업에 적용한 비공식 구현이다. 두 README의 상단 소개와 출처 절에 원문 링크를 표시한다.

| 순서 | 구성 | 목적 |
| --- | --- | --- |
| 1 | 가로 SVG 배너와 가운데 정렬 소개 | 하나의 질문에서 네 설명 형식으로 이어지는 구조를 보여준다. |
| 2 | 배지 여섯 개와 언어 전환 | 환경, 형식 수, 기본 언어, 호출 정책, 본문 크기와 라이선스를 확인한다. |
| 3 | 호출문과 실제 결과물 | 설치 전에 무엇을 만들 수 있는지 살펴본다. |
| 4 | 설치, 사용법과 작동 원칙 | 필요한 파일과 요청 방법을 확인한다. |
| 5 | 확인한 범위와 출처 | 제작 사례의 검증 범위와 참고 자료를 밝힌다. |

## 참고한 디자인

[Burntgogi/ai-slop-thresher](https://github.com/Burntgogi/ai-slop-thresher)의 가로 배너, 가운데 정렬 제목·소개, 배지 행, 언어 전환과 결과 예시 배치를 참고했다. 저장소 화면과 화면 구성 문서를 함께 확인했다. 2026년 10월 5일 확인한 저장소의 최신 커밋은 `8ce371e845187198fb18b2dd15ec8d56454ae377`이다. [해당 리비전 README](https://github.com/Burntgogi/ai-slop-thresher/blob/8ce371e845187198fb18b2dd15ec8d56454ae377/README.md) · [화면 구성 문서](https://github.com/Burntgogi/ai-slop-thresher/blob/8ce371e845187198fb18b2dd15ec8d56454ae377/docs/github-frontpage.md)

참고 배너의 캐릭터와 이미지 파일을 재사용하지 않았다. 새 배너는 네 모드의 관계를 나타내는 SVG다. 색상은 기존 웹·도해 예시의 크림색, 짙은 녹색과 금색으로 맞췄다. 배지는 로컬 SVG로 만들었으며 환경, 형식 수, 기본 언어, 호출 정책, 본문 크기와 MIT 라이선스를 표시한다.

## 설명과 윤문

`kar-plain`의 글 모드를 적용해 독자가 이해할 내용, 형식별 차이와 완료 조건을 먼저 정리했다. `thresh`를 적용해 한국어 초안의 반복 예고, 과잉 수식과 명사화를 다듬었다. 제목, 링크, 표, 호출문과 의미 보존 조건은 유지했다. 영어판은 이 구성을 따라 번역하고 사실·수치·조건을 대조했다. 두 스킬은 작성할 때 사용했으며 `kar-plain`의 설치 의존성으로 추가하지 않았다.

## GitHub 표시와 로컬 미리보기

README 본문에는 이미지, 가운데 정렬 HTML, 제목, 표와 링크를 사용한다. CSS와 JavaScript는 로컬 미리보기에서만 사용한다. 저장소 내부 파일은 상대 경로로 연결한다. [GitHub README 안내](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-readmes)

웹은 화면 이미지와 HTML 링크로, 영상은 실제 MP4에서 추출한 18초 GIF와 전체 파일 링크로 보여준다. 웹 예시를 내려받아 열면 도해와 영상까지 사용할 수 있다. GitHub 저장소에 올린 HTML의 실행이나 MP4의 자동 인라인 재생을 전제로 하지 않는다.

`scripts/render_readme.py`는 두 README의 Markdown을 렌더링해 미리보기를 만든다. 로컬 미리보기는 GitHub에 가까운 본문 서식을 확인하는 자료이며, GitHub에 게시한 화면은 아니다. 언어 전환 링크만 로컬 HTML 미리보기로 연결하고 원본 README의 링크는 유지한다.

미리보기를 다시 만들려면 Python 환경에 `scripts/requirements-preview.txt`의 패키지를 설치하고 `python scripts/render_readme.py`를 실행한다. 이 도구는 README 확인용이며 스킬 설치에 필요하지 않다.
