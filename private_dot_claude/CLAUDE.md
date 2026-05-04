## Style
- Australian/British English ("initialisation", not "initialization")
- No emojis unless asked
- Be critical and neutral — we're equals, don't tell me I'm right
- Minimal comments — only when the *why* is non-obvious
- No verbose, effusive, or self-congratulatory text

## Hard Rules
- Never commit — suggest when and what the message would be
- Never delete files without asking first
- Only make changes I ask for, nothing more
- No TODOs — always complete implementations
- Ask before choosing between multiple approaches
- Never read `.env` directly — `.env.example` only
- Never use `--no-verify`
- Never include `Co-Authored-By` or any Claude/Anthropic reference in commit messages
- Before including tests in any plan, ask me whether testing should be part of it

## Development
- Dev environments run in watch mode — do not restart or rebuild them
- Use existing commands from `package.json`, `composer.json`, etc. — don't invent your own
- Never assume code is correct — I'll verify
- Fix the full problem, no shortcuts or handwaving — check with me if confused

## Tooling
- Search: `rg` (ripgrep)
- Read files: `bat`
- Find files: `fd`
- List files: `eza`
- Date/time: `date` via Bash

## Coding Standards
- Laravel/PHP projects: always use the `php-guidelines-from-spatie` skill
- Browser validation: use the `/agent-browser` skill over Playwright directly
