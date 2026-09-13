#!/bin/bash

set -euo pipefail

# sgerrand/alpine-pkg-glibc has no `latest` release; pin an explicit version.
GLIBC_VERSION="2.35-r1"
BASE_URL="https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}"

# Remove existing glibc packages so the pinned version can be installed cleanly
echo "Removing existing glibc and glibc-bin..."
for package in glibc glibc-bin; do
  if apk info -e "$package"; then
    echo "$package found, removing..."
    apk del "$package"
  fi
done

cd /tmp
curl -fsSLO "${BASE_URL}/glibc-${GLIBC_VERSION}.apk"
curl -fsSLO "${BASE_URL}/glibc-bin-${GLIBC_VERSION}.apk"
apk add --no-cache --allow-untrusted --force-overwrite \
  bash "glibc-${GLIBC_VERSION}.apk" "glibc-bin-${GLIBC_VERSION}.apk"
