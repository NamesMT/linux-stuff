## +aws: Including aws-cli
FROM namesmt/linux-stuff:arch-node-aws as builder
##


FROM namesmt/linux-stuff:arch-node-dev
LABEL maintainer="dangquoctrung123@gmail.com"

## +aws: Copy built aws-cli
COPY --from=builder /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=builder /usr/local/bin/ /usr/local/bin/
##
