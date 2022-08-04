# Developing

* [Prerequisites](#prerequisites)
* [Setting Up a Development Environment](#setting-up-a-development-environment)
  * [Install Tools](#install-tools)
  * [Start Local Kubernetes Cluster](#start-local-kubernetes-cluster)
  * [Configure Environment](#configure-environment)
* [Building the Docker Image](#building-the-docker-image)

## Prerequisites

Access to an Orka cluster as described in the README [here](README.md#prerequisites) is required for development of all Orka tasks.

`minikube` may be used to run a local Kubernetes cluster. See the [section below](#start-local-kubernetes-cluster) on running a single-node cluster on your local development machine.

## Setting Up a Development Environment

### Install Tools

The following tools are required for development:

* [`git`](https://git-scm.com/): For source control
* [`make`](https://www.gnu.org/software/make/): For automating development tasks
* [`docker`](https://docs.docker.com/get-docker/): For building and pushing images to the ghcr.io/macstadium registry
* [`minikube`](https://minikube.sigs.k8s.io/docs/): For running a local Kubernetes cluster
* [`kubectl`](https://kubernetes.io/docs/tasks/tools/install-kubectl/): For interacting with the Kubernetes cluster

> **Note**: On macOS, `git` and `make` may be installed as part of the Xcode Command Line Tools by running the command `xcode-select --install` in the Terminal

### Start Local Kubernetes Cluster

To start a local Kubernetes cluster with `minikube`, run the following command:

  ```sh
  minikube start
  ```

To install the latest version of Tekton in the local cluster, run the following command:

  ```sh
  minikube kubectl -- apply --filename https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml
  ```

### Configure Environment

To setup the Kubernetes secrets and config maps, the following environment variables are required:

* `ORKA_API`: The load balancer address of the Orka API. Defaults to `http://10.221.188.20`
* `NAMESPACE`: The Kubernetes namespace to apply all resources to. Defaults to `default`
* `EMAIL`: The email address associated with an Orka user account
* `PASSWORD`: The password for an Orka user account
* `SSH_USERNAME`: The SSH username used to connect to an Orka VM
* `SSH_PASSWORD`: The SSH password used to connect to an Orka VM

To build and push the Docker image to a registry, the following environment variables are required:

* `IMAGE_REPO`: Container image repository for hosting development image
* `IMAGE_TAG`: Tag used when building and pushing the Docker image used for development purposes

Any of the above variables may be set in the shell prior to running `make`:

  ```sh
  export ORKA_API=http://10.221.188.20
  ```

However, the recommended approach is to create an `.env` file in the current working directory:

  ```sh
  # .env
  EMAIL=tekton-svc@email.com
  PASSWORD=p@ssw0rd
  SSH_USERNAME=admin
  SSH_PASSWORD=admin
  IMAGE_REPO=ghcr.io/my-org/orka-tekton-runner
  IMAGE_TAG=dev-latest
  ```

After all variables are set, run the following command to configure the cluster and install all tasks:

  ```sh
  make all
  ```

> **Note**: Run the command `make help` for more information on available targets

## Building the Docker Image

To build the Docker image, first make sure the environment variables `IMAGE_REPO` and `IMAGE_TAG` are set as described in the [above section](#configure-environment).

Run the following command to build the image:

  ```sh
  make build
  ```

Run the following command to push the image to a repository:

  ```sh
  make push
  ```
