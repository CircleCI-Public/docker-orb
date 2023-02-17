# vim:set ft=dockerfile:
#
# The Ubuntu-based CircleCI Docker Image. Only use Ubuntu Long-Term Support
# (LTS) releases.

FROM ubuntu:18.04

LABEL maintainer="CircleCI <support@circleci.com>"

ARG COMMIT_HASH

# Change default shell from Dash to Bash
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

RUN if [[ "${COMMIT_HASH}" =~ ^[0-9a-f]{5,40}$ ]]; then \
    echo "Success: COMMIT_HASH is valid commit hash"; \
  else \
    echo "Error: COMMIT_HASH is invalid commit hash"; \
    exit 1; \
  fi

WORKDIR /root/project
