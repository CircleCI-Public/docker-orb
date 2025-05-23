#!/usr/bin/env bash

# Import "utils.sh".
eval "$SCRIPT_UTILS"
expand_env_vars_with_prefix "PARAM_"
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

  # Set IFS to null to stop "," from breaking bash substitution
  local IFS=
  DOCKER_TAGS_ARG="$(eval echo $docker_arg)"
}

if ! parse_tags_to_docker_arg; then
  echo "Unable to parse provided tags."
  echo "Check your \"tag\" parameter or refer to the docs and try again: https://circleci.com/developer/orbs/orb/circleci/docker."
  exit 1
fi

build_args=(
  "--file=$PARAM_DOCKERFILE_PATH/$PARAM_DOCKERFILE_NAME"
)

eval 'for t in '$DOCKER_TAGS_ARG'; do build_args+=("$t"); done'

if [ -n "$EXTRA_BUILD_ARGS" ]; then
  eval 'for p in '$EXTRA_BUILD_ARGS'; do build_args+=("$p"); done'
fi

if [ -n "$PARAM_CACHE_FROM" ]; then
  cache_from=$(eval echo $PARAM_CACHE_FROM)
  for cache in $cache_from; do
    build_args+=("--cache-from=$cache")
  done
fi

if [ -n "$PARAM_CACHE_TO" ]; then
  cache_to="$(eval echo $PARAM_CACHE_TO)"

  docker buildx create --name cache --use
  docker buildx use cache
  for cache in $cache_to; do
    build_args+=("--cache-to=$cache")
  done
  build_args+=(--load)
fi

# The context must be the last argument.
build_args+=("$PARAM_DOCKER_CONTEXT")

old_ifs="$IFS"
IFS=' '

set -x
docker buildx build "${build_args[@]}"
set +x

IFS="$old_ifs"
