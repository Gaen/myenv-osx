#!/bin/bash

# This is a script for bootstrapping the environment after fresh OS installation.
# It tries to be idempotent, but there are still some redundant effects.

# This flag will be used to track if we have installed oh-my-zsh in current run
did_install_omz=false

log() {
  echo "[myenv-init] $@"
}

# Install homebrew if not present
#
# This will rewrite .zprofile!
# Original .zprofile will be saved as .zprofile.pre-myenv
init_homebrew() {
  
  # Skip if already present
  if [ $(which brew) ]; then
    log 'Present: homebrew'
    return
  fi
  
  log 'Installing: homebrew'

  # Official install command from https://brew.sh/
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # We are going to rewrite .zprofile, so backup it first
  if [ -s "$HOME/.zprofile" && ! -e "$HOME/.zprofile.pre-myenv" ]; then
    mv "$HOME/.zprofile" "$HOME/.zprofile.pre-myenv"
    log "Existing .zprofile saved as .zprofile.pre-myenv"
  fi
  
  # Rewrite .zprofile with homebrew activation
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' > ~/.zprofile

  # Activate homebrew in current session
  eval "$(/opt/homebrew/bin/brew shellenv)"

  # Update packages
  brew update

  log 'Installed: homebrew'
}

# Install some basic tools which require no configuration
init_basictools() {
      
  if [ $(which tree) ]; then
    log 'Present: tree'
  else
    log 'Installing: tree'
    brew install tree
    log 'Installed: tree'
  fi 

  if [ $(which watch) ]; then
    log 'Present: watch'
  else
    log 'Installing: watch'
    brew install watch
    log 'Installed: watch'
  fi 

  if [ $(which jq) ]; then
    log 'Present: jq'
  else
    log 'Installing: jq'
    brew install jq
    log 'Installed: jq'
  fi 

  if [ $(which htop) ]; then
    log 'Present: htop'
  else
    log 'Installing: htop'
    brew install htop
    log 'Installed: htop'
  fi 

  if [ $(which mc) ]; then
    log 'Present: midnight-commander'
  else
    log 'Installing: midnight-commander'
    brew install midnight-commander
    log 'Installed: midnight-commander'
  fi 
}

# Install gnu stow which drives further config management
init_stow() {

  # Install if not present
  if [ $(which stow) ]; then
    log 'Present: stow'
  else
    log 'Installing: stow'
    brew install stow
    log 'Installed: stow'
  fi 
}

# Install and configure tmux
init_tmux() {

  # Install if not present
  if [ $(which tmux) ]; then
    log 'Present: tmux'
  else
    log 'Installing: tmux'
    brew install tmux
    log 'Installed: tmux'
  fi

  # Install config if not present, skip if present and managed, do not touch if present and not managed
  log 'Configuring: tmux'
  stow tmux && log 'Configured: tmux' || log 'Not configured: tmux'
}

# Install and configure nano
init_nano() {

  # Install if not present
  #
  # Require it to be a homebrew installation, because we are going 
  # to depend on extra configs that come with it.
  if [ $(echo $(which nano) | grep $(brew --prefix)) ]; then
    log 'Present: nano'
  else
    log 'Installing: nano'
    brew install nano
    log 'Installed: nano'
  fi
 
  log 'Configuring: nano'

  # Syntax highlighting configs are provided under "$(brew --prefix)/share/nano",
  # which is different between intel and arm installations of osx.
  #
  # In order to have a static .nanorc which includes them, we do:
  # 1. Expose "$(brew --prefix)/share/nano" as "~/.config/nano/share" via symlink
  # 2. Include "~/.config/nano/share/*.nanorc" from .nanorc
  
  # Make a directory for our symlink
  [ -d "$HOME/.config/nano" ] || mkdir -p "$HOME/.config/nano"

  # Create or replace the symlink
  [ -L "$HOME/.config/nano/share" ] || ln -s -hf -v "$(brew --prefix)/share/nano" "$HOME/.config/nano/share"

  # Install config if not present, skip if present and managed, do not touch if present and not managed
  stow nano && log 'Configured: nano' || log 'Not configured: nano'
}

# Install and configure vim
init_vim() {

  # Install if not present
  #
  # Require it to be a homebrew installation, because we are going to depend on
  # extra configs that come with it in `share` directory
  if [ $(echo $(which vim) | grep $(brew --prefix)) ]; then
    log 'Present: vim'
  else
    log 'Installing: vim'
    brew install vim
    log 'Installed: vim'
  fi

  # Install config if not present, skip if present and managed, do not touch if present and not managed
  log 'Configuring: vim'  
  stow vim && log 'Configured: vim' || log 'Not configured: vim'
}

