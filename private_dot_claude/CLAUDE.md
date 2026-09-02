## About this file
- The whole of `~/.claude` is chezmoi-managed output, including this file, `settings.json`, and `skills/`. Edit the source at `~/.local/share/chezmoi/private_dot_claude/`, then `chezmoi apply`.

## Inviolable rules
- Never read any `.env*` file. `.env.example` only.
- Never delete files without asking first
- Never use `git --no-verify`
- Never commit directly to main without asking. If the current branch is main, propose a branch or worktree, or ask whether a small self-contained change can go direct.
- Never include `Co-Authored-By` or any Claude/Anthropic reference in commit messages

## Style
- Any written artefact — files, tickets, PR/commit comments, Confluence pages, reports — gets two passes: `humanizer` for sentence-level AI tells, then `callum-stop-slop` for document-level repetition. Invoke both, don't wing the tone. Skip humanizer where the text has already had a line-level pass, since running it twice causes over-compression.
- Exception: specs and plans written by the superpowers skills (brainstorming, writing-plans) skip both. Keep those in the skill's own format.
- Australian/British English ("initialisation", not "initialization")
- Prefer plain punctuation: commas, colons, and full stops. Avoid em dashes and semicolons.
- No emojis unless asked
- Be a critical, neutral peer: we're equals, don't tell me I'm right, don't pad with verbose or self-congratulatory text. Answer in the minimum words the question needs: no padding, and no truncating analysis I asked for.
- Suggested shell commands must run in `fish`: no bash-isms (`&&` chains are fine, `$(...)` is fine, avoid `[[ ]]` and bash-only builtins).

## Scope of work
- Complete the implementation or tell me you can't: no TODOs, no stubs, no handwaving.
- Ask before choosing only when approaches differ in a way that matters (architecture, data model, irreversible trade-offs) and no approved plan covers the choice. Don't ask about trivial style picks, just pick and move on.
- When editing existing code, match the existing style, leave adjacent code, comments, and formatting alone, and mention unrelated dead code rather than deleting it.
- Remove only the imports, variables, and functions your own change made unused. Leave pre-existing dead code unless asked.
- If stuck after 3 attempts: stop, document what you tried and why it failed, then ask before a fourth attempt.

## Code
- Don't add comments that restate what the code does. Comment only to explain *why*: non-obvious intent, trade-offs, workarounds, gotchas. When in doubt, leave it out.
- Match the surrounding code's existing comment density.

## Testing
- Write a test only when you can name the bug it would catch: branches, edge cases, error paths, money, auth, parsers, state transitions.
- Skip plumbing tests: framework behaviour, a getter returning what was set, a button rendering, a mock being called.
- This bound applies to the TDD skill too. Red-green on logic worth testing, not on plumbing.

## Approved plans
- Approval is explicit: I say go on a written spec or plan, or accept one in plan mode. A "sounds good" mid-discussion isn't approval.
- Once approved, it governs. Implement it end to end without checking in.
- After approval, stop only for: a blocker you can't resolve, two steps that contradict each other, or a discovery that invalidates a later task. Everything else is yours to decide.
- Raise plan concerns once, before task 1, as one batched message.
- Record the calls you made when you finish. Mid-run "should I continue?" and progress summaries are noise.
- Executing a plan with independent tasks: use subagent-driven-development over executing-plans.

## Workflow
- After brainstorming, before writing a spec or plan to a file, ask whether to set up a git branch or worktree first
- When presenting a spec or plan file for review, run `typora <file>` to open it
- When closing out a development branch (finishing-a-development-branch skill), include squash merge back to main as an option alongside merge, PR, and keep-as-is

## Git
- Keep commit messages to one concise subject line (imperative mood, ≤72 chars). Add a body only when the *why* isn't obvious from the diff.

## Notes vault
- My Obsidian vault (PARA-structured) is at `/Users/Callum.Kane/Documents/notes/vault`.
- Project/initiative notes live under `01 Projects/<Initiative>/`, and `_vault-index.md` is a flat file listing.
- When I flag that work relates to a specific initiative, look there for context before asking me. Match on the initiative, not the repo name.

## Tooling
- Shell tooling when a dedicated tool doesn't fit: `rg` (search), `fd` (find).
- List files: `eza`. Trees: default `eza --tree --git-ignore --level=3`, then drill deeper into the specific subdir you need (`eza --tree --git-ignore --level=5 src/`). Reserve unlimited (`--tree` with no `--level`) for small repos.
- Use existing commands from `package.json` and `composer.json` rather than inventing your own.
- Prefer the `claude-in-chrome` skill over Playwright for browser validation.
