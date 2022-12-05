#!/usr/bin/env bash

# Import "utils.sh".
eval "$SCRIPT_UTILS"
expand_env_vars_with_prefix "PARAM_"

if [[ $EUID == 0 ]]; then export SUDO=""; else export SUDO="sudo"; fi

# grab dockerize version
if [[ "$PARAM_VERSION" == "latest" ]]; then
  DOCKERIZE_VERSION=$(curl --fail --retry 3 -Ls -o /dev/null -w '%{url_effective}' "https://github.com/jwilder/dockerize/releases/latest" | sed 's:.*/::')
  echo "Latest version of dockerize is $DOCKERIZE_VERSION"
else
  DOCKERIZE_VERSION="$PARAM_VERSION"
  echo "Selected version of dockerize is $DOCKERIZE_VERSION"
fi

# check if dockerize needs to be installed
if command -v dockerize &> /dev/null; then
  if dockerize --version | grep "$DOCKERIZE_VERSION" &> /dev/null; then
    echo "dockerize $DOCKERIZE_VERSION is already installed"
    exit 0
  else
    echo "A different version of dockerize is installed ($(dockerize --version)); removing it"
    $SUDO rm -f "$(command -v dockerize)"
  fi
fi

# construct binary download URL
if uname -a | grep Darwin &> /dev/null; then
  PLATFORM=darwin-amd64
elif cat /etc/issue | grep Alpine &> /dev/null; then
  PLATFORM=alpine-linux-amd64
  apk add --no-cache openssl
else
  PLATFORM=linux-amd64
fi

DOCKERIZE_BINARY_URL="https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-$PLATFORM-$DOCKERIZE_VERSION.tar.gz"

# download & install binary
curl -O --silent --show-error --location --fail --retry 3 \
"$DOCKERIZE_BINARY_URL"

tar xf "dockerize-$PLATFORM-$DOCKERIZE_VERSION.tar.gz"
rm -f "dockerize-$PLATFORM-$DOCKERIZE_VERSION.tar.gz"

$SUDO mv dockerize "$PARAM_INSTALL_DIR"
$SUDO chmod +x "$PARAM_INSTALL_DIR"/dockerize

# verify version
echo "dockerize $(dockerize --version) has been installed to $(command -v dockerize)"
