# vim:set ft=dockerfile:
#
# The Ubuntu-based CircleCI Docker Image. Only use Ubuntu Long-Term Support
# (LTS) releases.

FROM ubuntu:18.04

LABEL maintainer="CircleCI <support@circleci.com>"

# Change default shell from Dash to Bash
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

RUN apt-get update && apt-get install -y \
	bzip2 \
	ca-certificates \
	curl \
	xvfb \
	git \
	gnupg \
	gzip \
	jq \
	locales \
	mercurial \
	net-tools \
	netcat \
	openssh-client \
	parallel \
	sudo \
	tar \
	unzip \
	wget \
	zip

WORKDIR /root/project
