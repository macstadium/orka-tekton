# Run macOS builds with MacStadium Orka

This set of `Tasks` can be used to utilize macOS build agents running on Tekton Pipelines with [Orka](https://www.macstadium.com/orka) by MacStadium.

An Orka cloud is required in order to use these `Tasks`.

- [Prerequisites](#Prerequisites)
- [Installation](#Installation)
- [Usage](#Usage)
- [Configuring Credentials](#Configuring-Credentials)
  - [Using an SSH key](#Using-an-SSH-key)
  - [A Note About Credentials](#A-Note-About-Credentials)
- [Configuring A Kubernetes Service Account](#Configuring-A-Kubernetes-Service-Account)
  - [Running Without A Service Account](#Running-Without-A-Service-Account)
- [Task Parameter Reference](#Task-Parameter-Reference)
  - [Common Parameters](#Common-Parameters)
  - [Configuring Secrets and Config Maps](#Configuring-Secrets-and-Config-Maps)

## Prerequisites

See the official documentation [here](https://orkadocs.macstadium.com/docs/quick-start-introduction) to get started.

As described in the above document, you will need the following:

- Locate your Orka API endpoint, available from your IP plan. This will typically be either `http://10.221.188.100` or `http://10.10.10.100`
- Create an Orka service account using the CLI with `orka user create`, or by sending a `POST` request to `/users` with an email and password in the body
  - **NOTE:** It is not necessary to manually obtain a token from the API
- Create a VM base image with SSH enabled. See [here](https://orkadocs.macstadium.com/docs/creating-an-ssh-enabled-image) for more information

## Installation

To install all `Tasks` and the Orka configuration in the `default` namespace within your Kubernetes cluster, run the following command, substituting your Orka API endpoint:

```sh
ORKA_API=http://10.221.188.100 ./install.sh --apply
```

You can specify a different namespace as follows:

```sh
NAMESPACE=tekton-orka ORKA_API=http://10.10.10.100 ./install.sh --apply
```

To uninstall, simply run the script with the `-d` or `--delete` flag, being sure to specify the namespace if applicable:

```sh
NAMESPACE=tekton-orka ./install.sh --delete
```

Note that it is not necessary to specify the API endpoint to uninstall.

## Usage

There are two main ways to use the `Tasks`:

- If you only need a single macOS build agent, use the `orka-full` task. See the [`build-audiokit-pipeline`](samples/build-audiokit-pipeline.yml) example for a pipeline that clones a git repository, passes it to the Orka build agent, and stores build artifacts on a persistent volume.
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

Similarly, the SSH credentials are expected to be stored in a secret called `orka-ssh-creds` with keys of `username` and `password`. These can also be customized using `Task` parameters.

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

The service account and related resources can be removed by running the script with the `-d` or `--delete` flag, specifying the `NAMESPACE` variable if applicable.

### Running Without A Service Account

If desired, you can run the `orka-deploy` task in a `Pipeline` by obtaining a token from the Orka API using the `/token` endpoint and supplying an already existing VM config:

```yaml
# Token below is generic and copied from https://jwt.io/
# Replace generic token with token obtained from Orka API
---
apiVersion: v1
kind: Secret
metadata:
  name: orka-token
type: Opaque
stringData:
  token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: orka-vm-name
data:
  vm-name: build-tools
```

By default, the `orka-deploy` task expects there to be a secret called `orka-token` with a key of `token` and a config map called `orka-vm-name` with a key of `vm-name`. These values can be customized with `Task` parameters.

See the `custom-deploy` example for more information. Note that you will still need to supply VM SSH credentials, although the Orka credentials are not necessary in this scenario.

## Task Parameter Reference

### Common Parameters

| Parameter | Description | Default |
| --- | --- | ---: |
| `base-image` | The Orka base image to use for the VM config. | --- |
| `cpu-count` | The number of CPU cores to dedicate for the VM. Must be 3, 4, 6, 8, 12, or 24. | 3 |
| `vcpu-count` | The number of vCPUs for the VM. Must equal the number of CPUs, when CPU is less than or equal to 3. Otherwise, must equal half of or exactly the number of CPUs specified. | 3 |
| `vnc-console` | Enables or disables VNC for the VM configuration. | false |
| `script` | The script to run inside of the VM. The script will be prepended with `#!/bin/sh` and `set -ex` if no shebang is present. You may supply your own shebang instead, e.g. to run a script with the shell of your choice, or a scripting language like Python or Ruby. | --- |
| `copy-build` | Specifies whether to copy build artifacts from VM back to workspace. Disable when there is no need to copy build artifacts, e.g when running tests or linting code. | true |
| `verbose` | Enables verbose logging for all connection activity to VM. | false |
| `ssh-key` | Specifies whether the SSH credentials secret contains an SSH key, as opposed to a password. | false |
| `delete-vm` | Specifies whether to delete the VM after use when run in a pipeline. This can be useful to discard build agents as soon as they are no longer needed, to free up resources. Set to false if you intend to manually clean up VMs after use. Applicable *only* to the `orka-deploy` task. | true |

### Configuring Secrets and Config Maps

| Parameter | Description | Default |
| --- | --- | ---: |
| `orka-creds-secret` | The name of the secret holding your Orka credentials. | orka-creds |
| `orka-creds-email-key` | The name of the key in the Orka credentials secret for the email address associated with the service account. | email |
| `orka-creds-password-key` | The name of the key in the Orka credentials secret for the password associated with the service account. | password |
| `ssh-secret` | The name of the secret holding your VM SSH credentials. | orka-ssh-creds |
| `ssh-username-key` | The name of the key in the VM SSH credentials secret for the username associated with the macOS VM. | username |
| `ssh-password-key` | The name of the key in the VM SSH credentials secret for the password associated with the macOS VM. If ssh-key is true, this parameter should specify the name of the key in the VM SSH credentials secret that holds the private SSH key. | password |
| `orka-token-secret` | The name of the secret holding the authentication token used to access the Orka API. Applicable to `orka-init` / `orka-deploy` / `orka-teardown`. | orka-token |
| `orka-token-secret-key` | The name of the key in the Orka token secret which holds the authentication token. Applicable to `orka-init` / `orka-deploy` / `orka-teardown`. | token |
| `orka-vm-name-config` | The name of the config map which stores the name of the generated VM configuration. Applicable to `orka-init` / `orka-deploy` / `orka-teardown`. | orka-vm-name |
| `orka-vm-name-config-key` | The name of the key in the VM name config map which stores the name of the generated VM configuration. Applicable to `orka-init` / `orka-deploy` / `orka-teardown`. | vm-name |
