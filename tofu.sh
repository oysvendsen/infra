#!/bin/bash

SCRIPT_NAME=$(basename "$0")

# Colors for output
GREEN="\033[0;32m"
RED="\033[0;31m"
NC="\033[0m"

# Help function
function help_screen() {
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
  $SCRIPT_NAME init
  $SCRIPT_NAME plan
  $SCRIPT_NAME help
  $SCRIPT_NAME kubeconfig > kubeconfig.yaml
EOF
}

function tofu() {
    nerdctl run \
        --workdir=/srv/workspace \
        --mount type=bind,source=.,target=/srv/workspace \
        ghcr.io/opentofu/opentofu:latest \
 	${@}
}

function init() {
    echo -e "${GREEN}Initializing Terraform...${NC}"
    nerdctl run \
        --workdir=/srv/workspace \
        --mount type=bind,source=.,target=/srv/workspace \
        ghcr.io/opentofu/opentofu:latest \
	init
}

function plan() {
    echo -e "${GREEN}Generating Terraform plan...${NC}"
    nerdctl run \
        --workdir=/srv/workspace \
        --mount type=bind,source=.,target=/srv/workspace \
        ghcr.io/opentofu/opentofu:latest \
        plan -out=main.plan
}

function apply() {
    echo -e "${GREEN}Applying Terraform configuration...${NC}"
    nerdctl run \
        --workdir=/srv/workspace \
        --mount type=bind,source=.,target=/srv/workspace \
        ghcr.io/opentofu/opentofu:latest \
        apply main.plan
}

function destroy() {
    echo -e "${RED}Destroying infrastructure...${NC}"
    nerdctl run \
        --workdir=/srv/workspace \
        --mount type=bind,source=.,target=/srv/workspace \
        ghcr.io/opentofu/opentofu:latest \
        destroy -auto-approve
}

function kubeconfig() {
    nerdctl run \
        --workdir=/srv/workspace \
        --mount type=bind,source=.,target=/srv/workspace \
        ghcr.io/opentofu/opentofu:latest \
        output kubernetes_kubeconfig |
    sed 's/^<<EOT//g' |
    sed 's/^EOT//g'
}

function alias_func() {
    echo "no alias' yet"
}

# Main dispatcher
case "$1" in
    init) init ;;
    plan) plan ;;
    apply) apply ;;
    destroy) destroy ;;
    kubeconfig) kubeconfig ;;
    alias) alias_func ;;
    help) help_screen ;;
    ""|*) tofu ${@:1} ;;
esac
