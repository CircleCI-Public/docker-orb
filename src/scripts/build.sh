#!/usr/bin/env bash

DOCKER_TAGS_ARG=""

parse_tags_to_docker_arg() {
  # Backup original IFS and set comma as the new delimiter.
  readonly old_ifs
  old_ifs="$IFS"
  IFS="," 

  # Read the split words into an array based on comma delimiter and rollback IFS.
  read -ra tags <<< "$PARAM_TAG"
  IFS="$old_ifs"

  local docker_arg

  for tag in "${tags[@]}"; do
    if [ -z "$docker_arg" ]; then
      docker_arg="--tag=\"$PARAM_REGISTRY/$PARAM_IMAGE:$tag\""
    else
      docker_arg="$docker_arg --tag=\"$PARAM_REGISTRY/$PARAM_IMAGE:$tag\""
    fi
  done

  DOCKER_TAGS_ARG="$(eval echo $docker_arg)"
}

pull_images_from_cache() {
  local cache
  cache="$(eval echo $PARAM_CACHE_FROM)"

  echo "$cache" | sed -n 1'p' | tr ',' '\n' | while read -r image; do
    echo "Pulling ${image}";
    docker pull ${image} || true
  done
}

if ! parse_tags_to_docker_arg; then
  echo "Unable to parse provided tags."
  echo "Check your \"tag\" parameter or refer to the docs and try again: https://circleci.com/developer/orbs/orb/circleci/docker."
  exit 1
fi

if [ -n "$PARAM_CACHE_FROM" ]; then
  if ! pull_images_from_cache; then
    echo "Unable to pull images from the cache."
    echo "Check your \"cache_from\" parameter or refer to the docs and try again: https://circleci.com/developer/orbs/orb/circleci/docker."
    exit 1
  fi
fi

# http://mywiki.wooledge.org/BashFAQ/050#I_only_want_to_pass_options_if_the_runtime_data_needs_them
docker build \
  ${PARAM_EXTRA_BUILD_ARGS:+"$PARAM_EXTRA_BUILD_ARGS"} \
  ${PARAM_CACHE_FROM:+--cache_from="$PARAM_CACHE_FROM"} \
  "--file=$PARAM_DOCKERFILE_PATH/$PARAM_DOCKERFILE_NAME" \
  "$DOCKER_TAGS_ARG" \
  "$PARAM_DOCKER_CONTEXT"