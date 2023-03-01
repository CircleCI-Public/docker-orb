# vim:set ft=dockerfile:
#
# The Ubuntu-based CircleCI Docker Image. Only use Ubuntu Long-Term Support
# (LTS) releases.

FROM cimg/base:2022.09

LABEL maintainer="CircleCI <support@circleci.com>"

# Change default shell from Dash to Bash
# RUN sudo rm /bin/sh && ln -s /bin/bash /bin/sh

# RUN docker run --rm -it cimg/base:2022.09 /usr/bin/curl google.com

RUN sudo apt-get update 
# && apt-get install -y \
# 	bzip2 \
# 	ca-certificates \
# 	curl \
# 	xvfb \
# 	git \
# 	gnupg \
# 	gzip \
# 	jq \
# 	locales \
# 	mercurial \
# 	net-tools \
# 	netcat \
# 	openssh-client \
# 	parallel \
# 	sudo \
# 	tar \
# 	unzip \
# 	wget \
# 	zip

# WORKDIR /root/project
