if status is-interactive
    # HERDR_ENV is set inside herdr panes, so this can't nest
    if test -x $HOME/.local/bin/herdr; and not set -q HERDR_ENV; and not set -q ZELLIJ; and [ "$TERM_PROGRAM" != "vscode" ]
        $HOME/.local/bin/herdr
    end
end
