#!/usr/bin/env python3
"""gh pr list --json 출력을 stdin으로 받아 기간 필터 후 사람이 읽을 형태로 출력한다.
usage: gh pr list ... | _prs.py 2026-09-04 [repo_path]

repo_path 를 주면 PR 브랜치에서 '기간 내 머지 아닌 커밋'을 세어 함께 출력한다.
dev 를 머지해 넣기만 한 PR 은 updatedAt 이 갱신되지만 실제 작업은 없으므로 금주업무가 아니다.
"""
import json
import re
import subprocess
import sys

since = sys.argv[1]
repo = sys.argv[2] if len(sys.argv) > 2 else None

try:
    prs = json.load(sys.stdin)
except Exception:
    print("  (PR 조회 실패 - gh 인증 또는 remote 설정을 확인하세요)")
    sys.exit(0)

recent = [p for p in prs if (p.get("updatedAt") or "")[:10] >= since]
if not recent:
    print("  (해당 기간 PR 없음)")
    sys.exit(0)


def week_commits(branch):
    """기간 내 머지 아닌 커밋 날짜 목록. 리모트 브랜치 우선, 없으면 로컬."""
    if not repo or not branch:
        return None
    for ref in (f"origin/{branch}", branch):
        r = subprocess.run(
            ["git", "-C", repo, "log", ref, "--no-merges", f"--since={since}",
             "--format=%ad", "--date=short"],
            capture_output=True, text=True)
        if r.returncode == 0:
            return [d for d in r.stdout.split() if d]
    return None


for p in sorted(recent, key=lambda x: x.get("updatedAt", ""), reverse=True):
    flags = p.get("state", "")
    if p.get("isDraft"):
        flags += "/DRAFT"
    merged = (p.get("mergedAt") or "")[:10]
    if merged:
        flags += f" merged {merged}"
    body = re.sub(r"\s+", " ", p.get("body") or "").strip()[:400]
    print(f"- #{p['number']} [{flags}] {p['title']}")
    print(f"  branch: {p.get('headRefName', '?')}")
    print(f"  url: {p.get('url', '')}")
    print(f"  created: {(p.get('createdAt') or '')[:10]}  updated: {(p.get('updatedAt') or '')[:10]}")
    dates = week_commits(p.get("headRefName"))
    if dates is not None:
        if dates:
            print(f"  이번 주 커밋(머지 제외): {len(dates)}건, 마지막 {max(dates)}")
        elif merged and merged >= since:
            print("  이번 주 커밋(머지 제외): 0건 — 이번 주에 머지됨")
        else:
            print("  이번 주 커밋(머지 제외): 0건 — !! 이번 주 실제 작업 없음. 금주업무에 넣지 말고 차주(리뷰 대기)로만")
    if body:
        print(f"  body: {body}")
