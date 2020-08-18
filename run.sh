kubectl delete task tekton-orka
kubectl delete taskrun run-tekton-orka
kubectl apply -f task.yml
kubectl apply -f taskrun.yml
kubectl-tkn taskrun logs run-tekton-orka -f
