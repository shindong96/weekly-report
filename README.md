# weekly-report — Claude Code 주간업무보고 스킬

Git/GitHub 활동(내 PR, 푸시 안 된 로컬 커밋, 작업중 변경)을 모아
**팀장·파트장이 30초 안에 훑을 수 있는** 한국어 주간보고 초안을 만들어 주는 [Claude Code](https://claude.com/claude-code) 스킬입니다.

- 커밋 로그를 옮겨 적지 않고, "무엇을 했고 어디까지 왔는가"를 사람이 읽는 문장으로 다시 씁니다.
- 읽는 사람이 **비개발자**라는 전제로 씁니다. 코드 용어를 쓰지 않고, 필요할 때만 "왜 했는지"를 사용자·운영 관점으로 붙입니다.
- 결과는 Teams / Slack / Notion에 그대로 붙여넣을 수 있는 마크다운입니다.

## 출력 예시

```
`금주업무`
🚀 **서비스 A 출시**

* 🟢 계정 삭제 실패 시 데이터가 반쯤 지워진 채 남던 문제 수정 [(PR #123)](https://...)
   * 삭제 도중 오류가 나도 되돌리지 않고 그대로 확정되어, 가족 3명 중 2명만 지워진 상태로 남을 수 있었습니다.
   * 오류가 나면 전체를 되돌리도록 수정하고 리뷰 요청하였습니다.

➕ **그 외 업무**

* ❌ 앱팀 협업 작업
   * 다른 우선 과제로 인해 지난 주 킥오프했던 작업들이 다음 달 이후로 미뤄집니다.
   * 미뤄지는 작업 리스트
      * 측정 기록 변경분만 받아오기 기능
      * 가족 계정 간 인증 코드 분리

`차주업무`
🚀 **서비스 A 출시**

* 계정 삭제 수정 반영
   * 리뷰 반영 후 반영 완료할 예정입니다.
```

## 설치

필요한 것: `git`, `python3`, [GitHub CLI](https://cli.github.com/) (`gh auth login` 완료 상태).

**개인용 (어느 프로젝트에서나 사용)** — 특정 레포에 묶이지 않습니다.

```bash
git clone https://github.com/shindong96/weekly-report.git ~/.claude/skills/weekly-report
```

설정 없이 바로 됩니다. 레포 폴더 안에서 "주간보고 만들어줘"라고 하면 그 레포의 활동을 모읍니다.
레포 여러 개를 한 보고서에 모으거나 카테고리를 나누고 싶을 때만 설정 파일을 만드세요.

```bash
cp ~/.claude/skills/weekly-report/config.example.json ~/.claude/skills/weekly-report/config.json
```

**팀 공유 (레포 안에 넣어 클론한 사람 모두 사용)**

```bash
git clone https://github.com/shindong96/weekly-report.git .claude/skills/weekly-report
```

이 경우 `config.json`은 각자 만들어야 합니다. `.gitignore`에 들어 있어 커밋되지 않습니다.
공용 설정을 두고 싶으면 `WEEKLY_REPORT_CONFIG=/path/to/config.json` 환경변수로 경로를 바꿀 수 있습니다.

## 설정 (`config.json`, 선택)

없으면 현재 디렉터리의 레포 하나, 카테고리 "➕ 그 외 업무" 하나로 동작합니다.

```json
{
  "output_dir": "~/Desktop/weekly-report",
  "repos": [
    { "path": "~/work/my-service-api", "name": "my-service", "default_category": "서비스 A 출시" }
  ],
  "categories": [
    { "emoji": "🚀", "name": "서비스 A 출시", "hints": ["release", "출시"] },
    { "emoji": "➕", "name": "그 외 업무", "hints": [] }
  ]
}
```

| 키 | 설명 |
|---|---|
| `output_dir` | 보고서가 저장되는 폴더. 레포 안에는 절대 저장하지 않습니다. |
| `repos[].path` | 수집할 로컬 레포. 여러 개 가능. |
| `repos[].default_category` | 힌트로 분류가 안 될 때 쓸 카테고리. |
| `categories[]` | 보고서 카테고리. 배열 순서가 출력 순서입니다. 마지막은 "그 외 업무" 같은 잡동사니 칸으로 두세요. |
| `categories[].hints` | 브랜치명·PR 제목·파일 경로에서 이 카테고리를 판별할 키워드. |

## 사용

Claude Code에서 이렇게 말하면 됩니다.

```
주간보고 초안 만들어줘
```

흐름:

1. `scripts/collect.sh`가 최근 7일치 PR·로컬 커밋·작업중 변경을 모읍니다. 설정이 없으면 현재 레포, 있으면 설정의 레포들. (`bash scripts/collect.sh 10`처럼 기간 조정 가능)
2. Claude가 카테고리별로 분류하고, 같은 맥락의 PR·커밋을 하나의 작업으로 묶어 문장을 씁니다.
3. 초안을 보여준 뒤 "커밋에 안 남는 일(미팅, 문서, 의사결정)이 있으면 알려 달라"고 묻습니다.
4. `output_dir/weekly-report-YYYY-MM-DD.md`로 저장합니다.

## 문체 규칙 요약

전체 규칙은 [SKILL.md](SKILL.md)에 있습니다. 핵심만:

- 1단계 불릿 = 작업 제목 + 상태 이모지(🟢 PR 있음 / 🟠 로컬만 / ❌ 미뤄짐) + 링크
- 2단계 불릿 = 한 불릿에 한 문장, 최대 3개. 순서는 **왜 → 무엇 → 어디까지**
- "왜"는 제목만으로 이유가 안 보일 때만. 사용자·운영 관점으로만 쓰고 코드 설명은 금지
- 나열은 3단계 불릿으로
- 원인 분석, 테스트 건수, 공수 추정치는 쓰지 않음. 숫자는 규모를 보여주는 것 하나만
- 내용 없는 카테고리는 헤더째 삭제

## 커스터마이즈

- 보고 양식이 다르면 `references/template.md`와 `SKILL.md`의 "3. 문장 쓰기"를 고치세요.
- 용어 치환표(`SKILL.md`)는 팀에서 쓰는 말에 맞게 바꾸면 됩니다.

## 구조

```
weekly-report/
├── SKILL.md                 # Claude가 따르는 규칙 전체
├── config.example.json      # 설정 예시 (config.json 으로 복사)
├── references/template.md   # 출력 템플릿과 문체 규칙
└── scripts/
    ├── collect.sh           # PR·커밋·작업중 변경 수집
    ├── _cfg.py              # config.json 파서
    └── _prs.py              # gh pr list 출력 정리
```
