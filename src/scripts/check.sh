#!/usr/bin/env bash

echo "$PARAM_DOCKER_PASSWORD" | docker login -u "$PARAM_DOCKER_USERNAME" --password-stdin "$PARAM_REGISTRY"