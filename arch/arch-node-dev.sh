#!/bin/bash

set -e

## Works with non-root user installation

## Whats this?
## Script to install an opinionated dev environment, check out: gh:namesmt/linux-stuff

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
export SHELL=/bin/zsh
exec /bin/zsh

# Install fnm and install lts node using fnm
wget https://fnm.vercel.app/install -O- | sh
source ~/.zshrc
fnm install --lts

# Setup the environment path for pnpm
mkdir ~/.pnpm-global
sudo touch /etc/profile.d/pnpmPath.sh && \
  echo 'export PNPM_HOME=$HOME/.pnpm-global' | sudo tee -a /etc/profile.d/pnpmPath.sh && \
  echo 'export PATH=$PNPM_HOME:$PATH' | sudo tee -a /etc/profile.d/pnpmPath.sh && \
  source /etc/profile.d/pnpmPath.sh

# Install pnpm and ni
npm install --global corepack@latest
corepack enable
corepack prepare pnpm --activate
pnpm i -g @antfu/ni && \
  touch ~/.nirc && \
  echo 'defaultAgent=pnpm' | tee -a ~/.nirc && \
  echo 'globalAgent=pnpm' | tee -a ~/.nirc

# Adding a simple command to change git remote connection from/to ssh/https
sudo touch /etc/profile.d/gitRemoteChanger.sh && \
  echo alias git-ssh=\'git remote set-url origin \"\$\(git remote get-url origin \| sed -E \'\\\'\'s,\^https://\(\[\^/\]\*\)/\(.\*\)\$,git@\\1:\\2,\'\\\'\'\)\"\' | sudo tee -a /etc/profile.d/gitRemoteChanger.sh && \
  echo alias git-https=\'git remote set-url origin \"\$\(git remote get-url origin \| sed -E \'\\\'\'s,\^git@\(\[\^:\]\*\):/\*\(.\*\)\$,https://\\1/\\2,\'\\\'\'\)\"\' | sudo tee -a /etc/profile.d/gitRemoteChanger.sh && \
  source /etc/profile.d/gitRemoteChanger.sh

echo "All done, please restart / open a new zsh shell to ensure everything is loaded correctly"
