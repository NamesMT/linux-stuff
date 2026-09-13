#!/bin/bash

set -euo pipefail

# Note: bun's musl build is still compiled against glibc 2.34; it fails with
# the newer 2.35 glibc from install-glibc.sh, so we pin 2.34 here.
GLIBC_VERSION="2.34-r0"
BASE_URL="https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}"

# Remove any existing glibc/gcompat so the pinned version installs cleanly.
# (`gcompat` is a glibc compatibility shim that conflicts with a real glibc.)
for package in gcompat glibc glibc-bin; do
  if apk info -e "$package"; then
    echo "Removing $package..."
    apk del "$package"
  else
    echo "$package is not installed, skipping."
  fi
done

cd /tmp
curl -fsSLO "${BASE_URL}/glibc-${GLIBC_VERSION}.apk"
curl -fsSLO "${BASE_URL}/glibc-bin-${GLIBC_VERSION}.apk"
apk add --no-cache --allow-untrusted --force-overwrite \
  bash "glibc-${GLIBC_VERSION}.apk" "glibc-bin-${GLIBC_VERSION}.apk"

curl -fsSL https://bun.sh/install | bash
