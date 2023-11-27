#
# build the target application
#
FROM public.ecr.aws/docker/library/alpine:3.18

# update the packages and add what we need
RUN apk update && apk upgrade && apk add bash tzdata ca-certificates curl jq tar aws-cli py3-pip zip unzip musl-utils musl-locales && rm -fr /var/cache/apk/*

# install the bagit package
RUN pip3 install bagit

# Create the run user and group
RUN addgroup --gid 18570 sse && adduser --uid 1984 docker -G sse -D

# set the timezone appropriatly
ENV TZ=UTC
RUN cp /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Specify home 
ENV APP_HOME /aptrust-tools
WORKDIR $APP_HOME

# Create necessary directories
RUN mkdir -p $APP_HOME/scripts
RUN chown -R docker $APP_HOME && chgrp -R sse $APP_HOME

# Move in necessary assets
COPY scripts/* $APP_HOME/scripts/
COPY data/container_bash_profile /home/docker/.profile

# Ensure permissions are correct
RUN chown docker:sse /home/docker/.profile $APP_HOME/scripts/* && chmod 755 /home/docker/.profile $APP_HOME/scripts/*

# Add the build tag
ARG BUILD_TAG
RUN test -n "$BUILD_TAG" && touch $APP_HOME/buildtag.build-$BUILD_TAG || touch $APP_HOME/buildtag.build-0

# Specify the user
USER docker

#
# end of file
#
