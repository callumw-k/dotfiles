switch (uname)
  case Darwin

      fish_add_path /opt/homebrew/bin


      if test -d $HOME/.dotnet
        set -x DOTNET_ROOT /opt/homebrew/opt/dotnet/libexec
        fish_add_path $DOTNET_ROOT
      end

      if test -d $HOME/.orbstack/bin
        set -x ORBSTACK_BIN $HOME/.orbstack/bin
        fish_add_path $ORBSTACK_BIN
      end

      for dir in \
          /opt/homebrew/opt/mysql-client/bin \
          /opt/homebrew/opt/openjdk@21/bin \
          /opt/homebrew/opt/rustup/bin \
          $HOME/.rbenv/shims
        test -d $dir; and fish_add_path $dir
      end


  case Linux

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

      if test -f $HOME/.pub-cache/bin
          fish_add_path $HOME/.pub-cache/bin
      end


  case '*'
    echo "Unknown term"
end

if test -d $HOME/.config/android-sdk
  set -x ANDROID_HOME $HOME/.config/android-sdk
  fish_add_path $ANDROID_HOME
end

for dir in \
    $HOME/.local/bin \
    $HOME/.spin/bin \
    $HOME/.composer/vendor/bin \
    $HOME/.volta/bin \
    $HOME/.dotnet/tools \
    $HOME/fvm/default/bin \
    $HOME/.pub-cache/bin
  test -d $dir; and fish_add_path $dir
end

if test -d $HOME/.pyenv
  set -x PYENV_ROOT $HOME/.pyenv
  fish_add_path $PYENV_ROOT/bin
  pyenv init - | source
end

if test -d $HOME/.phpenv
  fish_add_path $HOME/.phpenv/bin
  eval "$(phpenv init -)"
end
