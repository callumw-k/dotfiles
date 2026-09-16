# Worktree helpers

Temporary notes for the `gw*` fish helpers. Delete once they're muscle memory.

A worktree is a second checkout of the same repo in its own directory, on its own branch. You keep main clean in one directory and work on features in others, no stashing, no switching.

## Where worktrees go

`gwn` puts them inside the repo: `.claude/worktrees/<branch>` if that directory already exists (Claude Code's convention), otherwise `.worktrees/<branch>`. It adds the directory to `.git/info/exclude` so it never shows as untracked. Slashes in branch names become dashes in the directory name.

## Commands

| Command | Does |
|---|---|
| `gwn <branch>` | Fetch, then add a worktree for `<branch>` and cd into it. Uses the local branch if it exists, tracks `origin/<branch>` if only the remote has it, otherwise creates it off `main`. |
| `gwz` | fzf-pick a worktree and cd into it. |
| `gwm` | cd back to the main worktree. |
| `gwrm` | fzf-pick a worktree, remove it, delete its branch if merged. |
| `gwclean` | Remove every worktree whose branch is merged into `main`, delete those branches, prune. |
| `gwl` | `git worktree list` |
| `gwp` | `git worktree prune` |

## Typical flow

```fish
gwn feature/login      # new branch off main, in its own directory
# ... commit, push, open PR ...
gwm                    # back to main
git pull
gwclean                # once the PR merges, the worktree and branch go away
```

Picking up a colleague's branch: `gwn their-branch`. The fetch runs first, so a branch that only exists on origin gets a tracking worktree.

## Gotchas

- A branch can only be checked out in one worktree at a time. `gwn` fails if it's already checked out elsewhere; `gwz` to it instead.
- `gwrm` and `gwclean` use `git branch -d`, so an unmerged branch survives removal. Delete it by hand with `git branch -D` if you meant it.
- `gwn` assumes the default branch is `main`. On a `master` repo, creating a new branch fails; existing branches still work.
- Each worktree has its own untracked files, so `node_modules`, `vendor`, `.env` need installing per worktree.
