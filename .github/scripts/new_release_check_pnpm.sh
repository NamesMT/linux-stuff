#!/bin/bash
set -eu

# Check if the version is already tagged, if not, tag it and push to trigger CI
check_version() {
  TAG_NAME=pnpm$(echo $1 | cut -dv -f2)
  # CHECK IF WE ALREADY BUILD THE TAG
  if [ $(git tag -l "$TAG_NAME") ]; then
    echo "Version exists: $1"
  else
    echo "Found a new version: $1. Tagging this repository to trigger rebuild"
    git tag $TAG_NAME
    git push origin $TAG_NAME
  fi
}

# REPOSITORY TO CHECK FOR NEW TAG
REPO_OWNER="pnpm"
REPO_NAME="pnpm"

# GET THE THREE LATEST RELEASES OF THE REPO (in case the repo decides to release more than one version in a day :D)
RELEASES=$(wget -qO- "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases?per_page=3")

# GET THE TAG NAME AS WE USE IT FOR OUR OWN TAGS
echo $RELEASES | jq -c '.[]' |
  while IFS=$"\n" read -r VAR; do
    VERSION=$(echo "$VAR" | jq -r '.tag_name')
    check_version "$VERSION"
  done
