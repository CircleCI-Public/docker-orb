#!/usr/bin/env bash

if [[ $EUID == 0 ]]; then SUDO=""; else SUDO="sudo"; fi

if ! command -v dockerlint 1> /dev/null 2> /dev/null; then
  if ! command -v npm 1> /dev/null 2> /dev/null; then 
    echo "npm is required to install dockerlint.";
    echo "Consider running this command with an image that has node available: https://circleci.com/developer/images/image/cimg/node"; 
    echo "Alternatively, use dockerlint's docker image: https://github.com/RedCoolBeans/dockerlint#docker-image."
    exit 1
  fi

  if [ "$PARAM_DEBUG" = true ]; then
    npm install -g dockerlint || "$SUDO" npm install -g dockerlint
  else
    npm install -g dockerlint 1> /dev/null 2> /dev/null || "$SUDO" npm install -g dockerlint 1> /dev/null 2> /dev/null
  fi
fi

if [ "$PARAM_TREAT_WARNING_AS_ERRORS" = true ]; then
  dockerlint -f "$PARAM_DOCKERFILE" -p
else
  dockerlint -f "$PARAM_DOCKERFILE"
fi