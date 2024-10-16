
FROM ubuntu:18.04

LABEL maintainer="CircleCI <support@circleci.com>"

# Change default shell from Dash to Bash
RUN rm /bin/sh && ln -s /bin/bash /bin/sh
RUN --mount=type=secret,id=COMPOSER_AUTH,env=COMPOSER_AUTH echo $COMPOSER_AUTH
RUN echo Validation

WORKDIR /root/project
