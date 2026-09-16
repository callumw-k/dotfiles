function gwclean
    for branch in (git branch --merged main --format='%(refname:short)' | string match -v main)
        set -l path (git worktree list | string match -r "^(\S+).*\[$branch\]" | tail -1)
        test -n "$path" && git worktree remove $path && git branch -d $branch
    end
    git worktree prune
end
