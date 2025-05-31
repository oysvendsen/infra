# Infrastructure configuration
This repo contains the Infra-as-code scripts for [ExoScale](https://www.exoscale.com/), the current platform provider of choice.

The infrastructure is described as [Terraform](https://opentofu.org/) files, with the [Exoscale](provider).

The Terraform files defines the desired resources on the platform. OpenTofu uses the terraform files to create a plan for which changes to make to the platform. The plan can be fed back into OpenTofu to enact the changes.

## Structure and Architecture

The file `main.tf` contains all the resources that are desired during "normal operations".
It requires the existence of a '*.auto.tfvars' file with the 'api_key' and 'api_secret' specified.

## Usage
OpenTofu, much like TerraForm, deploys infrastructure in four steps; init - to set up the local directory, plan - to create a file with all the changes, apply - initiate the plan, and destroy - to remove all the resources.

The preferred usage method is the [OCI container image](https://opentofu.org/docs/intro/install/docker/). The alias below allows you to run the container image, alternately you can use the script `tofu.sh`.
```bash
alias tofu="nerdctl run --workdir=/src/workspace --mount type=bind,source=.,target=/srv/workspace ghcr.io/opentofu/opentofu:latest"
```

## Automation
