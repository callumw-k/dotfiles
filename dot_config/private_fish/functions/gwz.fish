function gwz
    set -l path (git worktree list | fzf | awk '{print $1}')
    test -n "$path" && cd $path
end
