#!/usr/bin/env bash

# Import "utils.sh".
eval "$SCRIPT_UTILS"
expand_env_vars_with_prefix "PARAM_"

HELPER_NAME="$PARAM_HELPER_NAME"
DOCKER_CONFIG_PATH="$(eval echo ${PARAM_DOCKER_CONFIG_PATH})"

if [ -z "${HELPER_NAME}" ]; then
  if uname | grep -q "Darwin"; then
    HELPER_NAME="osxkeychain"
  else
    HELPER_NAME="pass"
  fi
fi

if [ ! -e "$DOCKER_CONFIG_PATH" ]; then
  echo "${DOCKER_CONFIG_PATH} does not exist; initializing it..."
  mkdir -p "$(dirname "$DOCKER_CONFIG_PATH")"
  echo "{}" > "$DOCKER_CONFIG_PATH"
fi

cat "$DOCKER_CONFIG_PATH" |
  jq --arg credsStore "$HELPER_NAME" '. + {credsStore: $credsStore}' \
    >/tmp/docker-config-credsstore-update.json
cat /tmp/docker-config-credsstore-update.json > "$DOCKER_CONFIG_PATH"

rm /tmp/docker-config-credsstore-update.json
