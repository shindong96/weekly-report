#!/usr/bin/env python3
"""config.json의 repos를 탭 구분 줄로 출력한다: path\tname\tdefault_category"""
import json
import os
import sys

with open(sys.argv[1], encoding="utf-8") as f:
    cfg = json.load(f)

for r in cfg.get("repos", []):
    path = os.path.expanduser(r.get("path", ""))
    name = r.get("name") or os.path.basename(path.rstrip("/"))
    cat = r.get("default_category", "미분류")
    print(f"{path}\t{name}\t{cat}")
