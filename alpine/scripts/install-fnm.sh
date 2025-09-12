#!/bin/bash

set -e

INSTALL_DIR="$HOME/.local/share/fnm"

check_dependencies() {
  echo "Checking dependencies for the installation script..."

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
  URL=https://github.com/Schniz/fnm/releases/latest/download/fnm-linux.zip

  DOWNLOAD_DIR=$(mktemp -d)

  echo "Downloading $URL..."

  mkdir -p "$INSTALL_DIR" &>/dev/null

  if ! wget $URL -O $DOWNLOAD_DIR/fnmArchive.zip; then
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

  rm -rf $DOWNLOAD_DIR
}

setup_shell() {
  echo "Installing for Zsh. Appending the following to ~/.zshrc:"
  echo ""
  echo '  # fnm'
  echo '  export FNM_NODE_DIST_MIRROR=https://unofficial-builds.nodejs.org/download/release'
  echo '  export FNM_ARCH=x64-musl'
  echo '  export PATH="'"$INSTALL_DIR"':$PATH"'
  echo '  eval "`fnm env --use-on-cd --shell=zsh`"'

  echo '' >>~/.zshrc
  echo '# fnm' >>~/.zshrc
  echo 'export FNM_NODE_DIST_MIRROR=https://unofficial-builds.nodejs.org/download/release' >>~/.zshrc
  echo 'export FNM_ARCH=x64-musl' >>~/.zshrc
  echo 'export PATH="'$INSTALL_DIR':$PATH"' >>~/.zshrc
  echo 'eval "`fnm env --use-on-cd --shell=zsh`"' >>~/.zshrc

  echo ""
  echo "In order to apply the changes, open a new terminal or run the following command:"
  echo ""
  echo "  source ~/.zshrc"
}

check_dependencies
download_fnm
setup_shell
