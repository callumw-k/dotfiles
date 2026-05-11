if status is-interactive

    if [ "$TERM" = "xterm-ghostty" ] && [ "$TERM_PROGRAM" != "vscode" ]
        eval (zellij setup --generate-auto-start fish | string collect)
    end

    set -gx EDITOR "nvim"
    set -gx VISUAL "nvim"

    alias ezsh="cd ~/.local/share chezmoi && nvim && chezmoi apply"
    alias szsh="source ~/.zshrc"
    alias efish="nvim ~/.config/fish/config.fish"
    alias sfish="source ~/.config/fish/config.fish"
    alias vim="nvim"
    alias vi="nvim"
    alias sv="sudo -E nvim"
    alias so="sudo"
    alias svim="sudo -E nvim"
    alias snvim="sudo -E nvim"
    alias ce="cd ~/.local/share/chezmoi && nvim && chezmoi apply && cd - && sfish"
    alias cadd="chezmoi add"
    alias ca="chezmoi apply"
    alias cdc="chezmoi cd"
    alias dbc="distrobox create --clone base-arch-container --name"
    alias db="distrobox"
    alias dbe="distrobox enter"
    alias lg="lazygit"
    alias pnpx="pnpm dlx"
    alias fvf="fvm flutter"
    alias dvm="fvm dart"
    alias update-vms="sv /etc/libvirt/hooks/qemu"
    alias ga="git add ."
    alias gc="git checkout"
    alias gcs="git stash"
    alias gcsp="git stash pop"
    alias zj="zellij"
    alias gcb="git checkout -b"
    alias srmf="sudo rm -r"
    alias rmf="rm -r"
    alias syu="sudo pacman -Syu"
    alias sy="sudo pacman -S"
    alias artisan="php artisan"
    alias sail="./vendor/bin/sail"
    alias sart="./vendor/bin/sail artisan"
    alias part="./vendor/bin/sail php artisan"
    alias python="python3"
    alias set-user-owner='sudo chown -R $USER'
    alias set-user-perms='sudo chmod -R 775'
    alias dcupd='docker compose up --remove-orphans -d'
    alias dcdn='docker compose down'
    alias dc='docker'
    alias dci='docker exec -i'
    alias dcpull='docker compose pull'
    alias f="yazi"
    alias yays="yay -S"
    alias ls='eza -l -a'
    alias vf='vim $(fzf)'
    alias zu='z ..'
    alias zp='z -'


    set fish_greeting

    switch (uname)
      case Darwin

          fish_add_path /opt/homebrew/bin
          

          if test -d $HOME/.dotnet
            set -x DOTNET_ROOT /opt/homebrew/opt/dotnet/libexec
            fish_add_path $DOTNET_ROOT
          end

          set MYSQL_HOME "/opt/homebrew/opt/mysql-client/bin"
          if test -d $MYSQL_HOME
            fish_add_path $MYSQL_HOME
          end
          
          set JAVA_HOME "/opt/homebrew/opt/openjdk@21/bin"
          if test -d $JAVA_HOME
            fish_add_path $JAVA_HOME
          end


          set ORBSTACK_BIN "$HOME/.orbstack/bin"
          if test -d $ORBSTACK_BIN
            set -x ORBSTACK_BIN $ORBSTACK_BIN 
            fish_add_path $ORBSTACK_BIN
          end

          set RUSTUP_ROOT "/opt/homebrew/opt/rustup/bin"
          if test -d $RUSTUP_ROOT
            fish_add_path $RUSTUP_ROOT
          end


          if test -d $HOME/.rbenv/shims
            fish_add_path $HOME/.rbenv/shims
          end


      case Linux

          if test -f $HOME/.local/bin/claude
              fish_add_path $HOME/.local/bin
          end

          set -x QT_LOGGING_RULES "kwin_*.debug=true"
          set --erase _asdf_shims

          if test -z $ASDF_DATA_DIR
            set _asdf_shims "$HOME/.asdf/shims"
          else
            set _asdf_shims "$ASDF_DATA_DIR/shims"
          end

          if not contains $_asdf_shims $PATH
            set -gx --prepend PATH $_asdf_shims
          end


      case '*'
        echo "Unknown term"
    end

    if test -d $HOME/.config/android-sdk
      set -x ANDROID_HOME $HOME/.config/android-sdk
      fish_add_path $ANDROID_HOME
    end


    if test -d $HOME/.spin/bin
      fish_add_path $HOME/.spin/bin
    end

    if test -d $HOME/.composer/vendor/bin
      fish_add_path $HOME/.composer/vendor/bin
    end

    if test -d $HOME/.volta/bin
      fish_add_path $HOME/.volta/bin
    end


    ## .NET Tools ##
    if test -d $HOME/.dotnet/tools
      fish_add_path $HOME/.dotnet/tools
    end

    ## Flutter ##
    if test -d $HOME/fvm/default/bin
      fish_add_path $HOME/fvm/default/bin
    end

    set DART_PUB_PACKAGES "$HOME/.pub-cache/bin"
    if test -d $DART_PUB_PACKAGES
      fish_add_path $DART_PUB_PACKAGES
    end

    ## PyEnv ##
    if test -d $HOME/.pyenv
      set -x PYENV_ROOT $HOME/.pyenv
      fish_add_path $PYENV_ROOT/bin
      pyenv init - | source
    end

    if test -d $HOME/.phpenv
      fish_add_path $HOME/.phpenv/bin
      eval "$(phpenv init -)"
    end



    fzf --fish | source
    starship init fish | source
    zoxide init fish   | source

end



function z
    if test (count $argv) -eq 0
        zi
    else
        __zoxide_z $argv
    end
end

function dcib 
  if test (count $argv) -eq 0
    echo 'No container specified'
  else 
    docker exec -it $argv bash
  end
end

function dcis 
  if test (count $argv) -eq 0
    echo 'No container specified'
  else 
    docker exec -it $argv sh
  end
end

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


# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init2.fish 2>/dev/null || :
