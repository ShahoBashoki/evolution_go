#!/bin/bash

set -eux
set -o errexit
set -o pipefail
set -o nounset

export CGO_ENABLED=1
export GO111MODULE=on
export GOARCH=amd64
export GOOS=linux

CI=${1:-false}
OUTPUT_BIN=${2:-"swagger.json"}
OUTPUT_DIR=${3:-"doc"}
OUTPUT=./${OUTPUT_DIR}/${OUTPUT_BIN}

rm -fr ${OUTPUT}

# go mod tidy
go mod vendor

if ${CI}; then

swagger generate spec \
  -o ${OUTPUT}

else

COMPOSE_DOCKER_CLI_BUILD=1 DOCKER_BUILDKIT=1 docker run \
  --env CGO_ENABLED=1 \
  --env GO111MODULE=on \
  --env GOARCH=amd64 \
  --env GOOS=linux \
  --interactive \
  --platform linux/amd64 \
  --rm \
  --tty \
  --volume $(pwd):/workspace \
  --workdir /workspace \
  quay.io/goswagger/swagger:v0.29.0 generate spec \
    -o ${OUTPUT}

fi
