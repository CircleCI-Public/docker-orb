#!/usr/bin/env bash

# Import "utils.sh".
eval "$SCRIPT_UTILS"
expand_env_vars_with_prefix "PARAM_"

echo "$PARAM_IMAGES" | sed -n 1'p' | tr ',' '\n' | while read -r image; do
  echo "Pulling ${image}";

  if [ "$PARAM_IGNORE_DOCKER_PULL_ERROR" -eq 1 ]; then
    docker pull "${image}" || true;
  else
    docker pull "${image}";
  fi
done
