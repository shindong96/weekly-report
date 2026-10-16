#!/usr/bin/env bash
# 최근 N일간의 내 PR / 푸시 안 된 로컬 커밋 / 작업중 변경을 마크다운으로 덤프한다.
# usage: bash scripts/collect.sh [days]
set -uo pipefail

DAYS="${1:-7}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${WEEKLY_REPORT_CONFIG:-$SCRIPT_DIR/../config.json}"

command -v python3 >/dev/null || { echo "python3가 필요합니다." >&2; exit 1; }

# config.json 이 없으면 현재 디렉터리의 git 레포 하나만 수집한다 (카테고리는 "그 외 업무" 하나).
REPO_LINES=""
if [ -f "$CONFIG" ]; then
  REPO_LINES=$(python3 "$SCRIPT_DIR/_cfg.py" "$CONFIG")
else
  TOP=$(git rev-parse --show-toplevel 2>/dev/null) || {
    echo "config.json 이 없고 현재 디렉터리도 git 레포가 아닙니다." >&2
    echo "config.example.json 을 config.json 으로 복사해 레포 경로와 카테고리를 채우거나, 레포 안에서 실행하세요." >&2
    exit 1
  }
  echo "> 안내: config.json 이 없어 현재 레포($TOP)만 수집합니다. 카테고리는 '그 외 업무' 하나입니다." >&2
  REPO_LINES=$(printf '%s\t%s\t%s' "$TOP" "$(basename "$TOP")" "그 외 업무")
fi

SINCE=$(python3 -c "import datetime,sys;print((datetime.date.today()-datetime.timedelta(days=int(sys.argv[1]))).isoformat())" "$DAYS")
HAS_GH=0; command -v gh >/dev/null && gh auth status >/dev/null 2>&1 && HAS_GH=1

echo "# Weekly raw data (since ${SINCE}, ${DAYS}d)"
echo
[ "$HAS_GH" -eq 0 ] && echo "> 경고: gh CLI를 쓸 수 없어 PR 정보가 비어 있습니다. \`gh auth login\` 후 다시 실행하세요."

while IFS=$'\t' read -r REPO_PATH NAME DEFAULT_CAT; do
  [ -z "$REPO_PATH" ] && continue
  echo
  echo "## repo: ${NAME}  (기본 카테고리: ${DEFAULT_CAT})"
  echo "path: ${REPO_PATH}"

  if ! git -C "$REPO_PATH" rev-parse --git-dir >/dev/null 2>&1; then
    echo "  !! git 레포가 아니거나 경로가 없습니다. config.json을 확인하세요."
    continue
  fi

  # ---------- PRs ----------
  echo
  echo "### PRs (내가 작성, ${SINCE} 이후 업데이트)"
  if [ "$HAS_GH" -eq 1 ]; then
    (cd "$REPO_PATH" && gh pr list --author "@me" --state all --limit 100 \
        --json number,title,state,isDraft,url,headRefName,baseRefName,createdAt,updatedAt,mergedAt,body 2>/dev/null) \
      | python3 "$SCRIPT_DIR/_prs.py" "$SINCE" "$REPO_PATH"
  else
    echo "  (gh 미사용)"
  fi

  # ---------- 푸시 안 된 로컬 커밋 (워크트리의 브랜치도 ref를 공유하므로 함께 잡힘) ----------
  echo
  echo "### 푸시되지 않은 로컬 커밋 (브랜치별)"
  FOUND=0
  while IFS= read -r br; do
    LOG=$(git -C "$REPO_PATH" log "$br" --not --remotes --since="$SINCE" \
            --pretty=format:'    - %h %ad %s' --date=short 2>/dev/null)
    if [ -n "$LOG" ]; then
      FOUND=1
      echo "  branch: ${br}"
      echo "$LOG"
      FILES=$(git -C "$REPO_PATH" log "$br" --not --remotes --since="$SINCE" \
                --name-only --pretty=format: 2>/dev/null | sort -u | grep -v '^$' | head -15 | tr '\n' ' ')
      [ -n "$FILES" ] && echo "    files: ${FILES}"
    fi
  done < <(git -C "$REPO_PATH" for-each-ref --format='%(refname:short)' refs/heads 2>/dev/null)
  [ "$FOUND" -eq 0 ] && echo "  (없음)"

  # ---------- 브랜치 개요 (참고용) ----------
  echo
  echo "### 최근 활동 브랜치 (참고용)"
  git -C "$REPO_PATH" for-each-ref --sort=-committerdate refs/heads \
    --format='  - %(refname:short) | %(committerdate:short) | %(contents:subject)' 2>/dev/null | head -15

  # ---------- 워크트리 & 커밋 안 된 변경 ----------
  echo
  echo "### 워크트리 / 커밋 안 된 변경"
  git -C "$REPO_PATH" worktree list --porcelain 2>/dev/null | awk '/^worktree /{print $2}' | while read -r WT; do
    BR=$(git -C "$WT" rev-parse --abbrev-ref HEAD 2>/dev/null)
    echo "  worktree: ${WT} (${BR})"
    DIRTY=$(git -C "$WT" status --porcelain 2>/dev/null | head -20)
    if [ -n "$DIRTY" ]; then echo "$DIRTY" | sed 's/^/      /'; else echo "      (clean)"; fi
  done
  STASH=$(git -C "$REPO_PATH" stash list 2>/dev/null | head -5)
  [ -n "$STASH" ] && { echo "  stash:"; echo "$STASH" | sed 's/^/    - /'; }
done <<< "$REPO_LINES"

echo
echo "---"
echo "끝. 이 데이터는 초안 재료입니다. 커밋 메시지를 그대로 옮기지 말고 맥락을 담은 문장으로 다시 쓰세요."
