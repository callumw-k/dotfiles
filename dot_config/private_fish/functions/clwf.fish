function clwf
    set -l branch (git branch --format='%(refname:short)' | fzf)
    if test -z "$branch"
        return 1
    end
    # CLAUDE_CONFIG_DIR=/Users/Callum.Kane/.fine-dan-you-win/.claude claude --worktree $branch
    claude --worktree $branch
end
