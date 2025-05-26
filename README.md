# Infrastructure configuration
This repo contains the Infra-as-code scripts for [ExoScale](https://www.exoscale.com/), the current platform provider of choice.

The infrastructure is described as [Terraform](https://opentofu.org/) files, with the [Exoscale](provider).

The Terraform files defines the desired resources on the platform. OpenTofu uses the terraform files to create a plan for which changes to make to the platform. The plan can be fed back into OpenTofu to enact the changes.

## Structure and Architecture

`main.tf` contains all the resources that are desired during "normal operations".

## Usage
The preferred usage method is the [OCI container image](https://opentofu.org/docs/intro/install/docker/).

```bash
# Init providers plugins
nerdctl run \
    --workdir=/srv/workspace \
    --mount type=bind,source=.,target=/srv/workspace \
    ghcr.io/opentofu/opentofu:latest \
    init

# Creating plan file
nerdctl run \
    --workdir=/srv/workspace \
    --mount type=bind,source=.,target=/srv/workspace \
    ghcr.io/opentofu/opentofu:latest \
    plan -out=main.plan

# Applying plan file
nerdctl run \
    --workdir=/srv/workspace \
    --mount type=bind,source=.,target=/srv/workspace \
    ghcr.io/opentofu/opentofu:latest \
    apply "/srv/workspace/main.plan"
```

## Automation
