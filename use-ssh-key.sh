kubectl delete task orka-full
kubectl delete taskrun use-ssh-key
kubectl apply -f resources/task.yml
kubectl apply -f samples/use-ssh-key.yml
kubectl-tkn taskrun logs use-ssh-key -f
