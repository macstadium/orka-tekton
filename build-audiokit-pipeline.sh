kubectl delete task orka-full
kubectl delete -f samples/build-audiokit-pipeline.yml
kubectl apply -f tasks/orka-full.yml
kubectl apply -f samples/build-audiokit-pipeline.yml
kubectl-tkn pipelinerun logs run-build-audiokit-pipeline -f
