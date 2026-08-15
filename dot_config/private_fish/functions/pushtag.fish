function pushtag
    git tag $argv[1] && git push origin $argv[1]
end
