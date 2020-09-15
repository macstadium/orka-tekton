# Run macOS builds with MacStadium Orka

This set of `Tasks` can be used to utilize macOS build agents running on Tekton Pipelines with [Orka](https://www.macstadium.com/orka) by MacStadium.

An Orka cloud is required in order to use these `Tasks`.

## Prerequisites

See the official documentation [here](https://orkadocs.macstadium.com/docs/quick-start-introduction) to get started.

As described in the above document, you will need the following:

- Locate your Orka API endpoint, available from your IP plan. This will typically be either `http://10.221.188.100` or `http://10.10.10.100`
- Create an Orka service account using the CLI with `orka user create`, or by sending a POST request to `/users` with an email and password in the body
  - **NOTE:** It is not necessary to manually obtain a token from the API
- Create a VM base image with SSH enabled. See [here](https://orkadocs.macstadium.com/docs/creating-an-ssh-enabled-image) for more information
  - Create Kubernetes secret with either SSH password or SSH private key

## Installation

To install all `Tasks` and the Orka configuration in the `default` namespace within your Kubernetes cluster, run the following command, substituting your Orka API endpoint:

```sh
ORKA_API=http://10.221.188.100 ./install.sh
```

You can specify a different namespace as follows:

```sh
NAMESPACE=tekton-orka ORKA_API=http://10.10.10.100 ./install.sh
```

To uninstall, simply run the script with the `-d` or `--delete` flag, being sure to specify the namespace if applicable:

```sh
NAMESPACE=tekton-orka ./install.sh --delete
```

Note that it is not necessary to specify the API endpoint to uninstall.

## Usage

There are two main ways to use the `Tasks`:

- If you only need a single macOS build agent, use the `orka-full` task. See the `build-audiokit-pipeline` example for a pipeline that clones a git repository, passes it to the Orka build agent, and stores build artifacts on a persistent volume.
- If you need to run multiple parallel build agents in a pipeline, use the three modular `Tasks`:

    1. Set up an Orka job runner with the `orka-init` task
    1. Deploy multiple VMs (either in parallel or in series) using the `orka-deploy` task
    1. Clean up in the `finally` clause of the `Pipeline` using the `orka-teardown` task

    See the `parallel-deploy` example for this approach.

In order to use the modular approach, you will need to configure a Kubernetes service account to run the `Pipeline`. See the section below for more information.

## Configuring Credentials

You will need to create Kubernetes secrets to store both the Orka credentials as well as the VM SSH credentials. Refer to the following example:

```yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: orka-creds
type: Opaque
stringData:
  email: tekton-svc@macstadium.com
  password: p@ssw0rd
---
apiVersion: v1
kind: Secret
metadata:
  name: orka-ssh-creds
type: Opaque
stringData:
  username: admin
  password: admin
```

You can also generate these secrets using the provided scripts:

```sh
EMAIL=<email> PASSWORD=<password> ./add-orka-creds.sh --apply
SSH_USERNAME=<username> SSH_PASSWORD=<password> ./add-ssh-creds.sh --apply
```

Similar to the install script, you can also provide the `NAMESPACE` if desired and uninstall with the `-d` or `--delete` flag. Note that it is only necessary to provide the `NAMESPACE` when uninstalling, if initially provided.

### Using an SSH key

If you choose to use an SSH key to connect to the VM, first copy the public key to the VM and commit the base image. Then, store the username and private key in a Kubernetes secret:

```sh
kubectl create secret generic orka-ssh-key --from-file=id_rsa=/path/to/id_rsa --from-literal=username=<username>
```

See the `use-ssh-key` example for more information.

### A Note About Credentials

The Orka `Tasks` will expect the Orka credentials to be stored in a secret called `orka-creds` with keys of `username` and `password`. However, this is not set in stone; the `Task` parameters can be configured to use any names you wish. These defaults are provided for convenience.

Similar, the SSH credentials are expected to be stored in a secret called `orka-ssh-creds` with keys of `username` and `password`. These can also be customized using `Task` parameters.

## Configuring A Kubernetes Service Account

In order to use the `orka-init` and `orka-teardown` tasks, you will need to configure a Kubernetes service account along with a cluster role and cluster role binding as follows:

```yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: orka-svc
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: orka-runner
rules:
  - apiGroups: [""]
    resources:
      - configmaps
      - secrets
    verbs:
      - create
      - delete
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: orka-runner
subjects:
- kind: ServiceAccount
  name: orka-svc
  namespace: default
roleRef:
  kind: ClusterRole
  name: orka-runner
  apiGroup: rbac.authorization.k8s.io
```

For the sake of convenience this can be accomplished by running the `add-service-account.sh` script:

```sh
NAMESPACE=<namespace> ./add-service-account.sh --apply
```

The service account and related resources can be removed by running the same script with the `-d` or `--delete` flag, specifying the `NAMESPACE` variable if applicable.
