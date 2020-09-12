#!/bin/sh

: ${NAMESPACE:="default"}

sed -e 's/$(namespace)/'"$NAMESPACE"'/' resources/orka-token-manager.yml.tmpl > resources/orka-token-manager.yml
kubectl apply -f resources/orka-token-manager.yml
rm -f resources/orka-token-manager.yml
