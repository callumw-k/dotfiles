function claude --wraps claude
    set -l profile ~/.claude/profiles/$CLAUDE_PROFILE
    set -l flags
    if set -q CLAUDE_PROFILE
        test -f $profile.json; and set -a flags --settings $profile.json
        # why: --mcp-config is variadic, the = form stops it swallowing a subcommand
        test -f $profile.mcp.json; and set -a flags --mcp-config=$profile.mcp.json
    end
    command claude $flags $argv
end
