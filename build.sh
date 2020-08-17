#!/bin/sh

set -e

docker build -t sburtonmacstadium/tekton-orka .
docker push sburtonmacstadium/tekton-orka
