#-----------------AWS Managed EKS Add-ons----------------------

# module "aws_vpc_cni" {
#   count         = var.enable_amazon_eks_vpc_cni ? 1 : 0
#   source        = "./aws-vpc-cni"
#   addon_config  = var.amazon_eks_vpc_cni_config
#   addon_context = local.addon_context
#   enable_ipv6   = var.enable_ipv6
# }

# module "aws_coredns" {
#   count         = var.enable_amazon_eks_coredns ? 1 : 0
#   source        = "./aws-coredns"
#   addon_config  = var.amazon_eks_coredns_config
#   addon_context = local.addon_context
# }

# module "aws_kube_proxy" {
#   count         = var.enable_amazon_eks_kube_proxy ? 1 : 0
#   source        = "./aws-kube-proxy"
#   addon_config  = var.amazon_eks_kube_proxy_config
#   addon_context = local.addon_context
# }

#-----------------Kubernetes Add-ons----------------------

# module "cert_manager" {
#   count             = var.enable_cert_manager ? 1 : 0
#   source            = "./cert-manager"
#   helm_config       = var.cert_manager_helm_config
#   manage_via_gitops = var.argocd_manage_add_ons
#   addon_context     = local.addon_context
# }

module "cluster_autoscaler" {
  source = "./cluster-autoscaler"

  count = var.enable_cluster_autoscaler ? 1 : 0

  eks_cluster_version = local.eks_cluster_version
  helm_config         = var.cluster_autoscaler_helm_config
  manage_via_gitops   = var.argocd_manage_add_ons
  addon_context       = local.addon_context
}


module "metrics_server" {
  count             = var.enable_metrics_server ? 1 : 0
  source            = "./metrics-server"
  helm_config       = var.metrics_server_helm_config
  manage_via_gitops = var.argocd_manage_add_ons
  addon_context     = local.addon_context
}

module "aws_load_balancer_controller" {
  count             = var.enable_aws_load_balancer_controller ? 1 : 0
  source            = "./aws-load-balancer-controller"
  helm_config       = var.aws_load_balancer_controller_helm_config
  manage_via_gitops = var.argocd_manage_add_ons
  addon_context     = merge(local.addon_context, { default_repository = local.amazon_container_image_registry_uris[data.aws_region.current.name] })
}

module "csi_secrets_store_provider_aws" {
  count             = var.enable_secrets_store_csi_driver_provider_aws ? 1 : 0
  source            = "./csi-secrets-store-provider-aws"
  helm_config       = var.csi_secrets_store_provider_aws_helm_config
  manage_via_gitops = var.argocd_manage_add_ons
  addon_context     = local.addon_context
}

module "secrets_store_csi_driver" {
  count             = var.enable_secrets_store_csi_driver ? 1 : 0
  source            = "./secrets-store-csi-driver"
  helm_config       = var.secrets_store_csi_driver_helm_config
  manage_via_gitops = var.argocd_manage_add_ons
  addon_context     = local.addon_context
}

module "aws_for_fluent_bit" {
  count                    = var.enable_aws_for_fluentbit ? 1 : 0
  source                   = "./aws-for-fluentbit"
  helm_config              = var.aws_for_fluentbit_helm_config
  irsa_policies            = var.aws_for_fluentbit_irsa_policies
  create_cw_log_group      = var.aws_for_fluentbit_create_cw_log_group
  cw_log_group_name        = var.aws_for_fluentbit_cw_log_group_name
  cw_log_group_retention   = var.aws_for_fluentbit_cw_log_group_retention
  cw_log_group_kms_key_arn = var.aws_for_fluentbit_cw_log_group_kms_key_arn
  manage_via_gitops        = var.argocd_manage_add_ons
  addon_context            = local.addon_context
}