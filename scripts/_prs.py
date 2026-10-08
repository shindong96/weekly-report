#!/usr/bin/env python3
"""gh pr list --json 출력을 stdin으로 받아 기간 필터 후 사람이 읽을 형태로 출력한다.
usage: gh pr list ... | _prs.py 2026-09-04
"""
import json
import re
import sys

since = sys.argv[1]

try:
    prs = json.load(sys.stdin)
except Exception:
    print("  (PR 조회 실패 - gh 인증 또는 remote 설정을 확인하세요)")
    sys.exit(0)

recent = [p for p in prs if (p.get("updatedAt") or "")[:10] >= since]
if not recent:
    print("  (해당 기간 PR 없음)")
    sys.exit(0)

for p in sorted(recent, key=lambda x: x.get("updatedAt", ""), reverse=True):
    flags = p.get("state", "")
    if p.get("isDraft"):
        flags += "/DRAFT"
    if p.get("mergedAt"):
        flags += f" merged {p['mergedAt'][:10]}"
    body = re.sub(r"\s+", " ", p.get("body") or "").strip()[:400]
    print(f"- #{p['number']} [{flags}] {p['title']}")
    print(f"  branch: {p.get('headRefName', '?')}")
    print(f"  url: {p.get('url', '')}")
    if body:
        print(f"  body: {body}")
