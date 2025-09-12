ARG ALPINE_VERSION=3.21

FROM node:lts-alpine${ALPINE_VERSION}
LABEL maintainer="dangquoctrung123@gmail.com"
ARG PNPM_VERSION=latest

## Install basic packages
RUN apk add --no-cache \
  gcompat libstdc++ zip unzip jq sudo curl zsh bash

# Clear the ENTRYPOINT from node image
ENTRYPOINT []
# Set zsh as the default shell
RUN sed -i 's/\/root:\/bin\/ash/\/root:\/bin\/zsh/g' /etc/passwd
SHELL ["/bin/zsh", "-lc"]
ENV SHELL=/bin/zsh
CMD ["/bin/zsh", "--login"]
##

## Install PNPM
ENV PNPM_HOME=/root/.local/share/pnpm
ENV PATH=$PNPM_HOME:$PATH
RUN touch /etc/profile.d/pnpmPath.sh && \
  echo "export PNPM_HOME=$PNPM_HOME" >> /etc/profile.d/pnpmPath.sh && \
  echo "export PATH=$PNPM_HOME:$PATH" >> /etc/profile.d/pnpmPath.sh && \
  source /etc/profile.d/pnpmPath.sh
# This will make the command re-run if theres a new pnpm version (prevents docker cache installing an older version)
ADD "https://api.github.com/repos/pnpm/pnpm/tags?per_page=1" latest_commit
RUN npm install --global corepack@latest
RUN corepack enable
RUN corepack prepare pnpm@$PNPM_VERSION --activate
RUN pnpm i -g @antfu/ni && \
  touch ~/.nirc && \
  echo 'defaultAgent=pnpm' >> ~/.nirc && \
  echo 'globalAgent=pnpm' >> ~/.nirc
##
