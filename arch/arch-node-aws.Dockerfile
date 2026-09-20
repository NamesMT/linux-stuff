## +aws: Building aws-cli
# As with the alpine build, self-compile aws-cli v2 portable-exe (bundles its own Python
# runtime, so the final image needs no Python), ensuring latest version + a standalone binary.
FROM archlinux:latest as builder

RUN pacman -Syu --noconfirm \
  python python-pip python-setuptools python-wheel \
  python-ruamel-yaml \
  unzip \
  groff \
  base-devel \
  libffi \
  cmake \
  jq \
  curl \
  git

WORKDIR /aws-cli

# Resolve the latest aws-cli release via `git ls-remote` (git protocol) instead of the GitHub
# REST API, which returns 403 "rate limit exceeded" for unauthenticated requests on shared CI IPs.
RUN AWSCLI_TAG=$(git ls-remote --tags --refs --sort=-version:refname 'https://github.com/aws/aws-cli.git' \
      | awk -F'refs/tags/' 'NF{print $2}' \
      | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' \
      | head -1) && \
    echo "Building aws-cli ${AWSCLI_TAG}" && \
    curl -fsSL "https://github.com/aws/aws-cli/archive/refs/tags/${AWSCLI_TAG}.tar.gz" | \
    tar -xz --strip-components=1 --exclude=.changes --exclude=.github --exclude=tests --exclude=proposals

# Allow using pip to add global packages (Arch marks the system Python as externally-managed,
# i.e. PEP 668, so pip refuses global installs otherwise).
RUN python -m pip config set global.break-system-packages true
# Optimize: skip building aws_completer
RUN sed -i '/self._build_aws_completer()/d' backends/build_system/exe.py
RUN pip install -r requirements.txt
RUN pip install -r requirements/download-deps/bootstrap-lock.txt -r requirements/download-deps/portable-exe-lock.txt
RUN ./configure --with-install-type=portable-exe --prefix=/opt/aws-cli
RUN make
RUN make install

# reduce image size: remove autocomplete and examples
RUN rm -rf /opt/aws-cli/bin/aws_completer /opt/aws-cli/lib/aws-cli/aws_completer /opt/aws-cli/lib/aws-cli/awscli/data/ac.index /opt/aws-cli/lib/aws-cli/awscli/examples
RUN find /opt/aws-cli/lib/aws-cli/awscli/data -name completions-1*.json -delete
RUN find /opt/aws-cli/lib/aws-cli/awscli/botocore/data -name completions-1*.json -delete
RUN find /opt/aws-cli/lib/aws-cli/awscli/botocore/data -name examples-1.json -delete
##


FROM namesmt/linux-stuff:arch-node
LABEL maintainer="dangquoctrung123@gmail.com"

## +aws: Copy built aws-cli
COPY --from=builder /opt/aws-cli/lib/aws-cli/ /usr/local/aws-cli/
RUN ln -s /usr/local/aws-cli/aws /usr/local/bin/aws
##
