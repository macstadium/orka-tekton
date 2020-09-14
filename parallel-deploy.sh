#!/bin/bash
: ${NAMESPACE:="default"}

# kubectl delete task orka-init
# kubectl delete task orka-deploy
# kubectl delete task orka-teardown
kubectl delete --namespace=$NAMESPACE -f samples/parallel-deploy.yml
kubectl apply --namespace=$NAMESPACE \
  -f tasks/orka-init.yml \
  -f tasks/orka-deploy.yml \
  -f tasks/orka-teardown.yml
# kubectl apply -f tasks/orka-deploy.yml
# kubectl apply -f tasks/orka-teardown.yml
kubectl apply --namespace=$NAMESPACE -f samples/parallel-deploy.yml
kubectl-tkn pipelinerun logs run-parallel-deploy -f --namespace=$NAMESPACE
