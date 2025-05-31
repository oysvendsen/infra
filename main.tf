terraform {
  required_providers {
    exoscale = {
      source = "exoscale/exoscale"
      version = "0.64.1"
    }
  }
}

variable "api_key" {
  type        = string
  description = "Api Key for the provider."
  sensitive   = true
  validation {
    condition     = length(var.api_key) > 0
    error_message = "Value must not be empty."
  }
}

variable "api_secret" {
  type = string
  description = "Api secret for the provider."
  sensitive = true
  validation {
    condition     = length(var.api_secret) > 0
    error_message = "Value must not be empty."
  }
}

provider "exoscale" {
  key=var.api_key
  secret=var.api_secret
}

# Create a kubernetes cluster "kube" 
resource "exoscale_sks_cluster" "kubernetes" {
  zone = "ch-gva-2"
  name = "kubernetes"
}

output "my_sks_cluster_endpoint" {
  value = exoscale_sks_cluster.kubernetes.endpoint
}

resource "exoscale_sks_nodepool" "my_sks_nodepool" {
  cluster_id         = exoscale_sks_cluster.kubernetes.id
  zone               = exoscale_sks_cluster.kubernetes.zone
  name               = "kubernetes-nodepool"

  instance_type      = "standard.medium"
  size               = 3
}

resource "exoscale_sks_kubeconfig" "kubernetes_kubeconfig" {
  cluster_id = exoscale_sks_cluster.kubernetes.id
  zone       = exoscale_sks_cluster.kubernetes.zone

  user   = "kubernetes-admin"
  groups = ["system:masters"]
}

output "kubernetes_kubeconfig" {
  sensitive = true
  value = exoscale_sks_kubeconfig.kubernetes_kubeconfig.kubeconfig
}
