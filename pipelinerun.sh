kubectl delete task orka-full
kubectl delete -f samples/pipeline.yml
kubectl apply -f tasks/orka-full.yml
kubectl apply -f samples/pipeline.yml
kubectl-tkn pipelinerun logs run-orka-pipeline -f
