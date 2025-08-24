terraform {
  required_providers {
    exoscale = {
      source = "exoscale/exoscale"
      version = "0.64.1"
    }
    helm = {
      source = "hashicorp/helm"
      version = "3.0.0-pre2"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
      version = "1.19.0"
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

resource "exoscale_sks_cluster" "kubernetes" {
  zone = "ch-gva-2"
  name = "kubernetes"
  service_level = "starter"
}

output "kubernetes_endpoint" {
  value = exoscale_sks_cluster.kubernetes.endpoint
}

resource "exoscale_sks_nodepool" "kubernetes_nodepool" {
  cluster_id         = exoscale_sks_cluster.kubernetes.id
  zone               = exoscale_sks_cluster.kubernetes.zone
  name               = "kubernetes-nodepool"

  instance_type      = "standard.medium"
  size               = 1
  security_group_ids = [
    exoscale_security_group.sks_security_group.id
  ]
}

#https://community.exoscale.com/product/compute/containers/quick-start/
resource "exoscale_security_group" "sks_security_group" {
  name = "sks-security-group"
}

resource "exoscale_security_group_rule" "nodeport_services" {
  security_group_id = exoscale_security_group.sks_security_group.id
  type              = "INGRESS"
  protocol          = "TCP"
  cidr              = "0.0.0.0/0"
  start_port        = 30000
  end_port          = 32767
}

resource "exoscale_security_group_rule" "sks_kubelet" {
  security_group_id = exoscale_security_group.sks_security_group.id
  type              = "INGRESS"
  protocol          = "TCP"
  user_security_group_id = exoscale_security_group.sks_security_group.id
  start_port        = 10250
  end_port          = 10250
}

resource "exoscale_security_group_rule" "calico_traffic" {
  security_group_id = exoscale_security_group.sks_security_group.id
  type              = "INGRESS"
  protocol          = "TCP"
  user_security_group_id = exoscale_security_group.sks_security_group.id
  start_port        = 4789 
  end_port          = 4789 
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

provider "helm" {
  kubernetes = {
    host     = exoscale_sks_cluster.kubernetes.endpoint

    client_certificate     = base64decode(yamldecode(exoscale_sks_kubeconfig.kubernetes_kubeconfig.kubeconfig).users[0].user.client-certificate-data)
    client_key             = base64decode(yamldecode(exoscale_sks_kubeconfig.kubernetes_kubeconfig.kubeconfig).users[0].user.client-key-data)
    cluster_ca_certificate = base64decode(yamldecode(exoscale_sks_kubeconfig.kubernetes_kubeconfig.kubeconfig).clusters[0].cluster.certificate-authority-data)
  }

  registries = []
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = "argocd"
  create_namespace = true

  version = "8.0.14"
  
  values = [
    file("${path.module}/argocd-values.yaml")
  ]

  depends_on = [
    exoscale_sks_cluster.kubernetes,
    exoscale_sks_nodepool.kubernetes_nodepool
  ]
}

provider "kubectl" {
  host     = exoscale_sks_cluster.kubernetes.endpoint

  client_certificate     = base64decode(yamldecode(exoscale_sks_kubeconfig.kubernetes_kubeconfig.kubeconfig).users[0].user.client-certificate-data)
  client_key             = base64decode(yamldecode(exoscale_sks_kubeconfig.kubernetes_kubeconfig.kubeconfig).users[0].user.client-key-data)
  cluster_ca_certificate = base64decode(yamldecode(exoscale_sks_kubeconfig.kubernetes_kubeconfig.kubeconfig).clusters[0].cluster.certificate-authority-data)

  load_config_file       = false
}

resource "kubectl_manifest" "argocd-infra-gitops-app" {
  yaml_body = file("${path.module}/argocd-application.yaml")

  depends_on = [
    helm_release.argocd
  ]
}

resource "exoscale_dbaas" "test_postgres" {
  name = "test-postgres"
  plan = "Hobbyist-2"
  type = "pg"
  zone = exoscale_sks_cluster.kubernetes.zone

  #pg = {
  #  admin_username =
  #  admin_password =
  #  ip_filter =
  #  pg_settings =
  #}
}