if status is-interactive
    set -gx EDITOR "nvim"
    set -gx VISUAL "nvim"

    # Commands to run in interactive sessions can go here
    alias ezsh="chezmoi edit --apply ~/.zshrc && source ~/.zshrc"
    alias szsh="source ~/.zshrc"
    alias efish="nvim ~/.config/fish/config.fish"
    alias sfish="source ~/.config/fish/config.fish"
    alias vim="nvim"
    alias vi="nvim"
    alias sv="sudo -E nvim"
    alias so="sudo"
    alias svim="sudo -E nvim"
    alias snvim="sudo -E nvim"
    alias ce="chezmoi edit --apply"
    alias cadd="chezmoi add"
    alias ca="chezmoi apply"
    alias ccd="chezmoi cd"
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
    alias dcpull='docker compose pull'
    alias ls='ls -l -a'
    alias f="yazi"


    set fish_greeting

    switch (uname)
      case Darwin
          fish_add_path /opt/homebrew/bin

          if test -d $HOME/.dotnet
            set -x DOTNET_ROOT $HOME/.dotnet
            fish_add_path $DOTNET_ROOT
          end


          set -x ORBSTACK_BIN $HOME/.orbstack/bin

          if test -d $ORBSTACK_BIN
            fish_add_path $ORBSTACK_BIN
          end


          if test -d $HOME/.rbenv/shims
            fish_add_path $HOME/.rbenv/shims
          end

      case Linux
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
end


function init-git
  if test (count $argv) -ne 1
      echo "Usage: init-git <repository_name>"
      return 1
  end


  set repo_name $argv[1]

  set skip_init false

  if test -d .git
      echo "Git repository already exists. Skipping git init."
      set skip_init true
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

