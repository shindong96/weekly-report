#!/usr/bin/env python3
"""보고서 마크다운(불릿·볼드·인라인코드·링크만 쓰는 부분집합)을 HTML로 바꾼다.
usage: _md2html.py report.md  → stdout 에 HTML
외부 모듈 없이 동작한다. pandoc 이 없는 환경을 위한 최소 변환기다.
하위 불릿은 <li> 안에 <ul> 로 중첩해, Teams 같은 보수적인 편집기에서도 들여쓰기가 유지된다.\n일반 줄은 <p> 가 아니라 <div> 로 내보낸다. Teams 는 <p> 사이 줄바꿈을 공백으로 합쳐 헤더와 카테고리가 한 줄이 된다."""
import html
import re
import sys

src = open(sys.argv[1], encoding="utf-8").read().splitlines()


def inline(t):
    t = html.escape(t, quote=False)
    t = re.sub(r"\[([^\]]+)\]\((https?://[^)]+)\)", r'<a href="\2">\1</a>', t)
    t = re.sub(r"\*\*(.+?)\*\*", r"<b>\1</b>", t)
    t = re.sub(r"`([^`]+)`", r"<code>\1</code>", t)
    return t


class Item:
    def __init__(self, text):
        self.text, self.children = text, []


def render(items):
    if not items:
        return ""
    parts = ["<ul>"]
    for it in items:
        parts.append(f"<li>{it.text}{render(it.children)}</li>")
    parts.append("</ul>")
    return "".join(parts)


out, stack = [], []  # stack: 현재 열린 항목들 (깊이별)


def flush():
    global stack
    if stack:
        out.append(render(stack[0]))
        stack = []


for line in src:
    m = re.match(r"^( *)[*-] (.*)$", line)
    if m:
        level = len(m.group(1)) // 3  # 0 = 1단계
        item = Item(inline(m.group(2)))
        if level == 0:
            if not stack:
                stack = [[item]]
            else:
                stack[0].append(item)
                del stack[1:]
        else:
            while len(stack) < level + 1:
                stack.append(stack[-1][-1].children)
            del stack[level + 1:]
            stack[level].append(item)
    elif line.strip() == "":
        flush()
        # Teams 입력창은 <p> 사이 줄바꿈을 공백으로 합친다. 편집기가 빈 줄을 표현하는 방식 그대로 <div><br></div> 를 쓴다.
        if out and out[-1] != "<div><br></div>":
            out.append("<div><br></div>")
    else:
        flush()
        out.append(f"<div>{inline(line.strip())}</div>")
flush()
print("".join(out))
