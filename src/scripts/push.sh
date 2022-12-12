#!/usr/bin/env bash

# Import "utils.sh".
eval "$SCRIPT_UTILS"
expand_env_vars_with_prefix "PARAM_"

IFS="," read -ra DOCKER_TAGS <<< "$PARAM_TAG"

image="$(eval echo "$PARAM_IMAGE")"

for docker_tag in "${DOCKER_TAGS[@]}"; do
  tag=$(eval echo "$docker_tag")

  set -x
  docker push "$PARAM_REGISTRY"/"$image":"$tag"
  set +x
done

if [ -n "$PARAM_DIGEST_PATH" ]; then
  mkdir -p "$(dirname "$PARAM_DIGEST_PATH")"
  IFS="," read -ra DOCKER_TAGS <<< "$PARAM_TAG"
  tag=$(eval echo "${DOCKER_TAGS[0]}")
  docker image inspect --format="{{index .RepoDigests 0}}" "$PARAM_REGISTRY"/"$image":"$tag" > "$PARAM_DIGEST_PATH"
fi
