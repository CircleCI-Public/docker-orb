#!/usr/bin/env bash

DOCKER_TAGS_ARG=""

parse_tags_to_docker_arg() {
  # Set comma as the new delimiter for the scope of this function.
  local IFS="," 

  # Split tags into an array based on IFS delimiter.
  read -ra tags <<< "$PARAM_TAG"

  local docker_arg

  for tag in "${tags[@]}"; do
    if [ -z "$docker_arg" ]; then
      docker_arg="--tag=\"$PARAM_REGISTRY/$PARAM_IMAGE:$tag\""
    else
      docker_arg="$docker_arg --tag=\"$PARAM_REGISTRY/$PARAM_IMAGE:$tag\""
    fi
  done

  DOCKER_TAGS_ARG="$(eval printf '%s' $docker_arg)"
}

pull_images_from_cache() {
  local cache
  cache="$(eval printf '%s' $PARAM_CACHE_FROM)"

  printf '%s' "$cache" | sed -n 1'p' | tr ',' '\n' | while read -r image; do
    printf '%s\n' "Pulling ${image}";
    docker pull ${image} || true
  done
}

if ! parse_tags_to_docker_arg; then
  printf '%s\n' "Unable to parse provided tags."
  printf '%s\n' "Check your \"tag\" parameter or refer to the docs and try again: https://circleci.com/developer/orbs/orb/circleci/docker."
  exit 1
fi

if [ -n "$PARAM_CACHE_FROM" ]; then
  if ! pull_images_from_cache; then
    printf '%s\n' "Unable to pull images from the cache."
    printf '%s\n' "Check your \"cache_from\" parameter or refer to the docs and try again: https://circleci.com/developer/orbs/orb/circleci/docker."
    exit 1
  fi
fi

# http://mywiki.wooledge.org/BashFAQ/050#I_only_want_to_pass_options_if_the_runtime_data_needs_them
docker build \
  ${PARAM_EXTRA_BUILD_ARGS:+"$PARAM_EXTRA_BUILD_ARGS"} \
  ${PARAM_CACHE_FROM:+--cache-from="$PARAM_CACHE_FROM"} \
  "--file=$PARAM_DOCKERFILE_PATH/$PARAM_DOCKERFILE_NAME" \
  "$DOCKER_TAGS_ARG" \
  "$PARAM_DOCKER_CONTEXT"