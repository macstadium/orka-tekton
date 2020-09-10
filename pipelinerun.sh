kubectl delete task orka-full
kubectl apply -f resources/task.yml
kubectl delete -f samples/pipeline.yml
kubectl apply -f samples/pipeline.yml
kubectl-tkn pipelinerun logs run-orka-pipeline -f
