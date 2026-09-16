function gwn --argument-names branch
    if test -z "$branch"
        echo "usage: gwn <branch>" >&2
        return 1
    end
    set -l root (git rev-parse --show-toplevel) || return 1
    set -l dir .worktrees
    test -d $root/.claude/worktrees && set dir .claude/worktrees
    grep -qx "$dir/" $root/.git/info/exclude 2>/dev/null || echo "$dir/" >> $root/.git/info/exclude
    set -l path $root/$dir/(string replace -a / - $branch)
    git fetch --quiet origin 2>/dev/null
    if git show-ref -q --verify refs/heads/$branch || git show-ref -q --verify refs/remotes/origin/$branch
        git worktree add $path $branch && cd $path
    else
        git worktree add -b $branch $path main && cd $path
    end
end
