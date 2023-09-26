#!/bin/bash

: ${NAMESPACE:="default"}
: ${ORKA_API:="http://10.221.188.20"}
: ${TEKTON_PIPELINES_NAMESPACE:="tekton-pipelines"}
: ${TEKTON_PIPELINES_RESOLVERS_NAMESPACE:="tekton-pipelines-resolvers"}

USAGE=$(cat <<EOF
Usage:
  NAMESPACE=<namespace> ORKA_API=<url> ./install.sh [-a|-d|--apply|--delete]
Options:
  -a, --apply : Install all tasks and config map
  -d, --delete : Uninstall all tasks and config map
  --help : Display this message
Environment:
  NAMESPACE : Kubernetes namespace. Defaults to "default"
  ORKA_API : Orka API endpoint. Defaults to "http://10.221.188.20"
EOF
)

if [ -n "$1" ]; then
  if [[ "$1" == "-a" || "$1" == "--apply" ]]; then
    ACTION="apply"
  elif [[ "$1" == "-d" || "$1" = "--delete" ]]; then
    ACTION="delete"
  elif [[ "$1" == "--help" ]]; then
    echo "$USAGE"
    exit 0
  else
    echo -e "Unkown argument: $1\n"
    echo "$USAGE"
    exit 1
  fi
else
  ACTION="apply"
fi

# Install config map
sed -e 's|$(url)|'"$ORKA_API"'|' resources/orka-tekton-config.yaml.tmpl \
  > resources/orka-tekton-config.yaml
kubectl $ACTION --namespace=$NAMESPACE -f resources/orka-tekton-config.yaml
rm -f resources/orka-tekton-config.yaml

if [ $ACTION == "apply" ]; then
  API_VERSION_RESPONSE=$(curl "${ORKA_API}/version")
  if [[ "$API_VERSION_RESPONSE" == *"\"api_version\":\"3."* ]]; then
    # Add tolerations to tekton controller and webhook pods
    TEKTON_PODS=$(kubectl get pods -n $TEKTON_PIPELINES_NAMESPACE | tail -n +2 |  awk '{print $1}') 

    for pod in $TEKTON_PODS; do
      kubectl patch pod $pod -n $TEKTON_PIPELINES_NAMESPACE --patch-file "patch-files/patch-pod-tolerations.yaml"
    done

    TEKTON_RESOLVERS_PODS=$(kubectl get pods -n $TEKTON_PIPELINES_RESOLVERS_NAMESPACE | tail -n +2 |  awk '{print $1}')

    for pod in $TEKTON_RESOLVERS_PODS; do
      kubectl patch pod $pod -n $TEKTON_PIPELINES_RESOLVERS_NAMESPACE --patch-file "patch-files/patch-pod-tolerations.yaml"
    done

    # Add tolerations to default pod template in tekton configmap
    kubectl patch configmap config-defaults -n tekton-pipelines --patch-file "patch-files/patch-configmap-tolerations.yaml"

    # Wait for tekton pods to be up and running
    kubectl wait pod --all --for=condition=ready -n $TEKTON_PIPELINES_NAMESPACE
    kubectl wait pod --all --for=condition=ready -n $TEKTON_PIPELINES_RESOLVERS_NAMESPACE
  fi
fi

# Install tasks
kubectl $ACTION --namespace=$NAMESPACE \
  -f tasks/orka-full.yaml \
  -f tasks/orka-init.yaml \
  -f tasks/orka-deploy.yaml \
  -f tasks/orka-teardown.yaml
