#!/bin/bash

set -e

# List of packages to remove
echo "Removing existing glibc and glibc-bin..."
packages_to_remove="glibc glibc-bin"

for package in $packages_to_remove; do
  if apk info -e "$package"; then
    echo "$package found, removing..."
    apk del "$package"
  fi
done

cd /tmp
wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.35-r1/glibc-2.35-r1.apk
wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.35-r1/glibc-bin-2.35-r1.apk
apk add --no-cache --allow-untrusted --force-overwrite bash glibc-2.35-r1.apk glibc-bin-2.35-r1.apk