init_git() {

  # Install a homebrew version if not present
  # OSX developer tools provide some version of git, but we want a newer version and auto-updates
  if [ $(echo $(which git) | grep $(brew --prefix)) ]; then
    log 'Present: git'
  else
    log 'Installing: git'
    brew install git
    log 'Installed: git'
  fi

  log 'Configuring: git'

  #------------------------------
  # Opinionated git configuration
  #------------------------------

  # We will neither set name and email nor generate a key.
  # These operations are expected to be done manually.

  # Never touch line endings
  git config --global core.autocrlf input

  # Never ignore case of filenames
  git config --global core.ignorecase false

  # Always rebase on pull
  git config --global pull.rebase true

  # Push to upstream when no refspec given (just git push).
  # Compared to default `simple` option, this allows to have an upstream branch
  # with a different name.
  git config --global push.default upstream

  # Renormalize line endings before merge to reduce conflicts
  git config --global merge.renormalize true

  # Highlight whitespace errors in diff
  git config --global color.diff.whitespace 'red reverse'

  # Simple aliases for muscle memory
  git config --global alias.co    'checkout'
  git config --global alias.cm    'commit'
  git config --global alias.st    'status'
  git config --global alias.br    'branch'
  git config --global alias.rb    'rebase'
  git config --global alias.cp    'cherry-pick'
  git config --global alias.cpc   'cherry-pick --continue'
  git config --global alias.sm    'submodule'
  git config --global alias.prb   'pull --rebase'
  git config --global alias.rbc   'rebase --continue'

  # Fixup last commit
  git config --global alias.amend 'commit --amend -C HEAD'

  # Checkout to a branch by partial name
  git config --global alias.coo   '!f(){ git branch | grep $1 | head -1 | tr -d " " | xargs git checkout; }; f'

  # Custom log format
  git config --global alias.hist  'log --pretty=format:"%C(green)%h%Creset %cd %C(yellow)%an%Creset via %C(cyan)%cn%Creset%C(green)%d%Creset%n%Creset%B" --graph --date=local'

  log 'Configured: git'
}

# Install git-delta and configure git to use it in order to get fancy diffs
init_delta() {

  # Install if not present
  if [ $(which delta) ]; then
    log 'Present: git-delta'
  else
    log 'Installing: git-delta'
    brew install git-delta
    log 'Installed: git-delta'
  fi

  log 'Configuring: git-delta'
  
  # Use it as git pager
  git config --global core.pager delta

  # Use it with interactive commands like `git add -p`
  git config --global interactive.diffFilter 'delta --color-only'

  # Enable navigation between diff hunks with n and N keys
  git config --global delta.navigate true
  
  # Style: show line numbers, hide line +/- markers
  git config --global delta.line-numbers true
  git config --global delta.keep-plus-minus-markers false

  # Suggested setting from git-delta manual, no idea why
  git config --global merge.conflictStyle zdiff3

  log 'Configured: git-delta'
}

# Install chroma
#
# It will be used by colorize plugin of oh-my-zsh
# to provide syntax highlighting in `cat` and `less`.
init_chroma() {

  # Install if not present
  if [ $(which chroma) ]; then
    log 'Present: chroma'
  else
    log 'Installing: chroma'
    brew install chroma
    log 'Installed: chroma'
  fi
}

# Install and configure oh-my-zsh
#
# This will rewrite .zshrc file!
# Original .zshrc will be saved as .zshrc.pre-oh-my-zsh
init_omz() {

  # Install oh-my-zsh if not present
  if [ -n "$ZSH" ] && [ -d "$ZSH" ]; then
    log 'Present: oh-my-zsh'
  else
    
    log 'Installing: oh-my-zsh'
    
    # Unattended install: will not run zsh after finishing
    # It will however replace .zshrc and save original as .zshrc.pre-oh-my-zsh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    # If we've just installed oh-my-zsh then it's probably not active in current session.
    # We'll encourage the user to start a new sessoin after we're done.
    did_install_omz=true

    # Throw away config from oh-my-zsh - we will bring our own
    rm "$HOME/.zshrc"  
    
    log 'Installed: oh-my-zsh'
  fi

  if [ -n "$(brew ls --versions zsh-syntax-highlighting)" ]; then
    log 'Present: zsh-syntax-highlighting'
  else
    log 'Installing: zsh-syntax-highlighting'
    brew install zsh-syntax-highlighting
    log 'Installed: zsh-syntax-highlighting'
  fi

  # Install config if not present, skip if present and managed, do not touch if present and not managed
  log 'Configuring: zsh'  
  stow zsh && log 'Configured: zsh' || log 'Not configured: zsh'
}

# Install nvm
init_nvm() {

  # Install if not present
  if [ -n "$NVM_DIR" ] && [ -s "$NVM_DIR/nvm.sh" ]; then
    log 'Present: nvm'
  else
    
    log 'Installing: nvm'

    # Install from homebrew.
    #
    # Maintainers of nvm explicitly state that managing nvm via homebrew is not
    # oficially supported, but this way we get automatic updates.
    #
    # Our .zshrc is already configured to use nvm from homebrew.
    brew install nvm
    
    # $NVM_DIR is already set in our .zshrc but we need to create it
    [ -d "$NVM_DIR" ] || mkdir -p "$NVM_DIR"

    # Activate nvm in current session.
    # On first run it will create a symlink for `nvm.sh`` inside $NVM_DIR.
    # Our .zshrc will use that symlink to load nvm from $NVM_DIR instead of
    # calling `brew --prefix nvm` - this is a perfomance optimization.
    source "$(brew --prefix nvm)/nvm.sh"
    
    log 'Installed: nvm'
  fi
}

init_homebrew
init_basictools
init_stow
init_tmux
init_nano
init_vim
init_git
init_delta
init_chroma
init_omz 
init_nvm

log 'All done!'

if [ $did_install_omz = true ]; then
  log 'Start a new session to get oh-my-zsh experience'
fi
