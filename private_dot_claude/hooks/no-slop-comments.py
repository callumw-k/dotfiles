#!/usr/bin/env python3
"""PreToolUse hook: deny Write/Edit that adds unlabelled comments to code."""
import json
import re
import sys

CODE_EXT = re.compile(
    r"\.(py|js|jsx|ts|tsx|mjs|cjs|php|go|rs|java|kt|swift|rb|c|h|cpp|hpp|cs|sh|bash|fish|zsh|sql|css|scss|vue|svelte|tf|hcl)$"
)
COMMENT = re.compile(r"^\s*(//|#|/\*|\*(?!/)|--\s|<!--)")
DOC_OPEN = re.compile(r"^\s*(/\*\*|///)")
DOC_CLOSE = re.compile(r"\*/")
# escape hatches: directives, deliberate markers, doc contracts
KEEP = re.compile(
    r"(why:|ponytail:|eslint|prettier|ts-(ignore|expect-error|nocheck)|@type|jsdoc|noqa|type:\s*ignore|pylint|pyright|mypy|ruff|phpcs|phpstan|psalm|swiftlint|golangci|nolint|shellcheck|biome-ignore|istanbul|c8 |v8 ignore|coverage:|SPDX|Copyright|codegen|DO NOT EDIT|region |#!|#\s*\w+:\s*$)",
    re.I,
)


def offending(lines):
    # why: /** */ and /// blocks are API contracts tooling reads, not prose slop
    out, in_doc = [], False
    for l in lines:
        if in_doc:
            in_doc = not DOC_CLOSE.search(l)
            continue
        if DOC_OPEN.match(l):
            in_doc = not DOC_CLOSE.search(l)
            continue
        if COMMENT.match(l) and not KEEP.search(l):
            out.append(l)
    return out


def added_lines(payload):
    tool = payload.get("tool_name", "")
    inp = payload.get("tool_input", {}) or {}
    if tool == "Write":
        return inp.get("content", ""), inp.get("file_path", "")
    if tool == "Edit":
        return inp.get("new_string", ""), inp.get("file_path", "")
    return "", ""


def main():
    try:
        payload = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    content, path = added_lines(payload)
    if not content or not CODE_EXT.search(path or ""):
        sys.exit(0)

    lines = [l for l in content.splitlines() if l.strip()]
    if not lines:
        sys.exit(0)

    offenders = offending(lines)
    if not offenders:
        sys.exit(0)

    sample = "\n".join(o.strip()[:90] for o in offenders[:5])
    print(
        f"BLOCKED: {len(offenders)} unlabelled comment line(s).\n"
        f"Comments in code are off by default. Delete anything that restates what the code does.\n"
        f"If a comment earns its place, prefix it 'why:' (e.g. '// why: upstream API 500s on empty body') "
        f"or 'ponytail:' for a deliberate simplification. Nothing else gets through.\n"
        f"Offending lines:\n{sample}",
        file=sys.stderr,
    )
    sys.exit(2)


main()
