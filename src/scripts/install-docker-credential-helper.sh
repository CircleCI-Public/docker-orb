#!/usr/bin/env bash

# Import "utils.sh".
eval "$SCRIPT_UTILS"
expand_env_vars_with_prefix "PARAM_"

HELPER_NAME="$PARAM_HELPER_NAME"

if uname | grep -q "Darwin"; then platform="darwin"
else platform="linux"
fi

# Infer helper name from the platform
if [ -z "${HELPER_NAME}" ]; then
  if [ "$platform" = "darwin" ]; then HELPER_NAME="osxkeychain"
  else HELPER_NAME="pass"
  fi
fi

HELPER_FILENAME="docker-credential-${HELPER_NAME}"

if command -v "$HELPER_FILENAME" &> /dev/null; then
  echo "$HELPER_FILENAME is already installed"
  exit 0
fi

SUDO=""
if [ "$(id -u)" -ne 0 ] && command -v sudo &> /dev/null; then
  SUDO="sudo"
fi

# Create heredoc template here due to tab indentation issue
GPG_TEMPLATE=$(mktemp gpg_template.XXXXXX)
cat > $GPG_TEMPLATE << EOF
  Key-Type: RSA
  Key-Length: 2048
  Name-Real: CircleCI Orb User
  Name-Email: circleci-orbs@circleci.com
  Expire-Date: 0
  %no-protection
  %no-ask-passphrase
  %commit
EOF

if [ "$HELPER_FILENAME" = "docker-credential-pass" ]; then
  # Install pass which is needed for docker-credential-pass to work
  $SUDO apt-get update --yes && $SUDO apt-get install gnupg2 pass --yes

  # Initialize pass with a gpg key
  gpg2 --batch --gen-key "$GPG_TEMPLATE"

  FINGERPRINT_STRING=$(gpg2 \
    --list-keys --with-fingerprint --with-colons \
    circleci-orbs@circleci.com | \
    grep fpr)
  FINGERPRINT="$(grep -oP '(?<=:)([A-Za-z0-9].*)(?=:)' <<< $FINGERPRINT_STRING)"
  pass init $FINGERPRINT
fi
rm "$GPG_TEMPLATE"

echo "Downloading credential helper $HELPER_FILENAME"
BIN_PATH="/usr/local/bin"
mkdir -p "$BIN_PATH"
RELEASE_TAG="$PARAM_RELEASE_TAG"
base_url="https://github.com/docker/docker-credential-helpers/releases"
RELEASE_VERSION=$(curl -Ls --fail --retry 3 -o /dev/null -w '%{url_effective}' "$base_url/latest" | sed 's:.*/::')
if [ -n "${RELEASE_TAG}" ]; then
  RELEASE_VERSION="${RELEASE_TAG}"
fi

# Starting from v0.7.0, the release file name is changed to docker-credential-<helper-name>-<version>.<os>-<arch><variant>
# At the moment of writing, the amd64 binary does not have a variant suffix. But this might change in the future.
# https://github.com/CircleCI-Public/docker-orb/pull/156#discussion_r977920812
minor_version="$(echo "$RELEASE_VERSION" | cut -d. -f2)"
download_base_url="$base_url/download/${RELEASE_VERSION}/${HELPER_FILENAME}-${RELEASE_VERSION}"

if [ "$minor_version" -gt 6 ]; then
  DOWNLOAD_URL="$download_base_url.$platform-amd64"
  echo "Downloading from url: $DOWNLOAD_URL"
  curl -L -o "${HELPER_FILENAME}" "$DOWNLOAD_URL"
else
  DOWNLOAD_URL="$download_base_url-amd64.tar.gz"
  echo "Downloading from url: $DOWNLOAD_URL"
  curl -L -o "${HELPER_FILENAME}_archive" "$DOWNLOAD_URL"
  tar xvf "./${HELPER_FILENAME}_archive"
  rm "./${HELPER_FILENAME}_archive"
fi

chmod +x "./$HELPER_FILENAME"
$SUDO mv "./$HELPER_FILENAME" "$BIN_PATH/$HELPER_FILENAME"
"$BIN_PATH/$HELPER_FILENAME" version
