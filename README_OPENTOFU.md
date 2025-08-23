OpenTofu
========

Local usage
-----------

Exoscale provider
-----------------

The directory 'iac-exoscale' contains the Infra-as-code scripts for [ExoScale](https://www.exoscale.com/), the current platform provider of choice.

The infrastructure is described as [Terraform](https://opentofu.org/) files, with the [Exoscale](provider).

The Terraform files defines the desired resources on the platform. OpenTofu uses the terraform files to create a plan for which changes to make to the platform. The plan can be fed back into OpenTofu to enact the changes.

The file `main.tf` contains all the resources that are desired during "normal operations".

Directory structure for exoscale, with short descriptions:
```
/iac-exoscale
  main.tf #main terraform file that describes all infra on exoscale platform
  tofu.sh #wrapper-util for executing opentofuy locally
  *secret_keys.auto.tfvars #secret variables that opentofu automatically picks up
  *helm-values.yaml #configuration values for helm terraform provider
  *application.yaml #configuration resource for kubectl provider
  /terraform #terraform/opentofu metadata and temp storage
```

Exoscale secrets: In order to access the Exoscale api, a secret 'api_key' and 'api_secret' needs to be passed to opentofu. 
Add these to a '*.auto.tfvars' file and ensure it is ignored by git.
