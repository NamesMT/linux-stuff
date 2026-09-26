## +aws: Installing aws-cli from the Alpine community repo
# Tracks whichever aws-cli v2 the current Alpine release ships, instead of self-building
# the latest release. The AWS official prebuilt binary is glibc-only and cannot run on
# musl (it fails on `dladdr1` even with gcompat), so the distro package is the supported
# route here.
FROM namesmt/linux-stuff:alpine-node
LABEL maintainer="dangquoctrung123@gmail.com"

# `mandoc` instead of the larger `groff`, so `aws help` can render its man pages.
RUN apk add --no-cache aws-cli mandoc
##
