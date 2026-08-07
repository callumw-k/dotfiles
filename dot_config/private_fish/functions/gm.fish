function gm
    set signed_repos \
        "git@github.com:caradvice/drive-grille.git"

    set current_remote (git remote get-url origin 2>/dev/null)

    echo 'Is this even working'

    if contains -- $current_remote $signed_repos
        echo 'Signing commit'
        git commit -S -m $argv
    else
        echo 'Not signing commit'
        git commit -m $argv
    end
end
