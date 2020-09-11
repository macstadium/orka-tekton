kubectl delete task orka-full
kubectl delete taskrun dump-disk-info
kubectl apply -f tasks/orka-full.yml
kubectl apply -f samples/dump-disk-info.yml
kubectl-tkn taskrun logs dump-disk-info -f
