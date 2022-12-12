#!/usr/bin/env bash

# Import "utils.sh".
eval "$SCRIPT_UTILS"
expand_env_vars_with_prefix "PARAM_"

if [[ $EUID == 0 ]]; then export SUDO=""; else export SUDO="sudo"; fi

# grab Docker version
if [[ "$PARAM_VERSION" == "latest" ]]; then
  # extract latest version from GitHub releases API
  declare -i INDEX=0

  while :
  do
    INDEX_VERSION=$(curl --silent --show-error --location --fail --retry 3 \
      https://api.github.com/repos/docker/cli/tags | \
      jq --argjson index "$INDEX" '.[$index].name')

    # filter out betas & release candidates
    # shellcheck disable=SC2143 # Doesn't apply to this case.
    if [[ $(echo "$INDEX_VERSION" | grep -v beta | grep -v rc) ]]; then

      # can't use substring expression < 0 on macOS
      DOCKER_VERSION="${INDEX_VERSION:1:$((${#INDEX_VERSION} - 1 - 1))}"

      echo "Latest stable version of Docker is $DOCKER_VERSION"
      break
    else
      INDEX=$((INDEX+1))
    fi
  done
else
  DOCKER_VERSION="$PARAM_VERSION"
  echo "Selected version of Docker is $DOCKER_VERSION"
fi

# check if Docker needs to be installed
DOCKER_VERSION_NUMBER="${DOCKER_VERSION:1}"

if command -v docker >> /dev/null 2>&1; then
  if docker --version | grep "$DOCKER_VERSION_NUMBER" >> /dev/null 2>&1; then
    echo "Docker $DOCKER_VERSION is already installed"
    exit 0
  else
    echo "A different version of Docker is installed ($(docker --version)); removing it"
    $SUDO rm -f "$(command -v docker)"
  fi
fi

# get binary download URL for specified version
if uname -a | grep Darwin >> /dev/null 2>&1; then
  PLATFORM=mac
else
  PLATFORM=linux
fi

DOCKER_BINARY_URL="https://download.docker.com/$PLATFORM/static/stable/x86_64/docker-$DOCKER_VERSION_NUMBER.tgz"

# download binary tarball
DOWNLOAD_DIR="$(mktemp -d)"
DOWNLOAD_FILE="${DOWNLOAD_DIR}/docker.tgz"
curl --output "$DOWNLOAD_FILE" \
  --silent --show-error --location --fail --retry 3 \
  "$DOCKER_BINARY_URL"

tar xf "$DOWNLOAD_FILE" -C "$DOWNLOAD_DIR" && rm -f "$DOWNLOAD_FILE"

# install Docker binaries
BINARIES=$(ls "${DOWNLOAD_DIR}/docker")
$SUDO mv "$DOWNLOAD_DIR"/docker/* "$PARAM_INSTALL_DIR"
$SUDO rm -rf "$DOWNLOAD_DIR"

for binary in $BINARIES
do
  $SUDO chmod +x "$PARAM_INSTALL_DIR/$binary"
done

# verify version
echo "$(docker --version) has been installed to $(command -v docker)"
