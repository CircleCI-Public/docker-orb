#!/usr/bin/env bash

IFS="," read -ra DOCKER_TAGS <<< "$PARAM_TAG"

for docker_tag in "${DOCKER_TAGS[@]}"; do
  tag=$(eval echo "$docker_tag")
  docker push "$PARAM_REGISTRY"/"$PARAM_IMAGE":"$tag"
done

if [ -n "$PARAM_DIGEST_PATH" ]; then
  mkdir -p "$(dirname "$PARAM_DIGEST_PATH")"
  IFS="," read -ra DOCKER_TAGS <<< "$PARAM_TAG"
  docker image inspect --format="{{index .RepoDigests 0}}" "$PARAM_REGISTRY"/"$PARAM_IMAGE":"${DOCKER_TAGS[0]}" > "$PARAM_DIGEST_PATH"
fi