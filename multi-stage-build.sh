kubectl delete task orka-init
kubectl delete -f samples/multi-stage-build.yml
kubectl apply -f tasks/orka-init.yml
kubectl apply -f samples/multi-stage-build.yml
kubectl-tkn pipelinerun logs run-multi-stage-build -f
