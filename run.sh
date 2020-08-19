kubectl delete task tekton-orka
kubectl delete taskrun run-tekton-orka
kubectl apply -f resources/task.yml
kubectl apply -f resources/taskrun.yml
kubectl-tkn taskrun logs run-tekton-orka -f
