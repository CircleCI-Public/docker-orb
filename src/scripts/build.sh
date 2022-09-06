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

build_args=(
  "--file=$PARAM_DOCKERFILE_PATH/$PARAM_DOCKERFILE_NAME"
  "$DOCKER_TAGS_ARG"
)

if [ -n "$PARAM_EXTRA_BUILD_ARGS" ]; then
  extra_build_args="$(eval echo "$PARAM_EXTRA_BUILD_ARGS")"
  build_args+=("$extra_build_args")
fi

if [ -n "$PARAM_CACHE_FROM" ]; then
  cache_from="$(eval echo $PARAM_CACHE_FROM)"

  while read -r image; do
    build_args+=("--cache-from=${image}")
  done <<< "$(echo "$cache_from" | sed -n 1'p' | tr ',' '\n')"
fi

if [ "$PARAM_USE_BUILDKIT" -eq 1 ]; then
  build_args+=("--progress=plain")
fi

# The context must be the last argument.
build_args+=("$PARAM_DOCKER_CONTEXT")

old_ifs="$IFS"
IFS=' '

set -x
docker build ${build_args[*]}
set +x

IFS="$old_ifs"
