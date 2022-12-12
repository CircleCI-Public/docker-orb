#!/usr/bin/env bash

# Import "utils.sh".
eval "$SCRIPT_UTILS"
expand_env_vars_with_prefix "PARAM_"

if [ "$PARAM_REGISTRY" != "docker.io" ]; then
  echo "Registry is not set to Docker Hub. Exiting"
  exit 1
fi

USERNAME=${!PARAM_DOCKER_USERNAME}
PASSWORD=${!PARAM_DOCKER_PASSWORD}
IMAGE="$(eval echo "$PARAM_IMAGE")"

DESCRIPTION="$PARAM_PATH/$PARAM_README"
PAYLOAD="username=$USERNAME&password=$PASSWORD"
JWT=$(curl -s -d "$PAYLOAD" https://hub.docker.com/v2/users/login/ | jq -r .token)
HEADER="Authorization: JWT $JWT"
URL="https://hub.docker.com/v2/repositories/$IMAGE/"
STATUS=$(curl -s -o /dev/null -w '%{http_code}' -X PATCH -H "$HEADER" -H 'Content-type: application/json' --data "{\"full_description\": $(jq -Rs '.' $DESCRIPTION)}" $URL)

if [ $STATUS -ne 200 ]; then
  echo "Could not update image description"
  echo "Error code: $STATUS"
  exit 1
fi
