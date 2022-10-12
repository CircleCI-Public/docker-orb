#!/usr/bin/env bash

IFS="," read -ra DOCKER_TAGS <<< "$PARAM_TAG"

image="$(eval echo "$PARAM_IMAGE")"
registry="$(eval echo "$PARAM_REGISTRY")"

for docker_tag in "${DOCKER_TAGS[@]}"; do
  tag=$(eval echo "$docker_tag")

  set -x
  docker push "$registry"/"$image":"$tag"
  set +x
done

if [ -n "$PARAM_DIGEST_PATH" ]; then
  mkdir -p "$(dirname "$PARAM_DIGEST_PATH")"
  IFS="," read -ra DOCKER_TAGS <<< "$PARAM_TAG"
  tag=$(eval echo "${DOCKER_TAGS[0]}")
  docker image inspect --format="{{index .RepoDigests 0}}" "$registry"/"$image":"$tag" > "$PARAM_DIGEST_PATH"
fi
