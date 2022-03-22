#!/usr/bin/env bash

DOCKER_TAGS_ARG=""

parse_tags_to_docker_arg() {
  # Split list of tags by comma.
  IFS="," read -ra DOCKER_TAGS <<< "$PARAM_TAG"

  for tag in "${DOCKER_TAGS[@]}"; do
    local expanded_tag="$(eval echo ${tag})"
    DOCKER_TAGS_ARG="${DOCKER_TAGS_ARG} -t cpeorbtesting/docker-orb-test:${EXPANDED_TAG}"
  done
}

pull_images_from_cache() {
  echo "$PARAM_CACHE_FROM" | sed -n 1'p' | tr ',' '\n' | while read -r image; do
    echo "Pulling ${image}";
    docker pull ${image} || true
  done
}

parse_tags_to_docker_arg

if [ -z "$PARAM_CACHE_FROM" ]; then
  # The variable "DOCKER_TAGS_ARG" has to be inside a "${}".
  # If inside double-quotes, the docker command will fail.
  docker build \
    "$PARAM_EXTRA_BUILD_ARGS" \
    -f "$PARAM_DOCKERFILE_PATH"/"$PARAM_DOCKERFILE_NAME" \ 
    ${DOCKER_TAGS_ARG} \
    "$PARAM_DOCKER_CONTEXT"

else
  pull_images_from_cache

  # The variable "DOCKER_TAGS_ARG" has to be inside a "${}".
  # If inside double-quotes, the docker command will fail.
  docker build \
    "$PARAM_EXTRA_BUILD_ARGS" \
    --cache-from "$PARAM_CACHE_FROM" \
    -f "$PARAM_DOCKERFILE_PATH"/"$PARAM_DOCKERFILE_NAME" \
    ${DOCKER_TAGS_ARG} \
    "$PARAM_DOCKER_CONTEXT"
fi