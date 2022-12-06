#!/usr/bin/env bash

# Import "utils.sh".
eval "$SCRIPT_UTILS"
expand_env_vars_with_prefix "PARAM_"

if [[ $EUID == 0 ]]; then export SUDO=""; else export SUDO="sudo"; fi

# determine specified version
if [[ "$PARAM_VERSION" == latest ]]; then
  VERSION=$(curl -Ls --fail --retry 3 -o /dev/null -w '%{url_effective}' \
    "https://github.com/aelsabbahy/goss/releases/latest" | sed 's:.*/::')
  echo "Latest version of Goss is $VERSION"
else
  VERSION="$PARAM_VERSION"

  echo "Selected version of Goss is $VERSION"
fi

# installation check

if [[ "$PARAM_DEBUG" -eq 1 ]]; then
  set -x
fi

if command -v goss &> /dev/null; then

  if goss --version | \
    grep "$VERSION" &> /dev/null && \
    command -v dgoss &> /dev/null; then

    echo "Goss and dgoss $VERSION are already installed"
    exit 0
  else
    echo "A different version of Goss is installed ($(goss --version)); removing it"

    $SUDO rm -rf "$(command -v goss)" &> /dev/null
    $SUDO rm -rf "$(command -v dgoss)" &> /dev/null
  fi
fi

# download/install
# goss
curl -O --silent --show-error --location --fail --retry 3 \
  "https://github.com/aelsabbahy/goss/releases/download/$VERSION/goss-linux-$PARAM_ARCHITECTURE"

$SUDO mv goss-linux-$PARAM_ARCHITECTURE "$PARAM_INSTALL_DIR"/goss
$SUDO chmod +rx /usr/local/bin/goss

# test/verify goss
if goss --version | grep "$VERSION" &> /dev/null; then
  echo "$(goss --version) has been installed to $(command -v goss)"
else
  echo "Something went wrong; the specified version of Goss could not be installed"
  exit 1
fi

# dgoss
DGOSS_URL="https://raw.githubusercontent.com/aelsabbahy/goss/$VERSION/extras/dgoss/dgoss"
if curl --output /dev/null --silent --head --fail "$DGOSS_URL"; then
  curl -O --silent --show-error --location --fail --retry 3 "$DGOSS_URL"

  $SUDO mv dgoss "$PARAM_INSTALL_DIR"
  $SUDO chmod +rx /usr/local/bin/dgoss

  # test/verify dgoss
  if command -v dgoss &> /dev/null; then
    echo "dgoss has been installed to $(command -v dgoss)"
  else
    echo "Something went wrong; the dgoss wrapper for the specified version of Goss could not be installed"
    exit 1
  fi
else
  echo "No dgoss wrapper found for the selected version of Goss ($VERSION)..."
  echo "Goss installation will proceed, but to use dgoss, please try again with a newer version"
fi
