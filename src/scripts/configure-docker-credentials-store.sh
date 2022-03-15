#!/usr/bin/env bash

HELPER_NAME="$PARAM_HELPER_NAME"

if [ -z "${PARAM_HELPER_NAME}" ]; then
  if [ -n "$(uname | grep "Darwin")" ]; then
    HELPER_NAME="osxkeychain"
  else
    HELPER_NAME="pass"
  fi
fi

if [ ! -f "$PARAM_DOCKER_CONFIG_PATH" ]; then
  echo "${PARAM_DOCKER_CONFIG_PATH} does not exist; initializing it..."
  mkdir -p $(dirname "$PARAM_DOCKER_CONFIG_PATH")
  echo "{}" > "$PARAM_DOCKER_CONFIG_PATH"
fi

cat "$PARAM_DOCKER_CONFIG_PATH" |
  jq --arg credsStore "$HELPER_NAME" '. + {credsStore: $credsStore}' \
    >/tmp/docker-config-credsstore-update.json
cat /tmp/docker-config-credsstore-update.json >"$PARAM_DOCKER_CONFIG_PATH"
rm /tmp/docker-config-credsstore-update.json
