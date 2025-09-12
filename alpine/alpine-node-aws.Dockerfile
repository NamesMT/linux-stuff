## +aws: Building aws-cli
# Even though alpine 3.18+ have native aws-cli package, the self-built package have lower size and ensure latest version, as well packaged as a proper standalone binary instead of installing multiple packages to global apk.
FROM alpine as builder

RUN apk add --no-cache \
  python3 py3-pip \
  py3-ruamel.yaml \
  unzip \
  groff \
  build-base \
  libffi-dev \
  cmake \
  jq

WORKDIR /aws-cli

RUN wget $(wget https://api.github.com/repos/aws/aws-cli/tags\?per_page\=1 -qO- | jq -r '.[0].tarball_url') -qO- | \
  tar -xz --strip-components=1 --exclude=.changes --exclude=.github --exclude=tests --exclude=proposals

# Allow using pip to add global packages
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


FROM namesmt/linux-stuff:alpine-node
LABEL maintainer="dangquoctrung123@gmail.com"

## +aws: Copy built aws-cli
COPY --from=builder /opt/aws-cli/lib/aws-cli/ /usr/local/aws-cli/
RUN ln -s /usr/local/aws-cli/aws /usr/local/bin/aws
##
