# myenv-osx

A collection of configs and scripts for my OSX environment.

It brings the following:
- some basic tools:
  - `tree`
  - `watch`
  - `jq`
  - `htop`
  - `mc`
- `stow` for config management
- `tmux` + config
- `nano` + config
- `vim` + config
- `git` + config
- `oh-my-zsh` + `.zshrc`
- `nvm`


## Install

On a fresh system you first need to install developer tools. The following command will open installation dialog (it might open _behind_ the terminal window):
```sh
xcode-select --install
```

Now you have `git` to clone this repo:
```sh
git clone https://github.com/gaen/myenv-osx.git ~/.myenv
```

## Usage

All commands should be executed inside `.myenv` directory.

### Bootstrap everything

This will install all software and configs:

```sh
./init.sh
```

### Manage individual configs

Config files are managed with [GNU Stow](https://www.gnu.org/software/stow/manual/stow.html).

#### List all stow packages

Stow packages are simply directories inside `./stow`, so just list it:

```sh
ls stow
```

#### Stow a package

This will symlink configs from a given package into the home directory:
```sh
stow <package>
```

It will never delete or modify any existing files - in case of a conflict it will abort all operations.

For extra caution you can add `-n` for dry run and `-v` to see all intended changes:

```sh
stow -nv <package>
```

#### Unstow a package

This will remove all symlinks to a given package:
```sh
stow -D <package>
```

It will never delete or modify any existing files that are not symlinks pointing inside the package.

For extra caution you can add `-n` for dry run and `-v` to see all intended changes:

```sh
stow -nv -D <package>
```