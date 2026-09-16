function gwrm
    set -l line (git worktree list | tail -n +2 | fzf)
    test -z "$line" && return 1
    set -l path (echo $line | awk '{print $1}')
    set -l branch (echo $line | string match -r '\[(.+)\]' | tail -1)
    git worktree remove $path && git branch -d $branch
end
