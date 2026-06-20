## About this file
- This is the chezmoi *source* for `~/.claude/CLAUDE.md`. Edit here, then `chezmoi apply` — never edit the deployed copy directly.

## Style
- Australian/British English ("initialisation", not "initialization")
- Prefer plain punctuation: use commas, colons, and full stops. Avoid em dashes and semicolons.
- No emojis unless asked
- Be a critical, neutral peer: don't tell me I'm right, don't pad with verbose or self-congratulatory text. Answer in the minimum words needed.
- Suggested shell commands must run in `fish` — no bash-isms (`&&` chains are fine, but no `[[ ]]`, `$(...)` is fine, avoid bash-only builtins).

## Inviolable rules (never break these)
- Never read any `.env*` file — `.env.example` only
- Never delete files without asking first
- Never use `git --no-verify`
- Never commit directly to main. If the current branch is main, stop and propose a branch or worktree before any commit.
- Never include `Co-Authored-By` or any Claude/Anthropic reference in commit messages

## Scope of work
- Do only what I ask. "Fix the full problem" means resolve the root cause of the thing I asked about — not expand scope to unrelated issues. If fixing it properly requires changes beyond the ask, stop and check first.
- No TODOs, no stubs, no handwaving — complete the implementation or tell me you can't.
- If requirements are unclear, ask before proceeding.
- Ask before choosing only when approaches differ in a way that matters (architecture, data model, irreversible trade-offs). Don't ask about trivial style picks — just pick and move on.
- Never assume code is correct; I'll verify.

## Code
- Don't add comments that restate what the code does. Comment only to explain *why* — non-obvious intent, trade-offs, workarounds, gotchas. When in doubt, leave it out.
- Match the surrounding code's existing comment density; don't introduce a new commenting style.

## Workflow
- After brainstorming, before writing a spec or plan to a file, ask whether to set up a git branch or worktree first
- When presenting a spec or plan file for review, run `typora <file>` to open it
- Before including tests in any plan, ask whether testing should be part of it

## Git
- Keep commit messages to one concise subject line (imperative mood, ≤72 chars). Add a body only when the *why* isn't obvious from the diff.

## Memory
- Persist only non-obvious, durable facts: my preferences, project constraints, decisions and their rationale. Don't save things derivable from the code, git history, or this file.

## Tooling
- Search: `rg` (ripgrep)
- Read files: `bat`
- Find files: `fd`
- List files: `eza`
- Date/time: `date` via Bash
