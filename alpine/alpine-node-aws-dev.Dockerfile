## +aws: Adding aws-cli to the dev environment
# Same repo package as the non-dev aws image, installed on the dev base.
FROM namesmt/linux-stuff:alpine-node-dev
LABEL maintainer="dangquoctrung123@gmail.com"

RUN apk add --no-cache aws-cli mandoc
##
