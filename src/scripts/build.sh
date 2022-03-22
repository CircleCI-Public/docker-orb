#!/usr/bin/env bash

if [ -z "$PARAM_CACHE_FROM" ]; then
  docker_tag_args=""

  IFS="," read -ra DOCKER_TAGS <<< "$PARAM_TAG"

  for tag in "${DOCKER_TAGS[@]}"; do
    eval_tag="$(eval echo ${tag})"
    docker_tag_args="${docker_tag_args} -t cpeorbtesting/docker-orb-test:${eval_tag}"
  done

  if [ -z "$PARAM_EXTRA_BUILD_ARGS" ]; then
    COMMAND="docker build -f ${PARAM_DOCKERFILE_PATH}/${PARAM_DOCKERFILE_NAME} ${docker_tag_args} ${PARAM_DOCKER_CONTEXT}"
    echo "Running: ${COMMAND}"
    
    docker build -f "$PARAM_DOCKERFILE_PATH"/"$PARAM_DOCKERFILE_NAME" ${docker_tag_args} "$PARAM_DOCKER_CONTEXT"
  else
    echo "I'm the else for extra args"
    # COMMAND="docker build ${PARAM_EXTRA_BUILD_ARGS} -f ${PARAM_DOCKERFILE_PATH}/${PARAM_DOCKERFILE_NAME} ${docker_tag_args} ${PARAM_DOCKER_CONTEXT}"
    # echo "Running: ${COMMAND}"

    # docker build "$PARAM_EXTRA_BUILD_ARGS" -f "$PARAM_DOCKERFILE_PATH"/"$PARAM_DOCKERFILE_NAME" "$docker_tag_args" "$PARAM_DOCKER_CONTEXT"
  fi

else
    echo "I'm the else for cache"
  # echo "$PARAM_CACHE_FROM" | sed -n 1'p' | tr ',' '\n' | while read -r image; do
  #   echo "Pulling ${image}";
  #   docker pull ${image} || true
  # done

  # docker_tag_args=""

  # IFS="," read -ra DOCKER_TAGS <<< "$PARAM_TAG"

  # for tag in "${DOCKER_TAGS[@]}"; do
  #   docker_tag_args="${docker_tag_args} -t ${PARAM_REGISTRY}/${PARAM_IMAGE_NAME}:${tag}"
  # done

  # docker build "$PARAM_EXTRA_BUILD_ARGS" "$PARAM_EXTRA_BUILD_ARGS" --cache-from "$PARAM_CACHE_FROM" \
  #   -f "$PARAM_DOCKERFILE_PATH"/"$PARAM_DOCKERFILE_NAME" \
  #   $docker_tag_args \
  #   "$PARAM_DOCKER_CONTEXT"
fi