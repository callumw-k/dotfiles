function claude --wraps claude
    set -l profile ~/.claude/profiles/$CLAUDE_PROFILE.json
    if set -q CLAUDE_PROFILE; and test -f $profile
        command claude --settings $profile $argv
    else
        command claude $argv
    end
end
