#!/usr/bin/env bash

# Import "utils.sh".
eval "$SCRIPT_UTILS"
expand_env_vars_with_prefix "PARAM_"

echo "${!PARAM_DOCKER_PASSWORD}" | docker login -u "${!PARAM_DOCKER_USERNAME}" --password-stdin "$PARAM_REGISTRY"
