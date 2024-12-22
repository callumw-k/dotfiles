if status is-interactive
    # Commands to run in interactive sessions can go here
    alias ezsh="chezmoi edit --apply ~/.zshrc && source ~/.zshrc"
    alias szsh="source ~/.zshrc"
    alias efish="nvim ~/.config/fish/config.fish"
    alias sfish="source ~/.config/fish/config.fish"
    alias vim="nvim"
    alias vi="nvim"
    alias sv="sudo -E nvim"
    alias svim="sudo -E nvim"
    alias snvim="sudo -E nvim"
    alias ce="chezmoi edit --apply"
    alias cadd="chezmoi add"
    alias ca="chezmoi apply"
    alias dbc="distrobox create --clone base-arch-container --name"
    alias db="distrobox"
    alias dbe="distrobox enter"
    alias pnpx="pnpm dlx"
    alias fvf="fvm flutter"
    alias dvm="fvm dart"
    alias update-vms="sv /etc/libvirt/hooks/qemu"
    alias ga="git add ."
    alias gm="git commit -m"
    alias gc="git checkout"
    alias gcb="git checkout -b"
    alias spu="sudo pacman -Syu"
    alias sp="sudo pacman -S"
    alias artisan="php artisan"
    alias sail="./vendor/bin/sail"
    alias sart="./vendor/bin/sail artisan"
    alias part="./vendor/bin/sail php artisan"
    alias python="python3"
    alias set-user-owner='sudo chown -R $USER'
    alias set-user-perms='sudo chmod -R 775'
    alias dcupd='docker compose up --remove-orphans -d'
    alias dcpull='docker compose pull'

    set fish_greeting

    switch (uname)
      case Darwin
          if test -d $HOME/.dotnet
            set -x DOTNET_ROOT $HOME/.dotnet
            fish_add_path $DOTNET_ROOT
          end


          set -x ORBSTACK_BIN $HOME/.orbstack/bin

          if test -d $ORBSTACK_BIN
            fish_add_path $ORBSTACK_BIN
          end

          fish_add_path /opt/homebrew/bin

          if test -d $HOME/.rbenv/shims
            fish_add_path $HOME/.rbenv/shims
          end

      case Linux
        echo "Init linx"
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



    starship init fish | source
    zoxide init fish   | source
    #    rbenv init - --no-rehash fish | source
end


