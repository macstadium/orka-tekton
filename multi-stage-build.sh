kubectl delete task orka-init
kubectl delete task orka-deploy
kubectl delete task orka-teardown
kubectl delete -f samples/multi-stage-build.yml
kubectl apply -f tasks/orka-init.yml
kubectl apply -f tasks/orka-deploy.yml
kubectl apply -f tasks/orka-teardown.yml
kubectl apply -f samples/multi-stage-build.yml
kubectl-tkn pipelinerun logs run-multi-stage-build -f
