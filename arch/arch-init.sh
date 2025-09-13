#!/bin/bash

set -e

if [ -z "$NEW_USER" ]; then echo "\$NEW_USER is not set" exit 1; fi

## Whats this?
## Script to initialize a new Arch Linux installation: init & update databases, packages, create new user.
## CAUTION: this script will allow passwordless sudo for users.

# Update package database, keychain, and trust database
pacman-key --init
pacman-key --populate archlinux
pacman -Syu archlinux-keyring sudo --noconfirm

# Create user
useradd -m -G wheel -s /bin/bash $NEW_USER
sed -i 's/# %wheel ALL=(ALL:ALL)/%wheel ALL=(ALL:ALL)/g' /etc/sudoers

# WSL goodie: sets the new user as default user
if [ -f "/etc/wsl.conf" ]; then
  echo "[user]" | tee -a /etc/wsl.conf
  echo "default=$NEW_USER" | tee -a /etc/wsl.conf
fi

echo "Please run \"su - $NEW_USER\" to ensure logged in as the newly created user"
