kubectl delete task orka-full
kubectl delete taskrun run-orka-full
kubectl apply -f resources/task.yml
kubectl apply -f resources/taskrun.yml
kubectl-tkn taskrun logs run-orka-full -f
