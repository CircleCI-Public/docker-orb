#!/usr/bin/env bash

# Import "utils.sh".
eval "$SCRIPT_UTILS"
expand_env_vars_with_prefix "PARAM_"

trap_exit() {
  # clean-up
  printf '%s\n' "Cleaning up..."
  [ -f "$DOCKER_SHASUM_FILENAME" ] && rm -f "$DOCKER_SHASUM_FILENAME"
}
trap trap_exit EXIT

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
    $SUDO rm -f "$(command -v docker-compose)"
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
DOCKER_COMPOSE_RELEASES_HTML="$(curl -Ls --fail --retry 3 "https://github.com/docker/compose/releases/tag/$DOCKER_COMPOSE_VERSION")"
DOCKER_COMPOSE_RELEASE="docker-compose-$PLATFORM-x86_64"
DOCKER_SHASUM_FILENAME="checksum.txt"

# since v2.10.0, docker-compose doesn't have a ".sha256" file
# so we need to use the "checksums.txt" file instead
if grep --quiet "checksums.txt" <<< "$DOCKER_COMPOSE_RELEASES_HTML"; then
  printf '%s\n' "Downloading \"checksums.txt\" to verify the binary's integrity."

  curl -o "$DOCKER_SHASUM_FILENAME" \
    --silent --location --retry 3 \
    "$DOCKER_COMPOSE_BASE_URL/checksums.txt"
else
  printf '%s\n' "Downloading \"$DOCKER_COMPOSE_RELEASE.sha256\" to verify the binary's integrity."

  curl -o "$DOCKER_SHASUM_FILENAME" \
    --silent --location --retry 3 \
    "$DOCKER_COMPOSE_BASE_URL/$DOCKER_COMPOSE_RELEASE.sha256"
fi

# download docker-compose binary
curl -o "$DOCKER_COMPOSE_RELEASE" \
  --location --retry 3 \
  "$DOCKER_COMPOSE_BASE_URL/$DOCKER_COMPOSE_RELEASE"

# verify binary integrity using SHA-256 checksum
set +e
grep "$DOCKER_COMPOSE_RELEASE" "$DOCKER_SHASUM_FILENAME" | sha256sum -c -
SHASUM_SUCCESS=$?
set -e

if [[ "$SHASUM_SUCCESS" -ne 0 ]]; then
  echo "Checksum validation failed for $DOCKER_COMPOSE_RELEASE"
  exit 1
fi

# install docker-compose
$SUDO mv "$DOCKER_COMPOSE_RELEASE" "$PARAM_INSTALL_DIR"/docker-compose
$SUDO chmod +x "$PARAM_INSTALL_DIR"/docker-compose

# verify version
echo "$(docker-compose --version) has been installed to $(command -v docker-compose)"
