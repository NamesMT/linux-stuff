FROM namesmt/linux-stuff:arch-node
LABEL maintainer="dangquoctrung123@gmail.com"

## +dev: enhancements for development :D
RUN pacman -Syu --noconfirm git less

# Adding a simple command to change git remote connection from/to ssh/https
RUN touch /etc/profile.d/gitRemoteChanger.sh && \
  echo $'alias git-ssh=\'git remote set-url origin \"\$\(git remote get-url origin \| sed -E \'\\\'\'s,\^https://\(\[\^/\]\*\)/\(.\*\)\$,git@\\1:\\2,\'\\\'\'\)\"\' >> /etc/profile.d/gitRemoteChanger.sh' && \
  echo $'alias git-https=\'git remote set-url origin \"\$\(git remote get-url origin \| sed -E \'\\\'\'s,\^git@\(\[\^:\]\*\):/\*\(.\*\)\$,https://\\1/\\2,\'\\\'\'\)\"\' >> /etc/profile.d/gitRemoteChanger.sh' && \
  source /etc/profile.d/gitRemoteChanger.sh

# curl + guard: a failed fetch must fail the build, not silently ship an image with no zsh config.
RUN curl -fsSL -o /tmp/zsh-in-docker.sh \
    https://github.com/deluan/zsh-in-docker/releases/latest/download/zsh-in-docker.sh && \
  sh -c "$(cat /tmp/zsh-in-docker.sh)" -- \
  -x \
  -t https://github.com/spaceship-prompt/spaceship-prompt \
  -a 'SPACESHIP_USER_SHOW=false' \
  -a 'SPACESHIP_DIR_TRUNC_REPO=false' \
  -p command-not-found \
  -p git \
  -p z \
  -p https://github.com/zsh-users/zsh-autosuggestions \
  -p https://github.com/zsh-users/zsh-completions \
  -p https://github.com/z-shell/F-Sy-H \
  -p zsh-autocomplete && \
  test -f "$HOME/.zshrc"

# Pinned — rationale in AGENTS.md (real-time completion breaks after b7393e8).
RUN git clone -q https://github.com/marlonrichert/zsh-autocomplete.git \
      "$HOME/.oh-my-zsh/custom/plugins/zsh-autocomplete" && \
    git -C "$HOME/.oh-my-zsh/custom/plugins/zsh-autocomplete" checkout -q b7393e8fcb7ec05d0aff198486d54465358b8164
##
