if status is-interactive
    set -gx EDITOR "nvim"
    set -gx VISUAL "nvim"

    # Commands to run in interactive sessions can go here
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
    alias gm="git commit -m"
    alias gc="git checkout"
    alias gcb="git checkout -b"
    alias srmf="sudo rm -r"
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
    alias dcpull='docker compose pull'
    alias f="yazi"
    alias yays="yay -S"


    set fish_greeting

    switch (uname)
      case Darwin
          fish_add_path /opt/homebrew/bin

          if test -d $HOME/.dotnet
            set -x DOTNET_ROOT /opt/homebrew/opt/dotnet/libexec
            fish_add_path $DOTNET_ROOT
          end


          set -x ORBSTACK_BIN $HOME/.orbstack/bin

          if test -d $ORBSTACK_BIN
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
          alias ls='exa -l -a'

          if test -z $ASDF_DATA_DIR
            set _asdf_shims "$HOME/.asdf/shims"
          else
            set _asdf_shims "$ASDF_DATA_DIR/shims"
          end

          if not contains $_asdf_shims $PATH
            set -gx --prepend PATH $_asdf_shims
          end
          set --erase _asdf_shims

      case '*'
        echo "Unknown term"
    end

    if test -d $HOME/.config/android-sdk
      set -x ANDROID_HOME $HOME/.config/android-sdk
      fish_add_path $ANDROID_HOME
    else 
      echo "android-sdk not installed"
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

    ## PyEnv ##
    if test -d $HOME/.pyenv
      set -x PYENV_ROOT $HOME/.pyenv
      fish_add_path $PYENV_ROOT/bin
      pyenv init - | source
    else
      echo "pyenv not installed"
    end


    # tv init fish       | source
    starship init fish | source
    zoxide init fish   | source
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

