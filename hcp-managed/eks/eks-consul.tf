# Create Consul namespace
resource "kubernetes_namespace" "consul" {
  metadata {
    name = "consul"
  }
}

# Create Kubernetes secrets for Consul components
resource "kubernetes_secret" "consul_bootstrap_token" {
  metadata {
    name = "bootstrap-token"
    namespace = "consul"
  }

  data = {
    token = "${data.aws_secretsmanager_secret_version.bootstrap_token.secret_string}"
  }

  depends_on = [module.eks.eks_managed_node_groups, 
                kubernetes_namespace.consul
               ]

}

# Install Consul components on EKS
resource "helm_release" "consul" {
  name       = "consul"
  repository = "https://helm.releases.hashicorp.com"
  version    = var.consul_chart_version
  chart      = "consul"
  namespace  = "consul"

  values = [
    templatefile("${path.module}/helm/${var.consul_helm_filename}", {
      datacenter          = hcp_consul_cluster.main.datacenter
      # strip out url scheme from the public url
      consul_hosts        = substr(hcp_consul_cluster.main.consul_public_endpoint_url, 8, -1)
      cluster_id          = hcp_consul_cluster.main.cluster_id
      k8s_api_endpoint    = data.aws_eks_cluster.cluster.endpoint
      consul_version      = hcp_consul_cluster.main.consul_version
      boostrap_acl_token  = hcp_consul_cluster_root_token.token.secret_id
    })
  ]

  depends_on = [module.eks.eks_managed_node_groups,
                module.eks.aws_eks_addon,
                kubernetes_namespace.consul, 
                aws_secretsmanager_secret.bootstrap_token, 
                aws_secretsmanager_secret.ca_cert,
                hcp_consul_cluster.main,
                kubernetes_secret.consul_bootstrap_token,
                module.vpc
                ]
}

## Create API Gateway
data "kubectl_filename_list" "api_gw_manifests" {
  pattern = "${path.module}/api-gw/*.yaml"
}

resource "kubectl_manifest" "api_gw" {
  count     = length(data.kubectl_filename_list.api_gw_manifests.matches)
  yaml_body = file(element(data.kubectl_filename_list.api_gw_manifests.matches, count.index))


  depends_on = [helm_release.consul]
}

locals {
  # non-default context name to protect from using wrong kubeconfig
  kubeconfig_context = "_terraform-kubectl-context-${local.name}_"

  kubeconfig = {
    apiVersion = "v1"
    clusters = [
      {
        name = local.kubeconfig_context
        cluster = {
          certificate-authority-data = data.aws_eks_cluster.cluster.certificate_authority.0.data
          server                     = data.aws_eks_cluster.cluster.endpoint
        }
      }
    ]
    users = [
      {
        name = local.kubeconfig_context
        user = {
          token = data.aws_eks_cluster_auth.cluster.token
        }
      }
    ]
    contexts = [
      {
        name = local.kubeconfig_context
        context = {
          cluster   = local.kubeconfig_context
          user      = local.kubeconfig_context
          namespace = "consul"
        }
      }
    ]
  }
}