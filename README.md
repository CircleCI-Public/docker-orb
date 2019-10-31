# Docker Orb [![CircleCI Build Status](https://circleci.com/gh/CircleCI-Public/docker-orb.svg?style=shield "CircleCI Build Status")](https://circleci.com/gh/CircleCI-Public/docker-orb) [![CircleCI Orb Version](https://img.shields.io/badge/endpoint.svg?url=https://badges.circleci.io/orb/circleci/docker)](https://circleci.com/orbs/registry/orb/circleci/docker) [![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/CircleCI-Public/docker-orb/master/LICENSE) [![CircleCI Community](https://img.shields.io/badge/community-CircleCI%20Discuss-343434.svg)](https://discuss.circleci.com/c/ecosystem/orbs)

Quickly and easily install Docker, `dockerize`, and `docker-compose` in any CircleCI job. Install/use various other Docker-related tools on CircleCI. Build Docker images and deploy them to any registry.

Besides providing commands to easily install Docker, `docker-compose`, and `dockerize`, this orb contains the commands/jobs/executors/examples previously published to the [`docker-publish` orb](https://circleci.com/orbs/registry/orb/circleci/docker-publish).

## Usage

_For full usage guidelines, see the [orb registry listing](http://circleci.com/orbs/registry/orb/circleci/docker)._

## Orb Source

# This code is licensed from CircleCI to the user under the MIT license. See
# https://circleci.com/orbs/registry/licensing for details.
commands:
  build:
    description: |
      Build and tag a Docker image
    parameters:
      debug:
        default: false
        description: |
          Extra output for orb developers
        type: boolean
      dockerfile:
        default: Dockerfile
        description: Name of dockerfile to use, defaults to Dockerfile
        type: string
      extra_build_args:
        default: ""
        description: |
          Extra flags to pass to docker build. For examples, see https://docs.docker.com/engine/reference/commandline/build
        type: string
      image:
        description: Name of image to build
        type: string
      lint-dockerfile:
        default: false
        description: |
          Lint Dockerfile before building?
        type: boolean
      path:
        default: .
        description: |
          Path to the directory containing your Dockerfile and build context, defaults to . (working directory)
        type: string
      registry:
        default: docker.io
        description: |
          Name of registry to use, defaults to docker.io
        type: string
      step-name:
        default: Docker build
        description: Specify a custom step name for this command, if desired
        type: string
      tag:
        default: $CIRCLE_SHA1
        description: Image tag, defaults to the value of $CIRCLE_SHA1
        type: string
      treat-warnings-as-errors:
        default: false
        description: |
          If linting Dockerfile, treat linting warnings as errors (would trigger an exist code and fail the CircleCI job)?
        type: boolean
    steps:
    - when:
        condition: <<parameters.lint-dockerfile>>
        steps:
        - dockerlint:
            debug: <<parameters.debug>>
            dockerfile: <<parameters.path>>/<<parameters.dockerfile>>
            treat-warnings-as-errors: <<parameters.treat-warnings-as-errors>>
    - run:
        command: |
          docker build \
            <<#parameters.extra_build_args>><<parameters.extra_build_args>><</parameters.extra_build_args>> \
            -f <<parameters.path>>/<<parameters.dockerfile>> -t \
            <<parameters.registry>>/<< parameters.image>>:<<parameters.tag>> \
            <<parameters.path>>
        name: <<parameters.step-name>>
  check:
    description: |
      Sanity check to make sure you can build a Docker image. Check that Docker username and password environment variables are set, then run docker login to ensure that you can push the built image
    parameters:
      docker-password:
        default: DOCKER_PASSWORD
        description: |
          Name of environment variable storing your Docker password
        type: env_var_name
      docker-username:
        default: DOCKER_LOGIN
        description: |
          Name of environment variable storing your Docker username
        type: env_var_name
      registry:
        default: docker.io
        description: Name of registry to use, defaults to docker.io
        type: string
    steps:
    - orb-tools/check-env-var-param:
        param: <<parameters.docker-username>>
    - orb-tools/check-env-var-param:
        param: <<parameters.docker-password>>
    - run:
        command: |
          docker login \
            -u "$<<parameters.docker-username>>" -p "$<<parameters.docker-password>>" \
            <<parameters.registry>>
        name: Docker login
  dockerlint:
    description: |
      Install hadolint and lint a given Dockerfile
    parameters:
      debug:
        default: false
        description: |
          Extra output for orb developers
        type: boolean
      dockerfile:
        default: Dockerfile
        description: |
          Relative or absolute path, including name, to Dockerfile to be linted, e.g., `~/project/app/deploy.Dockerfile`, defaults to a Dockerfile named `Dockerfile` in the working directory
        type: string
      treat-warnings-as-errors:
        default: false
        description: |
          Treat linting warnings as errors (would trigger an exist code and fail the CircleCI job)?
        type: boolean
      version:
        default: latest
        description: |
          Version of hadolint to install, defaults to the latest release: https://github.com/hadolint/hadolint/releases
        type: string
    steps:
    - run:
        command: |
          if [[ $EUID == 0 ]]; then export SUDO=""; else export SUDO="sudo"; fi

          npm install -g dockerlint<<^parameters.debug>> > /dev/null 2>&1<</parameters.debug>> || \
            $SUDO npm install -g dockerlint<<^parameters.debug>> > /dev/null 2>&1<</parameters.debug>>

          dockerlint<<#parameters.treat-warnings-as-errors>> -p<</parameters.treat-warnings-as-errors>> \
            <<parameters.dockerfile>>
        name: Lint Dockerfile at <<parameters.dockerfile>>
  install-docker:
    description: |
      Install the Docker CLI. Supports stable versions `v17.06.0-ce` and newer, on all platforms (Linux, macOS). Requirements: curl, grep, jq, tar
    parameters:
      install-dir:
        default: /usr/local/bin
        description: |
          Directory in which to install Docker binaries
        type: string
      version:
        default: latest
        description: |
          Version of Docker to install, defaults to the latest stable release. If specifying a version other than latest, provide a full release tag, as listed at https://api.github.com/repos/docker/cli/tags, e.g., `v18.09.4`.
        type: string
    steps:
    - run:
        command: |
          if [[ $EUID == 0 ]]; then export SUDO=""; else export SUDO="sudo"; fi

          # grab Docker version
          if [[ <<parameters.version>> == "latest" ]]; then
            # extract latest version from GitHub releases API
            declare -i INDEX=0

            while :
            do
              INDEX_VERSION=$(curl --silent --show-error --location --fail --retry 3 \
                https://api.github.com/repos/docker/cli/tags | \
                jq --argjson index "$INDEX" '.[$index].name')

              # filter out betas & release candidates
              if [[ $(echo "$INDEX_VERSION" | grep -v beta | grep -v rc) ]]; then

                # can't use substring expression < 0 on macOS
                DOCKER_VERSION="${INDEX_VERSION:1:$((${#INDEX_VERSION} - 1 - 1))}"

                echo "Latest stable version of Docker is $DOCKER_VERSION"
                break
              else
                INDEX=INDEX+1
              fi
            done
          else
            DOCKER_VERSION=<<parameters.version>>
            echo "Selected version of Docker is $DOCKER_VERSION"
          fi

          # check if Docker needs to be installed
          DOCKER_VERSION_NUMBER="${DOCKER_VERSION:1}"

          if command -v docker >> /dev/null 2>&1; then
            if docker --version | grep "$DOCKER_VERSION_NUMBER" >> /dev/null 2>&1; then
              echo "Docker $DOCKER_VERSION is already installed"
              exit 0
            else
              echo "A different version of Docker is installed ($(docker --version)); removing it"
              $SUDO rm -f $(command -v docker)
            fi
          fi

          # get binary download URL for specified version
          if uname -a | grep Darwin >> /dev/null 2>&1; then
            PLATFORM=mac
          else
            PLATFORM=linux
          fi

          DOCKER_BINARY_URL="https://download.docker.com/$PLATFORM/static/stable/x86_64/docker-$DOCKER_VERSION_NUMBER.tgz"

          # download binary tarball
          curl --output docker.tgz \
            --silent --show-error --location --fail --retry 3 \
            "$DOCKER_BINARY_URL"

          tar xf docker.tgz && rm -f docker.tgz

          # install Docker binaries
          BINARIES=$(ls docker)
          $SUDO mv docker/* <<parameters.install-dir>>
          $SUDO rm -rf docker

          for binary in $BINARIES
          do
            $SUDO chmod +x "<<parameters.install-dir>>/$binary"
          done

          # verify version
          echo "$(docker --version) has been installed to $(which docker)"
        name: Install Docker CLI
  install-docker-compose:
    description: |
      Install the `docker-compose` CLI. Supports stable versions. Requirements: curl, Docker, grep, jq, sha256sum,
    parameters:
      install-dir:
        default: /usr/local/bin
        description: |
          Directory in which to install `docker-compose`
        type: string
      version:
        default: latest
        description: |
          Version of `docker-compose` to install, defaults to the latest stable release. If specifying a version other than latest, provide a full release tag, as listed at https://github.com/docker/compose/releases or https://api.github.com/repos/docker/compose/releases, e.g., `1.23.1`.
        type: string
    steps:
    - run:
        command: |
          if [[ $EUID == 0 ]]; then export SUDO=""; else export SUDO="sudo"; fi

          # grab docker-compose version
          if [[ <<parameters.version>> == "latest" ]]; then
            # extract latest version from GitHub releases API
            declare -i INDEX=0

            while :
            do
              INDEX_VERSION=$(curl --silent --show-error --location --fail --retry 3 \
                https://api.github.com/repos/docker/compose/releases | \
                jq --argjson index "$INDEX" '.[$index].name')

              # filter out betas & release candidates
              if [[ $(echo "$INDEX_VERSION" | grep -v beta | grep -v rc) ]]; then

                # strip leading/trailing quotes
                # can't use substring expression < 0 on macOS
                DOCKER_COMPOSE_VERSION="${INDEX_VERSION:1:$((${#INDEX_VERSION} - 1 - 1))}"

                echo "Latest stable version of docker-compose is $DOCKER_COMPOSE_VERSION"
                break
              else
                INDEX=INDEX+1
              fi
            done
          else
            DOCKER_COMPOSE_VERSION=<<parameters.version>>
            echo "Selected version of docker-compose is $DOCKER_COMPOSE_VERSION"
          fi

          # check if docker-compose needs to be installed
          if command -v docker-compose >> /dev/null 2>&1; then
            if docker-compose --version | grep "$DOCKER_COMPOSE_VERSION" >> /dev/null 2>&1; then
              echo "docker-compose $DOCKER_COMPOSE_VERSION is already installed"
              exit 0
            else
              echo "A different version of docker-compose is installed ($(docker-compose --version)); removing it"
              $SUDO rm -f $(command -v docker-compose)
            fi
          fi

          # docker-compose binary won't run on alpine, install via pip
          if cat /etc/issue | grep Alpine >> /dev/null 2>&1; then
            $SUDO apk add gcc libc-dev libffi-dev openssl-dev make python-dev py-pip
            $SUDO pip install docker-compose=="$DOCKER_COMPOSE_VERSION"
          else
            # get binary/shasum download URL for specified version
            if uname -a | grep Darwin >> /dev/null 2>&1; then
              PLATFORM=Darwin
              HOMEBREW_NO_AUTO_UPDATE=1 brew install coreutils
            else
              PLATFORM=Linux
            fi

            DOCKER_COMPOSE_BINARY_URL="https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-$PLATFORM-x86_64"

            DOCKER_COMPOSE_SHASUM_URL="$DOCKER_COMPOSE_BINARY_URL.sha256"

            # download binary and shasum
            curl -O \
              --silent --show-error --location --fail --retry 3 \
              "$DOCKER_COMPOSE_BINARY_URL"

            # just try doing it this way since some of the actual checksum files are malformatted anyway
            DOCKER_COMPOSE_RELEASE_BODY=$(curl \
              --silent --show-error --location --fail --retry 3 \
              "https://api.github.com/repos/docker/compose/releases/tags/$DOCKER_COMPOSE_VERSION" | \
              jq '.body')

            if [[ $(echo $DOCKER_COMPOSE_RELEASE_BODY | \
              grep -o -e "\`................................................................\` | \`docker-compose-$PLATFORM-x86_64") ]]; then

              SHASUM_STRING=$(echo $DOCKER_COMPOSE_RELEASE_BODY | \
                grep -o -e "\`................................................................\` | \`docker-compose-$PLATFORM-x86_64" | \
                sed -E 's/`|\|//g')
            elif [[ $(echo $DOCKER_COMPOSE_RELEASE_BODY | \
              grep -o -e "\`docker-compose-$PLATFORM-x86_64\` | \`................................................................") ]]; then

              SHASUM_STRING=$(echo $DOCKER_COMPOSE_RELEASE_BODY | \
                grep -o -e "\`docker-compose-$PLATFORM-x86_64\` | \`................................................................" | \
                sed -E 's/`|\|//g')
            fi

            SHASUM=$(echo "$SHASUM_STRING" | sed -E "s/docker-compose-$PLATFORM-x86_64| //g")

            # verify shasum
            echo "$SHASUM  docker-compose-$PLATFORM-x86_64" | sha256sum -c

            # install docker-compose
            $SUDO mv "docker-compose-$PLATFORM-x86_64" <<parameters.install-dir>>/docker-compose
            $SUDO chmod +x <<parameters.install-dir>>/docker-compose
          fi

          # verify version
          echo "$(docker-compose --version) has been installed to $(which docker-compose)"
        name: Install docker-compose
  install-docker-tools:
    description: |
      Install commonly used Docker tools (Docker, `docker-compose`, `dockerize`). Requirements: curl, grep, jq, sha256sum, tar
    parameters:
      debug:
        default: false
        description: |
          Extra output for orb developers
        type: boolean
      docker-compose-install-dir:
        default: /usr/local/bin
        description: |
          Directory in which to install `docker-compose`
        type: string
      docker-compose-version:
        default: latest
        description: |
          Version of `docker-compose` to install, defaults to the latest stable release. If specifying a version other than latest, provide a full release tag, as listed at https://github.com/docker/compose/releases or https://api.github.com/repos/docker/compose/releases, e.g., `1.23.1`.
        type: string
      docker-install-dir:
        default: /usr/local/bin
        description: |
          Directory in which to install Docker binaries
        type: string
      docker-version:
        default: latest
        description: |
          Version of Docker to install, defaults to the latest stable release. If specifying a version other than latest, provide a full release tag, as listed at https://api.github.com/repos/docker/cli/tags, e.g., `v18.09.4`.
        type: string
      dockerize-install-dir:
        default: /usr/local/bin
        description: |
          Directory in which to install `dockerize`
        type: string
      dockerize-version:
        default: latest
        description: |
          Version of `dockerize` to install, defaults to the latest release. If specifying a version other than latest, provide a full release tag, as listed at https://github.com/jwilder/dockerize/releases, e.g., `v0.5.0`. Supports versions `v.0.4.0` and later.
        type: string
      goss-install-dir:
        default: /usr/local/bin
        description: |
          Directory in which to install Goss and `dgoss`
        type: string
      goss-version:
        default: latest
        description: |
          Version of Goss and `dgoss` to install, defaults to the latest stable release. If specifying a version other than latest, provide a full release tag, as listed at https://github.com/aelsabbahy/goss/releases or https://api.github.com/repos/aelsabbahy/goss/releases, e.g., `v0.3.7`.
        type: string
      install-docker:
        default: true
        description: |
          Install the Docker CLI? Supports stable versions `v17.06.0-ce` and newer, on all platforms (Linux, macOS). Requirements: curl, grep, jq, tar
        type: boolean
      install-docker-compose:
        default: true
        description: |
          Install the `docker-compose` CLI? Supports stable versions. Requirements: curl, Docker, grep, jq, sha256sum
        type: boolean
      install-dockerize:
        default: true
        description: |
          Install `dockerize`? Supports versions `v.0.4.0` and later. Requirements: curl, Docker
        type: boolean
      install-goss-dgoss:
        default: true
        description: |
          Install Goss and `dgoss`?
        type: boolean
    steps:
    - when:
        condition: <<parameters.install-docker>>
        steps:
        - install-docker:
            install-dir: <<parameters.docker-install-dir>>
            version: <<parameters.docker-version>>
    - when:
        condition: <<parameters.install-docker-compose>>
        steps:
        - install-docker-compose:
            install-dir: <<parameters.docker-compose-install-dir>>
            version: <<parameters.docker-compose-version>>
    - when:
        condition: <<parameters.install-dockerize>>
        steps:
        - install-dockerize:
            install-dir: <<parameters.dockerize-install-dir>>
            version: <<parameters.dockerize-version>>
    - when:
        condition: <<parameters.install-goss-dgoss>>
        steps:
        - install-goss:
            debug: <<parameters.debug>>
            install-dir: <<parameters.goss-install-dir>>
            version: <<parameters.goss-version>>
  install-dockerize:
    description: |
      Install `dockerize`. Supports versions `v.0.4.0` and later. Requirements: curl, Docker
    parameters:
      install-dir:
        default: /usr/local/bin
        description: |
          Directory in which to install `dockerize`
        type: string
      version:
        default: latest
        description: |
          Version of `dockerize` to install, defaults to the latest release. If specifying a version other than latest, provide a full release tag, as listed at https://github.com/jwilder/dockerize/releases, e.g., `v0.5.0`. Supports versions `v.0.4.0` and later.
        type: string
    steps:
    - run:
        command: |
          if [[ $EUID == 0 ]]; then export SUDO=""; else export SUDO="sudo"; fi

          # grab dockerize version
          if [[ <<parameters.version>> == "latest" ]]; then
            # extract latest version from GitHub releases API
            DOCKERIZE_VERSION=$(curl \
              --silent --show-error --location --fail --retry 3 \
              https://api.github.com/repos/jwilder/dockerize/releases/latest | \
              jq '.tag_name' | sed -E 's/"//g')
          else
            DOCKERIZE_VERSION=<<parameters.version>>
            echo "Selected version of dockerize is $DOCKERIZE_VERSION"
          fi

          # check if dockerize needs to be installed
          if command -v dockerize >> /dev/null 2>&1; then
            if dockerize --version | grep "$DOCKERIZE_VERSION" >> /dev/null 2>&1; then
              echo "dockerize $DOCKERIZE_VERSION is already installed"
              exit 0
            else
              echo "A different version of dockerize is installed ($(dockerize --version)); removing it"
              $SUDO rm -f $(command -v dockerize)
            fi
          fi

          # construct binary download URL
          if uname -a | grep Darwin >> /dev/null 2>&1; then
            PLATFORM=darwin-amd64
          elif cat /etc/issue | grep Alpine >> /dev/null 2>&1; then
            PLATFORM=alpine-linux-amd64
            apk add --no-cache openssl
          else
            PLATFORM=linux-amd64
          fi

          DOCKERIZE_BINARY_URL="https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-$PLATFORM-$DOCKERIZE_VERSION.tar.gz"

          # download & install binary
          curl -O --silent --show-error --location --fail --retry 3 \
          "$DOCKERIZE_BINARY_URL"

          tar xf "dockerize-$PLATFORM-$DOCKERIZE_VERSION.tar.gz"
          rm -f "dockerize-$PLATFORM-$DOCKERIZE_VERSION.tar.gz"

          $SUDO mv dockerize <<parameters.install-dir>>
          $SUDO chmod +x <<parameters.install-dir>>/dockerize

          # verify version
          echo "dockerize $(dockerize --version) has been installed to $(which dockerize)"
        name: Install dockerize
  install-goss:
    description: |
      Install the Goss and `dgoss` CLI tools, commonly using for testing Docker containers. Only compatible with Linux-based execution environments. More info: https://github.com/aelsabbahy/goss https://github.com/aelsabbahy/goss/tree/master/extras/dgoss
    parameters:
      debug:
        default: false
        description: |
          Extra output for orb developers
        type: boolean
      install-dir:
        default: /usr/local/bin
        description: |
          Directory in which to install Goss and `dgoss`
        type: string
      version:
        default: latest
        description: |
          Version of Goss and `dgoss` to install, defaults to the latest stable release. If specifying a version other than latest, provide a full release tag, as listed at https://github.com/aelsabbahy/goss/releases or https://api.github.com/repos/aelsabbahy/goss/releases, e.g., `v0.3.7`. Supports versions `v0.3.1` and newer.
        type: string
    steps:
    - run:
        command: |
          if [[ $EUID == 0 ]]; then export SUDO=""; else export SUDO="sudo"; fi

          # determine specified version
          if [[ <<parameters.version>> == latest ]]; then
            VERSION=$(curl --silent --show-error \
              --location --fail --retry 3 \
              https://api.github.com/repos/aelsabbahy/goss/releases/latest | \
              grep tag_name | cut -d '"' -f 4)

            echo "Latest version of Goss is $VERSION"
          else
            VERSION=<<parameters.version>>

            echo "Selected version of Goss is $VERSION"
          fi

          # installation check
          if command -v goss<<^parameters.debug>> > /dev/null 2>&1<</parameters.debug>>; then

            if goss --version | \
              grep "$VERSION"<<^parameters.debug>> > /dev/null 2>&1<</parameters.debug>> && \
              command -v dgoss<<^parameters.debug>> > /dev/null 2>&1<</parameters.debug>>; then

              echo "Goss and dgoss $VERSION are already installed"
              exit 0
            else
              echo "A different version of Goss is installed ($(goss --version)); removing it"

              $SUDO rm -rf "$(command -v goss)"<<^parameters.debug>> > /dev/null 2>&1<</parameters.debug>>
              $SUDO rm -rf "$(command -v dgoss)"<<^parameters.debug>> > /dev/null 2>&1<</parameters.debug>>
            fi
          fi

          # download/install
          # goss
          curl -O --silent --show-error --location --fail --retry 3 \
            "https://github.com/aelsabbahy/goss/releases/download/$VERSION/goss-linux-amd64"

          $SUDO mv goss-linux-amd64 <<parameters.install-dir>>/goss
          $SUDO chmod +rx /usr/local/bin/goss

          # test/verify goss
          if goss --version | grep "$VERSION"<<^parameters.debug>> > /dev/null 2>&1<</parameters.debug>>; then
            echo "$(goss --version) has been installed to $(command -v goss)"
          else
            echo "Something went wrong; the specified version of Goss could not be installed"
            exit 1
          fi

          # dgoss
          DGOSS_URL="https://raw.githubusercontent.com/aelsabbahy/goss/$VERSION/extras/dgoss/dgoss"
          if curl<<^parameters.debug>> --output /dev/null<</parameters.debug>> --silent --head --fail "$DGOSS_URL"; then
            curl -O --silent --show-error --location --fail --retry 3 "$DGOSS_URL"

            $SUDO mv dgoss <<parameters.install-dir>>
            $SUDO chmod +rx /usr/local/bin/dgoss

            # test/verify dgoss
            if command -v dgoss<<^parameters.debug>> > /dev/null 2>&1<</parameters.debug>>; then
              echo "dgoss has been installed to $(command -v dgoss)"
            else
              echo "Something went wrong; the dgoss wrapper for the specified version of Goss could not be installed"
              exit 1
            fi
          else
            echo "No dgoss wrapper found for the selected version of Goss ($(echo $VERSION))..."
            echo "Goss installation will proceed, but to use dgoss, please try again with a newer version"
          fi
        name: Install Goss and dgoss
  push:
    description: Push a Docker image to a registry
    parameters:
      image:
        description: Name of image to push
        type: string
      registry:
        default: docker.io
        description: |
          Name of registry to use, defaults to docker.io
        type: string
      step-name:
        default: Docker push
        description: Specify a custom step name for this command, if desired
        type: string
      tag:
        default: $CIRCLE_SHA1
        description: Image tag, defaults to the value of $CIRCLE_SHA1
        type: string
    steps:
    - deploy:
        command: |
          docker push <<parameters.registry>>/<< parameters.image>>:<<parameters.tag>>
        name: <<parameters.step-name>>
description: |
  Quickly and easily install/configure/use Docker, `dockerize`, and `docker-compose` in any CircleCI job. See this orb's source: https://github.com/CircleCI-Public/docker-orb
examples:
  build-without-publishing:
    description: |
      Build, but don't publish, an image using the publish job
    usage:
      orbs:
        docker: circleci/docker@x.y.z
      version: 2.1
      workflows:
        build-docker-image-only:
          jobs:
          - docker/publish:
              deploy: false
              image: $CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME
  build-without-publishing-commands:
    description: |
      Build, but don't publish, an image using the check and build commands
    usage:
      jobs:
        check-and-build-only:
          executor: docker/machine
          steps:
          - checkout
          - docker/check
          - docker/build:
              image: $CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME
      orbs:
        docker: circleci/docker@x.y.z
      version: 2.1
      workflows:
        build-docker-image-only:
          jobs:
          - check-and-build-only
  custom-name-tag-executor:
    description: |
      Build and Deploy docker image with a custom name and tag, using a non-default executor with custom parameter values (note: when using a Docker-based excecutor, the `use-remote-docker` parameter must be set to true in order for Docker commands to run successfully).
    usage:
      orbs:
        docker: circleci/docker@x.y.z
      version: 2.1
      workflows:
        build-and-publish-docker-image:
          jobs:
          - docker/publish:
              executor:
                image: circleci/node
                name: docker/docker
                tag: boron-browsers
              image: my/image
              tag: my-tag
              use-remote-docker: true
  custom-registry-and-dockerfile:
    description: |
      Build and deploy a Docker image with a non-standard Dockerfile to a custom registry
    usage:
      orbs:
        docker: circleci/docker@x.y.z
      version: 2.1
      workflows:
        build-and-publish-docker-image:
          jobs:
          - docker/publish:
              dockerfile: my.Dockerfile
              image: $CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME
              path: path/to/Docker/build/context
              registry: my.docker.registry
  hadolint:
    description: |
      Use hadolint to lint a Dockerfile
    usage:
      orbs:
        docker: circleci/docker@x.y.z
      version: 2.1
      workflows:
        lint:
          jobs:
          - docker/hadolint:
              dockerfile: path/to/Dockerfile
              ignore-rules: DL4005,DL3008
              trusted-registries: docker.io,my-company.com:5000
  install-docker-tools:
    description: |
      Quickly install Docker, docker-compose, and dockerize in any CircleCI job environment where they are missing
    usage:
      jobs:
        your-job:
          executor:
            name: docker/docker
            tag: "3.6"
          steps:
          - checkout
          - docker/install-docker-tools
      orbs:
        docker: circleci/docker@x.y.z
      version: 2.1
      workflows:
        your-workflow:
          jobs:
          - your-job
  lifecycle-hooks:
    description: |
      Build and deploy a Docker image with custom lifecycle hooks: after checking out the code from the VCS repository, before building the Docker image, and after building the Docker image
    usage:
      orbs:
        docker: circleci/docker@x.y.z
      version: 2.1
      workflows:
        build-and-publish-docker-image:
          jobs:
          - docker/publish:
              after_build:
              - run:
                  command: echo "Did this after the build"
                  name: Do this after the build
              after_checkout:
              - run:
                  command: echo "Did this after checkout"
                  name: Do this after checkout
              before_build:
              - run:
                  command: echo "Did this before the build"
                  name: Do this before the build
              image: $CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME
  lint-dockerfile:
    description: |
      Use the `dockerlint` command to install Dockerlint and lint a Dockerfile
    usage:
      orbs:
        docker: circleci/docker@x.y.z
        jobs:
          lint:
            executor: docker/machine
            steps:
            - checkout
            - docker/dockerlint:
                dockerfile: path/to/and/name/of/Dockerfile
                treat-warnings-as-errors: true
      version: 2.1
      workflows:
        lint-dockerfile:
          jobs:
          - lint
  standard-build-and-push:
    description: |
      A standard Docker workflow, where you are building an image with a Dockerfile in the root of your repository, naming the image to be the same name as your repository, and then pushing to the default docker registry (at docker.io)
    usage:
      orbs:
        docker: circleci/docker@x.y.z
      version: 2.1
      workflows:
        build-and-publish-docker-image:
          jobs:
          - docker/publish:
              image: $CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME
  with-extra-build-args:
    description: |
      Build/publish a Docker image with extra build arguments
    usage:
      orbs:
        docker: circleci/docker@x.y.z
      version: 2.1
      workflows:
        build-docker-image-only:
          jobs:
          - docker/publish:
              extra_build_args: --build-arg FOO=bar --build-arg BAZ=qux
              image: $CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME
executors:
  docker:
    description: |
      The docker container to use when running this orb's jobs
    docker:
    - image: <<parameters.image>>:<<parameters.tag>>
    parameters:
      image:
        default: circleci/python
        description: Docker image name
        type: string
      tag:
        default: "3.6"
        description: Image tag
        type: string
  hadolint:
    description: Hadolint Docker image
    docker:
    - image: hadolint/hadolint:<<parameters.tag>>
    parameters:
      resource-class:
        default: small
        enum:
        - small
        - medium
        - medium+
        - large
        - xlarge
        type: enum
      tag:
        default: latest-debian
        description: |
          Specific Hadolint image (make sure to use a `debian` tag, otherwise image will not be usable on CircleCI): https://hub.docker.com/r/hadolint/hadolint/tags
        type: string
    resource_class: <<parameters.resource-class>>
  machine:
    description: |
      CircleCI's Ubuntu-based machine executor VM: https://circleci.com/docs/2.0/executor-types/#using-machine
    machine:
      docker_layer_caching: <<parameters.dlc>>
      image: <<parameters.image>>
    parameters:
      dlc:
        default: false
        description: Enable Docker Layer Caching?
        type: boolean
      image:
        default: ubuntu-1604:201903-01
        type: string
jobs:
  hadolint:
    description: |
      Lint a given Dockerfile using a hadolint Docker image: https://hub.docker.com/r/hadolint/hadolint
    executor: hadolint
    parameters:
      artifacts-path:
        default: ~/project
        description: |
          Relative or absolute path to directory to store as job artifacts.
        type: string
      attach-workspace:
        default: false
        description: |
          Boolean for whether or not to attach to an existing workspace, default is false
        type: boolean
      checkout:
        default: true
        description: Checkout as a first step? Default is true
        type: boolean
      dockerfiles:
        default: Dockerfile
        description: |
          Relative or absolute path, including name, to Dockerfile(s) to be linted, e.g., `~/project/app/deploy.Dockerfile`, defaults to a Dockerfile named `Dockerfile` in the working directory. To lint multiple Dockerfiles, pass a comma-separated string, e.g., `~/project/app/deploy.Dockerfile,~/project/app/test.Dockerfile`.
        type: string
      ignore-rules:
        default: ""
        description: |
          Comma-separated string list of rules to ignore (e.g., `DL3000,SC1010`): https://github.com/hadolint/hadolint#rules
        type: string
      trusted-registries:
        default: ""
        description: |
          Comma-separated list of trusted registries (e.g., `docker.io,my-company.com:5000`); if set, return an error if Dockerfiles use any images from registries not included in this list
        type: string
      workspace-root:
        default: workspace
        description: |
          Workspace root path that is either an absolute path or a path relative to the working directory
        type: string
    steps:
    - bt/install-ci-tools
    - when:
        condition: <<parameters.checkout>>
        steps:
        - checkout
    - when:
        condition: <<parameters.attach-workspace>>
        steps:
        - attach_workspace:
            at: <<parameters.workspace-root>>
    - run:
        command: |
          <<#parameters.ignore-rules>>
          IGNORE_STRING=<<parameters.ignore-rules>>
          IGNORE_RULES=$(echo "--ignore ${IGNORE_STRING//,/ --ignore }")
          <</parameters.ignore-rules>>

          <<#parameters.trusted-registries>>
          REGISTRIES_STRING=<<parameters.trusted-registries>>
          TRUSTED_REGISTRIES=$(echo "--trusted-registry ${REGISTRIES_STRING//,/ --trusted-registry }")
          <</parameters.trusted-registries>>

          echo "Running hadolint with the following options..."
          echo "$IGNORE_RULES"
          echo "$TRUSTED_REGISTRIES"

          DOCKERFILES=<<parameters.dockerfiles>>

          # use comma delimiters to create array
          arrDOCKERFILES=(${DOCKERFILES//,/ })
          let END=${#arrDOCKERFILES[@]}

          for ((i=0;i<END;i++)); do
            DOCKERFILE="${arrDOCKERFILES[i]}"

            hadolint<<#parameters.ignore-rules>> $IGNORE_RULES<</parameters.ignore-rules>> <<#parameters.trusted-registries>>$TRUSTED_REGISTRIES <</parameters.trusted-registries>>$DOCKERFILE

            echo "Success! $DOCKERFILE linted; no issues found"
          done
        name: Lint <<parameters.dockerfiles>> with hadolint
    - store_artifacts:
        path: <<parameters.artifacts-path>>
  publish:
    description: Build and optionally deploy a Docker image
    executor: <<parameters.executor>>
    parameters:
      after_build:
        default: []
        description: Optional steps to run after building the Docker image
        type: steps
      after_checkout:
        default: []
        description: Optional steps to run after checking out the code
        type: steps
      before_build:
        default: []
        description: Optional steps to run before building the Docker image
        type: steps
      deploy:
        default: true
        description: Push the image to a registry?
        type: boolean
      docker-password:
        default: DOCKER_PASSWORD
        description: |
          Name of environment variable storing your Docker password
        type: env_var_name
      docker-username:
        default: DOCKER_LOGIN
        description: |
          Name of environment variable storing your Docker username
        type: env_var_name
      dockerfile:
        default: Dockerfile
        description: Name of dockerfile to use, defaults to Dockerfile
        type: string
      executor:
        default: machine
        description: |
          Executor to use for this job, defaults to this orb's `machine` executor
        type: executor
      extra_build_args:
        default: ""
        description: |
          Extra flags to pass to docker build. For examples, see https://docs.docker.com/engine/reference/commandline/build
        type: string
      image:
        description: Name of image to build
        type: string
      lint-dockerfile:
        default: false
        description: |
          Lint Dockerfile before building?
        type: boolean
      path:
        default: .
        description: |
          Path to the directory containing your Dockerfile and build context, defaults to . (working directory)
        type: string
      registry:
        default: docker.io
        description: |
          Name of registry to use, defaults to docker.io
        type: string
      tag:
        default: $CIRCLE_SHA1
        description: Image tag, defaults to the value of $CIRCLE_SHA1
        type: string
      treat-warnings-as-errors:
        default: false
        description: |
          If linting Dockerfile, treat linting warnings as errors (would trigger an exist code and fail the CircleCI job)?
        type: boolean
      use-remote-docker:
        default: false
        description: |
          Setup a remote Docker engine for Docker commands? Only required if using a Docker-based executor
        type: boolean
    steps:
    - checkout
    - when:
        condition: <<parameters.after_checkout>>
        name: Run after_checkout lifecycle hook steps
        steps: <<parameters.after_checkout>>
    - when:
        condition: <<parameters.use-remote-docker>>
        steps:
        - setup_remote_docker
    - when:
        condition: <<parameters.deploy>>
        steps:
        - check:
            docker-password: <<parameters.docker-password>>
            docker-username: <<parameters.docker-username>>
            registry: <<parameters.registry>>
    - when:
        condition: <<parameters.before_build>>
        name: Run before_build lifecycle hook steps
        steps: <<parameters.before_build>>
    - build:
        dockerfile: <<parameters.dockerfile>>
        extra_build_args: <<parameters.extra_build_args>>
        image: <<parameters.image>>
        lint-dockerfile: <<parameters.lint-dockerfile>>
        path: <<parameters.path>>
        registry: <<parameters.registry>>
        tag: <<parameters.tag>>
        treat-warnings-as-errors: <<parameters.treat-warnings-as-errors>>
    - when:
        condition: <<parameters.after_build>>
        name: Run after_build lifecycle hook steps
        steps: <<parameters.after_build>>
    - when:
        condition: <<parameters.deploy>>
        steps:
        - push:
            image: <<parameters.image>>
            registry: <<parameters.registry>>
            tag: <<parameters.tag>>
orbs:
  bt: circleci/build-tools@2.6.3
  orb-tools: circleci/orb-tools@8.8.0
version: 2.1

## Contributing

We welcome [issues](https://github.com/CircleCI-Public/docker-orb/issues) to and [pull requests](https://github.com/CircleCI-Public/docker-orb/pulls) against this repository!

For further questions/comments about this or other orbs, visit [CircleCI's orbs discussion forum](https://discuss.circleci.com/c/orbs).
