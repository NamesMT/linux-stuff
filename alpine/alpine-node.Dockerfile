ARG ALPINE_VERSION=3.23

FROM node:lts-alpine${ALPINE_VERSION}
LABEL maintainer="dangquoctrung123@gmail.com"
ARG PNPM_VERSION=latest

## Install basic packages
RUN apk add --no-cache \
  gcompat libstdc++ \
  zip unzip jq sudo less zsh curl wget

# Set zsh as the default shell
RUN sed -i 's/\/root:\/bin\/ash/\/root:\/bin\/zsh/g' /etc/passwd
SHELL ["/bin/zsh", "-lc"]
ENV SHELL=/bin/zsh
CMD ["/bin/zsh", "--login"]
##

## Install PNPM
ENV PNPM_HOME="/root/.local/share/pnpm"
ENV PATH="$PNPM_HOME/bin:$PNPM_HOME:$PATH"
RUN touch /etc/profile.d/pnpmPath.sh && \
  echo "export PNPM_HOME=\$PNPM_HOME" >> /etc/profile.d/pnpmPath.sh && \
  echo "export PATH=\$PNPM_HOME/bin:\$PNPM_HOME:\$PATH" >> /etc/profile.d/pnpmPath.sh && \
  source /etc/profile.d/pnpmPath.sh
# Cache-buster: re-run the corepack install when a new pnpm version is published.
# Uses the npm registry (not rate-limited) instead of the unauthenticated GitHub API.
ADD "https://registry.npmjs.org/-/package/pnpm/dist-tags" latest_pnpm
RUN npm install --global corepack@latest
RUN corepack enable
RUN corepack prepare pnpm@$PNPM_VERSION --activate
RUN pnpm i -g @antfu/ni && \
  touch ~/.nirc && \
  echo 'defaultAgent=pnpm' >> ~/.nirc && \
  echo 'globalAgent=pnpm' >> ~/.nirc
##

# Clear the ENTRYPOINT from node image
ENTRYPOINT []
