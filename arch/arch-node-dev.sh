#!/bin/bash

set -e

## Works with non-root user installation

## Whats this?
## Script to install an opinionated dev environment, check out: gh:namesmt/linux-stuff

# Update package database, keychain, and trust database
sudo pacman-key --init
sudo pacman-key --populate archlinux
sudo pacman -Sy archlinux-keyring --noconfirm

# Install basic packages
sudo pacman -S --noconfirm \
  zip unzip jq sudo git less zsh curl wget

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

# Setup the environment path for pnpm
touch /etc/profile.d/pnpmPath.sh && \
  echo 'export PNPM_HOME=/root/.local/share/pnpm' >> /etc/profile.d/pnpmPath.sh && \
  echo 'export PATH=$PNPM_HOME:$PATH' >> /etc/profile.d/pnpmPath.sh && \
  source /etc/profile.d/pnpmPath.sh

# Install pnpm and ni
npm install --global corepack@latest
corepack enable
corepack prepare pnpm --activate
pnpm i -g @antfu/ni && \
  touch ~/.nirc && \
  echo 'defaultAgent=pnpm' >> ~/.nirc && \
  echo 'globalAgent=pnpm' >> ~/.nirc

# Adding a simple command to change git remote connection from/to ssh/https
touch /etc/profile.d/gitRemoteChanger.sh && \
  echo alias git-ssh=\'git remote set-url origin \"\$\(git remote get-url origin \| sed -E \'\\\'\'s,\^https://\(\[\^/\]\*\)/\(.\*\)\$,git@\\1:\\2,\'\\\'\'\)\"\' >> /etc/profile.d/gitRemoteChanger.sh && \
  echo alias git-https=\'git remote set-url origin \"\$\(git remote get-url origin \| sed -E \'\\\'\'s,\^git@\(\[\^:\]\*\):/\*\(.\*\)\$,https://\\1/\\2,\'\\\'\'\)\"\' >> /etc/profile.d/gitRemoteChanger.sh && \
  source /etc/profile.d/gitRemoteChanger.sh
