# Run macOS builds with MacStadium Orka

**IMPORTANT: These `Tasks` are compatible with Tekton Pipelines v0.16.0 or later.**

**IMPORTANT: You need an Orka envrionment to run these `Tasks`.**

This set of `Tasks` lets Tekton utilize macOS build agents running on [Orka](https://www.macstadium.com/orka) by MacStadium.

- [Prerequisites](#Prerequisites)
- [Installation](#Installation)
  - [Default namespace installation](#default-namespace-installation)
  - [Custom namespace installation](#custom-namespace-installation)
- [Usage](#Usage)
  - [Single macOS build agent](#single-macos-build-agent)
  - [Multiple macOS build agents](#multiple-macos-build-agents)
- [Configuring Credentials](#Configuring-Credentials)
  - [Using an SSH key](#Using-an-SSH-key)
  - [A Note About Credentials](#A-Note-About-Credentials)
- [Configuring A Kubernetes Service Account](#Configuring-A-Kubernetes-Service-Account)
- [Task Parameter Reference](#Task-Parameter-Reference)
  - [Common Parameters](#Common-Parameters)
  - [Configuring Secrets and Config Maps](#Configuring-Secrets-and-Config-Maps)

## Prerequisites

* You need a Kubernetes cluster with Tekton Pipelines v0.16.0 or later configured.
* You need an Orka environment with the following components:
  * Orka API endpoint (IP or custom domain). Usually, `http://10.221.188.100`, `http://10.10.10.100` or `https://<custom-domain>`.
  * Dedicated Orka user with valid credentials (email & password). Create a new user or request one from your Orka administrator.
  * SSH-enabled base image and the respective SSH credentials (email & password OR SSH key). Use an existing base image or create your own. 
* You need an active VPN connection between your Kubernetes cluster and Orka. Use a VPN client for a temporary connection or create a site-to-site VPN tunnel for permanent access.

See also: [Using Orka, At a Glance](https://orkadocs.macstadium.com/docs/quick-start-introduction)

## Installation

### Default namespace installation

To install all `Tasks` and the Orka configuration in the `default` namespace within your Kubernetes cluster, run the following command against your actual Orka API endpoint.

```sh
ORKA_API=http://10.221.188.100 ./install.sh --apply
```

To uninstall from the `default` namespace, run the script with the `-d` or `--delete` flag:

```sh
./install.sh --delete
```

### Custom namespace installation

To specify a custom namespace during installation, run the following command against your preferred namespace and your actual Orka API endpoint:

```sh
NAMESPACE=tekton-orka ORKA_API=http://10.221.188.100 ./install.sh --apply
```

To uninstall from a selected namespace, run the script with the `-d` or `--delete` flag against the namespace:

```sh
NAMESPACE=tekton-orka ./install.sh --delete
```

## Usage

You can use these `Tasks` one of two ways:

## Single macOS build agent

Use the `orka-full` task. 

The [`build-audiokit-pipeline`](samples/build-audiokit-pipeline.yml) example provides a pipeline that:
1. Clones a git repository.
2. Passes it to the Orka build agent.
3. Stores build artifacts on a persistent volume.

## Multiple macOS build agents

Use the three modular `Tasks`:

1. Set up an Orka job runner with the `orka-init` task.
1. Deploy multiple VMs (either in parallel or in series) using the `orka-deploy` task.
1. Clean up in the `finally` clause of the `Pipeline` using the `orka-teardown` task.

See the [`parallel-deploy`](samples/parallel-deploy.yml) example for this approach.

To use the modular approach, you need to configure a Kubernetes service account to run the `Pipeline`. See [the section below](#Configuring-A-Kubernetes-Service-Account) for more information.

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

Similar to the install script, you can also provide the `NAMESPACE` if desired and uninstall with the `-d` or `--delete` flag. Note that only the `NAMESPACE` variable is required when uninstalling, if initially provided.

### Using an SSH key

If using an SSH key to connect to the VM, first copy the public key to the VM and commit the base image. Then, store the username and private key in a Kubernetes secret:

```sh
kubectl create secret generic orka-ssh-key --from-file=id_rsa=/path/to/id_rsa --from-literal=username=<username>
```

See the [`use-ssh-key`](samples/use-ssh-key.yml) example for more information.

### A Note About Credentials

The Orka `Tasks` will expect the Orka credentials to be stored in a secret called `orka-creds` with keys of `email` and `password`. However, this is not set in stone; the `Task` parameters can be configured to use any names you wish. These defaults are provided for convenience.

Similarly, the SSH credentials are expected to be stored in a secret called `orka-ssh-creds` with keys of `username` and `password`. These can also be customized using `Task` parameters.

## Configuring A Kubernetes Service Account

To use the `orka-init` and `orka-teardown` tasks, you will need to configure a Kubernetes service account along with a cluster role and cluster role binding as follows:

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

For convenience this can be accomplished by running the `add-service-account.sh` script:

```sh
NAMESPACE=<namespace> ./add-service-account.sh --apply
```

The service account and related resources can be removed by running the script with the `-d` or `--delete` flag, specifying the `NAMESPACE` variable if applicable.

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
