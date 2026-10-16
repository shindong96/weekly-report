#!/usr/bin/env bash
# 보고서 마크다운을 서식 있는 HTML 로 바꿔 클립보드에 올린다. Teams/Slack 입력창에 그대로 붙여넣으면 불릿·볼드·링크가 살아난다.
# usage: bash scripts/copy-teams.sh ~/Desktop/weekly-report/weekly-report-2026-10-16.md
set -euo pipefail
FILE="${1:?보고서 파일 경로가 필요합니다}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
case "$(uname)" in
  Darwin)
    HEX=$(python3 "$SCRIPT_DIR/_md2html.py" "$FILE" | xxd -p | tr -d '\n')
    osascript -e "set the clipboard to «data HTML${HEX}»"
    echo "클립보드에 서식 있는 보고서를 올렸습니다. Teams 입력창에 붙여넣으세요: $FILE"
    ;;
  *)
    python3 "$SCRIPT_DIR/_md2html.py" "$FILE" | xclip -selection clipboard -t text/html 2>/dev/null \
      || { echo "xclip 이 필요합니다 (apt install xclip)" >&2; exit 1; }
    echo "클립보드에 올렸습니다: $FILE"
    ;;
esac
