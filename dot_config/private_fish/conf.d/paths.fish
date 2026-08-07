switch (uname)
  case Darwin

      fish_add_path /opt/homebrew/bin

      source "$HOME/.cargo/env.fish"


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

if test -f $HOME/.local/bin/claude
    fish_add_path $HOME/.local/bin
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
