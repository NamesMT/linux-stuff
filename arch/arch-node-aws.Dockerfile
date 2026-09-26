## +aws: Installing aws-cli from the Arch extra repo
# Tracks whichever aws-cli v2 the current Arch release ships, instead of self-building
# the latest release. `mandoc` is needed for `aws help` to render its man pages;
# python-docutils alone is not enough.
FROM namesmt/linux-stuff:arch-node
LABEL maintainer="dangquoctrung123@gmail.com"

RUN pacman -Syu --noconfirm aws-cli-v2 mandoc
##
