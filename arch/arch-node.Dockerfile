ARG ARCH_VERSION=latest

FROM archlinux:${ARCH_VERSION}
LABEL maintainer="dangquoctrung123@gmail.com"
ARG PNPM_VERSION=latest

## Install basic packages
# Arch has no official `node:` base image, so install Node's toolchain from pacman.
# Unlike Alpine (glibc is native to Arch), no gcompat/libstdc++ shims are needed.
RUN pacman -Syu --noconfirm \
  nodejs npm corepack \
  zip unzip jq sudo less zsh curl wget

# Set zsh as the default shell
RUN sed -i 's/\/root:\/bin\/bash/\/root:\/bin\/zsh/g' /etc/passwd
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
# Cache-buster: re-run the corepack prepare when a new pnpm version is published.
# Uses the npm registry (not rate-limited) instead of the unauthenticated GitHub API.
ADD "https://registry.npmjs.org/-/package/pnpm/dist-tags" latest_pnpm
RUN corepack enable
RUN corepack prepare pnpm@$PNPM_VERSION --activate
RUN pnpm i -g @antfu/ni && \
  touch ~/.nirc && \
  echo 'defaultAgent=pnpm' >> ~/.nirc && \
  echo 'globalAgent=pnpm' >> ~/.nirc
##
