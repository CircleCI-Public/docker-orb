#!/usr/bin/env bash

# Import "utils.sh".
eval "$SCRIPT_UTILS"
expand_env_vars_with_prefix "PARAM_"

retries="${PARAM_RETRIES:-3}"
attempt=1
max_attempts=$((retries + 1))
exit_code=1

while [ "$attempt" -le "$max_attempts" ]; do
  echo "Attempt ${attempt}/${max_attempts}: docker login"
  if ( set -x; echo "${!PARAM_DOCKER_PASSWORD}" | docker login -u "${!PARAM_DOCKER_USERNAME}" --password-stdin "$PARAM_REGISTRY" ); then
    exit 0
  fi
  exit_code=$?
  echo "docker login failed with exit code ${exit_code}"

  if [ "$attempt" -lt "$max_attempts" ]; then
    echo "Retrying in ${attempt} second(s)..."
    sleep "$attempt"
  fi
  attempt=$((attempt + 1))
done

exit "$exit_code"
