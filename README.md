# Run macOS builds with MacStadium Orka

This set of `Tasks` can be used to utilize macOS build agents running on Tekton Pipelines with [Orka](https://www.macstadium.com/orka) by MacStadium.

An Orka cloud is required in order to use these `Tasks`.

## Prerequisites

See the official documentation [here](https://orkadocs.macstadium.com/docs/quick-start-introduction) to get started.

As described in the above document, you will need to complete the following:

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

The Task relies on Orka credentials being stashed in a Kubernetes secret called `tekton-orka-creds`. This secret should look something like the following:

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
```

Create a secret from an ssh key:

`kubectl create secret generic orka-ssh-key --from-file=id_rsa=/path/to/id_rsa --from-literal=username=<username>`
