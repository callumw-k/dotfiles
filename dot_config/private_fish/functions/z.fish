function z
    if test (count $argv) -eq 0
        zi
    else
        __zoxide_z $argv
    end
end
