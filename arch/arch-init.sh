#!/bin/bash

set -euo pipefail

if [ -z "${NEW_USER:-}" ]; then
  echo "Error: \$NEW_USER is not set" >&2
  exit 1
fi

## What's this?
## Script to initialize a new Arch Linux installation: init & update databases, packages, create new user.
## NOTE: this script enables sudo for the `wheel` group.

# Update package database, keychain, and trust database
pacman-key --init
pacman-key --populate archlinux
pacman -Syu archlinux-keyring sudo --noconfirm

# Create user (no-op if it already exists)
if id "$NEW_USER" >/dev/null 2>&1; then
  echo "User '$NEW_USER' already exists, skipping creation"
else
  useradd -m -G wheel -s /bin/bash "$NEW_USER"
fi

# Allow members of the `wheel` group to use sudo
sed -i 's/# %wheel ALL=(ALL:ALL)/%wheel ALL=(ALL:ALL)/g' /etc/sudoers

# WSL goodie: set the new user as the default user
if [ -f /etc/wsl.conf ]; then
  if ! grep -q '^\[user\]' /etc/wsl.conf; then
    echo '[user]' >> /etc/wsl.conf
  fi
  if ! grep -q "^default=$NEW_USER" /etc/wsl.conf; then
    echo "default=$NEW_USER" >> /etc/wsl.conf
  fi
fi

echo "Please run \"su - $NEW_USER\" to ensure you are logged in as the newly created user"
