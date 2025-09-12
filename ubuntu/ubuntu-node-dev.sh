#!/bin/bash

set -e

## Works with non-root user installation

## Whats this?
## Script to install an opinionated dev environment, check out: gh:namesmt/linux-stuff

# Install basic packages
sudo apt-get update
sudo apt-get install -y \
  zip jq curl less zsh git

# Configures zsh
sh -c "$(wget -qO- https://github.com/deluan/zsh-in-docker/releases/latest/download/zsh-in-docker.sh)" -- \
  -x \
  -t https://github.com/spaceship-prompt/spaceship-prompt \
  -a 'SPACESHIP_USER_SHOW=false' \
  -a 'SPACESHIP_DIR_TRUNC_REPO=false' \
  -p command-not-found \
  -p git \
  -p history-substring-search \
  -p z \
  -p https://github.com/zsh-users/zsh-autosuggestions \
  -p https://github.com/zsh-users/zsh-completions \
  -p https://github.com/zsh-users/zsh-syntax-highlighting

# set zsh as default shell
sudo sed -i 's/\/bin\/bash/\/bin\/zsh/g' /etc/passwd
zsh
export SHELL=/bin/zsh

# Install fnm and install lts node using fnm
wget https://fnm.vercel.app/install -O- | sh
source ~/.zshrc
fnm install --lts
