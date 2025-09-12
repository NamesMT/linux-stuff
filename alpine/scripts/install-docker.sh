#!/bin/bash

set -e

## What this?
## Script to setup docker in a fresh alpine instance :D

# Install deps
apk add openrc docker docker-compose

# mount cgroup
grep -qxF 'cgroup /sys/fs/cgroup cgroup defaults 0 0' /etc/fstab || echo 'cgroup /sys/fs/cgroup cgroup defaults 0 0' |  tee -a /etc/fstab

# get start script docker
wget https://gist.githubusercontent.com/NamesMT/0708cc223a3db878df0477159115a49b/raw/17f45c7f23d3ecd8125963d5171f046979cb8f28/alpine.docker.service.sh -O ${HOME}/alpine.docker.service.sh

# configure start docker on standard shell login
echo "source $HOME/alpine.docker.service.sh" >> $HOME/.profile

# configure start docker for .zsh if .zshrc exists
if [ -e $HOME/.zshrc ]
then
    echo "source $HOME/alpine.docker.service.sh" >> $HOME/.zshrc
fi

# start docker and verify it's status
source $HOME/alpine.docker.service.sh
docker info
docker-compose version

# cgroup systemd
cat << EOT > $HOME/alpine.cgroup.systemd.sh
if [ ! -d /sys/fs/cgroup/systemd ]; then
  sudo mkdir /sys/fs/cgroup/systemd
  echo "creating cgroup systemd folder..."
fi
if ! grep -qs '/sys/fs/cgroup/systemd' /proc/mounts; then
  sudo mount -n -t cgroup -o none,name=systemd cgroup /sys/fs/cgroup/systemd
  echo "mounting cgroup systemd folder..."
fi
EOT

# configure start cgroup systemd
echo "source $HOME/alpine.cgroup.systemd.sh" >> $HOME/.profile
# configure start cgroup systemd for .zsh if .zshrc exists
if [ -e $HOME/.zshrc ]
then
    echo "source $HOME/alpine.cgroup.systemd.sh" >> $HOME/.zshrc
fi
# start cgroup systemd
source $HOME/alpine.cgroup.systemd.sh
