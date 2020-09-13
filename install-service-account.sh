#!/bin/sh

: ${NAMESPACE:="default"}

sed -e 's/$(namespace)/'"$NAMESPACE"'/' resources/orka-runner.yml.tmpl > resources/orka-runner.yml
kubectl apply -f resources/orka-runner.yml
rm -f resources/orka-runner.yml
