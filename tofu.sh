#!/bin/bash

SCRIPT_NAME=$(basename "$0")
RELATIVE_DIR=$("dirname ${BASH_SOURCE[0]}")
EXOSCALE_DIR="iac-exoscale"

# Colors for output
GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m"

container_image_version="latest"

# Help function
function _help_screen() {
    cat <<EOF
Usage: $SCRIPT_NAME <command>

This script relies on containerd, nerdctl and the opentofu container image to execute terraform files.

Available commands:
  init        Initialize Terraform working directory
  plan        Show the execution plan
  apply       Apply the Terraform configuration
  destroy     Destroy all managed infrastructure
  kubeconfig  Print the kubeconfig from the Terraform state output
  alias       Spits out useful aliases for opentofu
  help        Show this help message
  ''          Just passes arguments to tofu
  -help       Shows the Tofu help screen

Examples:
  ${RELATIVE_DIR}/${SCRIPT_NAME} init
  ${RELATIVE_DIR}/${SCRIPT_NAME} plan
  ${RELATIVE_DIR}/${SCRIPT_NAME} help
  ${RELATIVE_DIR}/${SCRIPT_NAME} kubeconfig > kubeconfig.yaml

  tofu help:
EOF
    _tofu -help
}

function _tofu() {
    nerdctl run \
        --rm \
        --workdir=/srv/workspace \
        --mount type=bind,source=${EXOSCALE_DIR}/.,target=/srv/workspace \
        ghcr.io/opentofu/opentofu:${container_image_version} \
 	${@}
}

function _init() {
    echo -e "${GREEN}Initializing Terraform...${NC}"
    _tofu init
}

function _plan() {
    echo -e "${GREEN}Generating Terraform plan...${NC}"
    _tofu plan -out=.terraform/main.plan
}

function _apply() {
    echo -e "${GREEN}Applying Terraform configuration...${NC}"
    _tofu apply .terraform/main.plan 
}

function _destroy() {
    echo -e "${RED}Destroying infrastructure...${NC}"
    _tofu destroy -auto-approve
}

function _kubeconfig() {
    nerdctl run \
        --rm \
        --workdir=/srv/workspace \
        --mount type=bind,source=.,target=/srv/workspace \
        ghcr.io/opentofu/opentofu:${container_image_version} \
        output kubernetes_kubeconfig |
    sed 's/^<<EOT//g' |
    sed 's/^EOT//g'
}

function _alias_func() {
    echo "alias update_local_kubeconfig='.$(pwd)/tofu.sh kubeconfig > $(pwd)/.terraform/config' #Write kubeconfig to local file"
    echo "export KUBECONFIG='${HOME}/.kube/config:$(pwd)/.terraform/config' #Configure kubeconfig-path to merge standard config and local file."
}

# Main dispatcher
case "$1" in
    init) _init ;;
    plan) _plan ;;
    apply) _apply ;;
    destroy) _destroy ;;
    kubeconfig) _kubeconfig ;;
    alias) _alias_func ;;
    help) _help_screen ;;
    ""|*) _tofu ${@:1} ;;
esac
