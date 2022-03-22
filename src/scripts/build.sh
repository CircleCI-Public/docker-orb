#!/usr/bin/env bash

DOCKER_TAGS_ARG=""

parse_tags_to_docker_arg() {
  # Split list of tags by comma.
  IFS="," read -ra tags <<< "$PARAM_TAG"

  for tag in "${tags[@]}"; do
    local expanded_tag
    expanded_tag="$(eval echo ${tag})"
    DOCKER_TAGS_ARG="${DOCKER_TAGS_ARG} -t cpeorbtesting/docker-orb-test:${expanded_tag}"
  done
}

pull_images_from_cache() {
  echo "$PARAM_CACHE_FROM" | sed -n 1'p' | tr ',' '\n' | while read -r image; do
    echo "Pulling ${image}";
    docker pull ${image} || true
  done
}

if ! parse_tags_to_docker_arg; then
  echo "Unable to parse provided tags."
  echo "Check your \"tag\" parameter or refer to the docs and try again: https://circleci.com/developer/orbs/orb/circleci/docker."
  exit 1
fi

if [ -z "$PARAM_CACHE_FROM" ]; then
  # The variable "DOCKER_TAGS_ARG" has to be inside a "${}".
  # If inside double-quotes, the docker command will fail.
  docker build \
    "$PARAM_EXTRA_BUILD_ARGS" \
    -f "$PARAM_DOCKERFILE_PATH"/"$PARAM_DOCKERFILE_NAME" \
    ${DOCKER_TAGS_ARG} \
    "$PARAM_DOCKER_CONTEXT"

else
  if ! pull_images_from_cache; then
    echo "Unable to pull images from the cache."
    echo "Check your \"cache_from\" parameter or refer to the docs and try again: https://circleci.com/developer/orbs/orb/circleci/docker."
    exit 1
  fi

  # The variable "DOCKER_TAGS_ARG" has to be inside a "${}".
  # If inside double-quotes, the docker command will fail.
  docker build \
    "$PARAM_EXTRA_BUILD_ARGS" \
    --cache-from "$PARAM_CACHE_FROM" \
    -f "$PARAM_DOCKERFILE_PATH"/"$PARAM_DOCKERFILE_NAME" \
    ${DOCKER_TAGS_ARG} \
    "$PARAM_DOCKER_CONTEXT"
fi