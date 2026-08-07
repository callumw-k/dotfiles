function init-git
    if test (count $argv) -ne 1
        echo "Usage: init-git <repository_name>"
        return 1
    end
    set repo_name $argv[1]

    if test -d .git
        echo "Git repository already exists. Skipping git init."
    else
        git init
        echo "Initialized new git repository"
    end

    set existing_origin (git remote get-url origin 2>/dev/null)
    if test -n "$existing_origin"
        echo "Remote 'origin' already exists. Skipping branch rename and push."
        return 0
    end

    git branch -m main
    git add -A
    git commit -m "init"
    git remote add origin git@git.callumserver.com:callumwk/$repo_name.git
    git push -u origin main
end
