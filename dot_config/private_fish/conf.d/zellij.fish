if status is-interactive; and set -q ZELLIJ
    function zellij_rename_tab_pwd --on-event fish_prompt
        set -l tty (tty | string replace /dev/ '')
        if pgrep -t $tty -x herdr >/dev/null
            zellij action rename-tab herdr
        else
            zellij action rename-tab (basename (pwd))
        end
    end
end
