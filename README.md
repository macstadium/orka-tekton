# Google Tekton integration for Orka

Tekton is a CI/CD tool made by Google which uses Kubernetes native resources to run pipeline jobs. The Tekton vocabulary introduces a few new Kubernetes resources, including:

- `Task`
- `TaskRun`
- `Pipeline`
- `PipelineRun`
- `PipelineResource`

The smallest re-useable Tekton resource is the `Task`. A `Task` consists of multiple steps for a job. A single task is run using a Kubernetes pod, and each step in the task is run as a container in the pod using a specified image. Tasks can be assembled to run concurrently or in series in a `Pipeline`. In order to execute a task or pipeline, a `TaskRun` or `PipelineRun` resource can be applied.

This repository contains a prototype for an Orka / Tekton integration which uses the Orka API to create a virtual machine, copy a build script to the virtual machine, execute the build script, and copy the resulting build back to the Tekton cluster. This is accomplished with a Task that makes use of a Tekton feature called `workspaces` which allows the `TaskRun` or `PipelineRun` resource to specify a volume mount in which to store the build results. This could be a persistent volume mount in the cluster or an S3 bucket, for example.

## Orka User Requirements

- Orka service account set up (email / password)
- License key
- Base image with SSH enabled
- Orka API endpoint
  - http://10.10.10.100
  - http://10.221.188.100

### Orka Credentials

The Task relies on Orka credentials being stashed in a Kubernetes secret called `tekton-orka-creds`. This secret should look something like the following:

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: tekton-orka-creds
type: Opaque
stringData:
  email: tekton-svc@macstadium.com
  password: p@ssw0rd
  licenseKey: orka-license-key
```

## Tekton Task Docker Image

The Orka Tekton Task uses a Docker image built from Alpine with minimal dependencies installed. It is fairly lightweight, at ~14.8MB.

The image is packed with a shell script which communicates with the Orka API using curl. The build script is run in the VM over SSH using sshpass.

## Tekton Task Workflow

1. Get token
1. Create VM config
1. Deploy VM
    - Store IP / SSH port in variables
1. Wait for SSH access
1. Copy build script
1. Execute build script
1. Copy build artifact
1. Purge VM
1. Revoke token

## Links

- https://medium.com/@dlorenc/tekton-on-mac-ed6ea72d1efb
- https://github.com/tektoncd/pipeline/blob/master/docs/install.md
- https://github.com/tektoncd/pipeline/blob/master/docs/container-contract.md
- https://github.com/tektoncd/pipeline/blob/master/docs/tasks.md
- https://github.com/tektoncd/pipeline/blob/master/docs/workspaces.md
