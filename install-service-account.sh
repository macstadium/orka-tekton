#!/bin/bash

: ${NAMESPACE:="default"}
: ${ACTION:="apply"}

if [[ "$1" == "-a" || "$1" == "--apply" ]]; then
  ACTION="apply"
elif [[ "$1" == "-d" || "$1" = "--delete" ]]; then
  ACTION="delete"
fi

sed -e 's/$(namespace)/'"$NAMESPACE"'/' resources/orka-runner.yml.tmpl > resources/orka-runner.yml
kubectl $ACTION -f resources/orka-runner.yml
rm -f resources/orka-runner.yml
