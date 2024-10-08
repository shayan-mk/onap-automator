# ONAP Automator

## Overview
This repository contains a set of Bash scripts designed to automate the deployment and management of ONAP (Open Network Automation Platform) for 5G slicing on a Kubernetes environment. The scripts handle tasks such as setting up a VM, deploying ONAP components, managing dependencies, and cleaning up the environment.

## Repository Structure
- **`setup-vm.sh`**: Prepares the virtual machine environment by installing necessary tools and configuring env and network for ONAP deployment.

- **`cleanup-vm.sh`**: Cleans up the virtual machine by removing ONAP-related configurations, containers, and temporary files, restoring the VM to its original state.

- **`install-reqs.sh`**: Installs the necessary dependencies and tools required for running ONAP, such as Docker, Helm, and Kubernetes with a specific version.

- **`uninstall-reqs.sh`**: Removes previously installed dependencies, cleaning up the environment after the deployment is done.

- **`run-all.sh`**: This script runs other scripts on all VM nodes :)  For example `./run-all.sh control setup-vm.s` will run `setup-vm.sh` only on control nodes.

- **`deploy-basics.sh`**: Initializes the deployment of basic ONAP components. This script handles setting up essential services needed for ONAP deployment (a.k.a Base Platform).

- **`sub-deploy.sh`**: Deploys specific ONAP components individually. Useful if only certain ONAP features need to be deployed at any given time.

- **`sub-undeploy.sh`**: Uninstalls specific ONAP components. This allows you to remove particular components while keeping others intact.

- **`undeploy-all.sh`**: Undeploys all the ONAP components that have been deployed using the `deploy-basics.sh` or `sub-deploy.sh` scripts.

- **`helm-plugins/`**: Customized version of ONAP's `deploy` and `undeploy` plugins enabling dry-run and component-specific deployment. You can install using `helm install plugin helm-plugins/deploy`. This plugins are prerequisites to the other ONAP deployment scripts above.

- **`base-platform-yamls/`**: This directory contains yaml configs for the ONAP Base Platform, versions **Montreal** and **New Delhi**

- **`archive/`**: Legacy scripts for k8s cluster creation, which are now replaced with RKE `cluster.yml` config. ( Special thanks to Niloy Saha for the legacy scripts :D )
