#!/usr/bin/env bash

# checking for root user
if [[ $(id -u) -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

# installing curl if linux distribution is Alpine
if cat /etc/issue | grep Alpine &> /dev/null; then
  $SUDO apk update
  $SUDO apk add curl
fi

# grab docker-compose version
if [[ "$PARAM_DOCKER_COMPOSER_VERSION" == "latest" ]]; then
  DOCKER_COMPOSE_VERSION="$(curl -Ls --fail --retry 3 -o /dev/null -w '%{url_effective}' "https://github.com/docker/compose/releases/latest" | sed 's:.*/::')"
  echo "Latest stable version of docker-compose is $DOCKER_COMPOSE_VERSION"
else
  DOCKER_COMPOSE_VERSION="$PARAM_DOCKER_COMPOSER_VERSION"
  echo "Selected version of docker-compose is $DOCKER_COMPOSE_VERSION"
fi

# check if docker-compose needs to be installed
if command -v docker-compose &> /dev/null; then
  if docker-compose --version | grep "$DOCKER_COMPOSE_VERSION" &> /dev/null; then
    echo "docker-compose $DOCKER_COMPOSE_VERSION is already installed"
    exit 0
  else
    echo "A different version of docker-compose is installed ($(docker-compose --version)); removing it"
    $SUDO rm -f "$(command -v docker-compose)"1
  fi
fi

# get binary/shasum download URL for specified version
if uname -a | grep Darwin &> /dev/null; then
  PLATFORM=darwin
  HOMEBREW_NO_AUTO_UPDATE=1 brew install coreutils
else
  PLATFORM=linux
fi

DOCKER_COMPOSE_BASE_URL="https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION"
DOCKER_COMPOSE_SHASUM_URL="$DOCKER_COMPOSE_BASE_URL/docker-compose-$PLATFORM-x86_64.sha256"

# download binary and shasum
curl -O \
  --silent --show-error --location --fail --retry 3 \
  "$DOCKER_COMPOSE_SHASUM_URL"

FILENAME=$(cat docker-compose-$PLATFORM-x86_64.sha256 | awk '{ print $NF }' | sed 's/^\*//')

curl -O \
  --silent --show-error --location --fail --retry 3 \
  "$DOCKER_COMPOSE_BASE_URL/$FILENAME"

set +e
grep "$FILENAME" docker-compose-$PLATFORM-x86_64.sha256 | sha256sum -c -
SHASUM_SUCCESS=$?
set -e

if [[ "$SHASUM_SUCCESS" -ne 0 ]]; then
  echo "Checksum validation failed for $FILENAME"
  exit 1
fi

# install docker-compose
$SUDO mv "$FILENAME" "$PARAM_INSTALL_DIR"/docker-compose
$SUDO chmod +x "$PARAM_INSTALL_DIR"/docker-compose

# verify version
echo "$(docker-compose --version) has been installed to $(command -v docker-compose)"