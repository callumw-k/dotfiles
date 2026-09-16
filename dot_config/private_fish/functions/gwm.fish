function gwm
    cd (git worktree list | head -1 | awk '{print $1}')
end
