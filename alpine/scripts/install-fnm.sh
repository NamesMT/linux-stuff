#!/bin/bash

set -euo pipefail

INSTALL_DIR="$HOME/.local/share/fnm"

# Architecture detection: pick the right fnm binary and the matching musl
# Node.js distribution arch (Alpine is musl-based, so we use `*-musl` builds
# from the unofficial-builds mirror).
case "$(uname -m)" in
  x86_64|amd64)
    FNM_ASSET="fnm-linux.zip"
    FNM_ARCH="x64-musl"
    ;;
  aarch64|arm64)
    FNM_ASSET="fnm-arm64.zip"
    FNM_ARCH="arm64-musl"
    ;;
  *)
    echo "Unsupported architecture: $(uname -m)" >&2
    exit 1
    ;;
esac

check_dependencies() {
  echo "Checking dependencies for the installation script..."
  SHOULD_EXIT=""

  echo -n "Checking availability of unzip... "
  if hash unzip 2>/dev/null; then
    echo "OK!"
  else
    echo "Missing!"
    SHOULD_EXIT="true"
  fi

  if [ "$SHOULD_EXIT" = "true" ]; then
    echo "Not installing fnm due to missing dependencies."
    exit 1
  fi
}

download_fnm() {
  URL="https://github.com/Schniz/fnm/releases/latest/download/${FNM_ASSET}"

  DOWNLOAD_DIR="$(mktemp -d)"

  echo "Downloading $URL..."

  mkdir -p "$INSTALL_DIR" >/dev/null 2>&1

  if ! wget -q "$URL" -O "$DOWNLOAD_DIR/fnmArchive.zip"; then
    echo "Download failed."
    exit 1
  fi

  unzip -q "$DOWNLOAD_DIR/fnmArchive.zip" -d "$DOWNLOAD_DIR"

  if [ -f "$DOWNLOAD_DIR/fnm" ]; then
    mv "$DOWNLOAD_DIR/fnm" "$INSTALL_DIR/fnm"
  else
    mv "$DOWNLOAD_DIR/fnmArchive/fnm" "$INSTALL_DIR/fnm"
  fi

  chmod +x "$INSTALL_DIR/fnm"

  rm -rf "$DOWNLOAD_DIR"
}

setup_shell() {
  echo "Installing for Zsh. Appending the following to ~/.zshrc:"
  echo ""
  echo '  # fnm'
  echo '  export FNM_NODE_DIST_MIRROR=https://unofficial-builds.nodejs.org/download/release'
  echo "  export FNM_ARCH=${FNM_ARCH}"
  echo '  export PATH="'"$INSTALL_DIR"':$PATH"'
  echo '  eval "`fnm env --use-on-cd --shell=zsh`"'

  {
    echo ''
    echo '# fnm'
    echo 'export FNM_NODE_DIST_MIRROR=https://unofficial-builds.nodejs.org/download/release'
    echo "export FNM_ARCH=${FNM_ARCH}"
    echo "export PATH=\"$INSTALL_DIR:\$PATH\""
    echo 'eval "`fnm env --use-on-cd --shell=zsh`"'
  } >> ~/.zshrc

  echo ""
  echo "In order to apply the changes, open a new terminal or run the following command:"
  echo ""
  echo "  source ~/.zshrc"
}

check_dependencies
download_fnm
setup_shell
