#!/usr/bin/env python3
"""PreToolUse hook: deny Write/Edit whose added lines are comment-heavy."""
import json
import re
import sys

MAX_RATIO = 0.12
MIN_COMMENTS = 2

CODE_EXT = re.compile(
    r"\.(py|js|jsx|ts|tsx|mjs|cjs|php|go|rs|java|kt|swift|rb|c|h|cpp|hpp|cs|sh|bash|fish|zsh|sql|css|scss|vue|svelte|tf|hcl|yaml|yml|toml)$"
)
COMMENT = re.compile(r"^\s*(//|#|/\*|\*(?!/)|--\s|<!--)")
# escape hatches: directives, deliberate markers, doc contracts
KEEP = re.compile(
    r"(ponytail:|eslint|prettier|ts-(ignore|expect-error|nocheck)|@type|jsdoc|noqa|type:\s*ignore|pylint|pyright|mypy|ruff|phpcs|phpstan|psalm|swiftlint|golangci|nolint|shellcheck|biome-ignore|istanbul|c8 |v8 ignore|coverage:|SPDX|Copyright|codegen|DO NOT EDIT|region |#!|#\s*\w+:\s*$)",
    re.I,
)


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

    offenders = [l for l in lines if COMMENT.match(l) and not KEEP.search(l)]
    n = len(offenders)
    if n < MIN_COMMENTS or n / len(lines) <= MAX_RATIO:
        sys.exit(0)

    sample = "\n".join(o.strip()[:90] for o in offenders[:5])
    print(
        f"BLOCKED: {n} comment lines in {len(lines)} lines of code ({n / len(lines):.0%}, cap {MAX_RATIO:.0%}).\n"
        f"Delete every comment that restates what the code does. Keep only non-obvious WHY: "
        f"trade-offs, workarounds, gotchas. Mark deliberate simplifications with 'ponytail:'.\n"
        f"Offending lines:\n{sample}",
        file=sys.stderr,
    )
    sys.exit(2)


main()
