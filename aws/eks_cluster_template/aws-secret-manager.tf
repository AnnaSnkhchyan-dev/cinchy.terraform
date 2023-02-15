#------------------------------------------------------------------------------------
# This creates a IAM Policy content limiting access to the secret in Secrets Manager
#------------------------------------------------------------------------------------

data "aws_iam_policy_document" "<<namespace>>_secrets_management_policy" {
  statement {
    sid    = ""
    effect = "Allow"
    resources = <<aws_secrets_manager_arn_list>>
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
  }
}

#---------------------------------------------------------------
# Creating IAM Policy to be attached to the IRSA Role
#---------------------------------------------------------------

resource "aws_iam_policy" "<<namespace>>_aws_iam_policy" {
  description = "AWS Secret Manager IAM Policy for IRSA"
  name        = "${module.eks.cluster_id}-irsa-<<namespace>>"
  policy      = data.aws_iam_policy_document.<<namespace>>_secrets_management_policy.json
}

# Create a Namespace
resource kubernetes_namespace <<namespace>> {
  count = local.create_service_accounts == true ? 1 : 0
  metadata {
    name = "<<namespace>>"
    labels = {
      "env"                        = "<<namespace>>"
      "istio-injection"            = "enabled"
    }
  }
}

#---------------------------------------------------------------
# Creating IAM Role for Service Account
#---------------------------------------------------------------
module "<<namespace>>-iam-role-connections-serviceaccount" {
  source                     = "../../terraform_modules/irsa"
  create_kubernetes_namespace = false
  count = local.create_service_accounts == true ? 1 : 0
  eks_cluster_id             = module.eks.cluster_id
  eks_oidc_provider_arn      = module.eks.oidc_provider_arn
  kubernetes_namespace       = "<<namespace>>"
  kubernetes_service_account = "connections-serviceaccount"
  irsa_iam_policies          = [aws_iam_policy.<<namespace>>_aws_iam_policy.arn]

  depends_on = [
    module.eks,
    kubernetes_namespace.<<namespace>>
  ]
}

module "<<namespace>>-iam-role-event-listener-serviceaccount" {
  source                     = "../../terraform_modules/irsa"
  create_kubernetes_namespace = false
  count = local.create_service_accounts == true ? 1 : 0
  eks_cluster_id             = module.eks.cluster_id
  eks_oidc_provider_arn      = module.eks.oidc_provider_arn
  kubernetes_namespace       = "<<namespace>>"
  kubernetes_service_account = "event-listener-serviceaccount"
  irsa_iam_policies          = [aws_iam_policy.<<namespace>>_aws_iam_policy.arn]

  depends_on = [
    module.eks,
    kubernetes_namespace.<<namespace>>
  ]
}

module "<<namespace>>-iam-role-forms-serviceaccount" {
  source                     = "../../terraform_modules/irsa"
  create_kubernetes_namespace = false
  count = local.create_service_accounts == true ? 1 : 0
  eks_cluster_id             = module.eks.cluster_id
  eks_oidc_provider_arn      = module.eks.oidc_provider_arn
  kubernetes_namespace       = "<<namespace>>"
  kubernetes_service_account = "forms-serviceaccount"
  irsa_iam_policies          = [aws_iam_policy.<<namespace>>_aws_iam_policy.arn]

  depends_on = [
    module.eks,
    kubernetes_namespace.<<namespace>>
  ]
}

module "<<namespace>>-iam-role-idp-serviceaccount" {
  source                     = "../../terraform_modules/irsa"
  create_kubernetes_namespace = false
  count = local.create_service_accounts == true ? 1 : 0
  eks_cluster_id             = module.eks.cluster_id
  eks_oidc_provider_arn      = module.eks.oidc_provider_arn
  kubernetes_namespace       = "<<namespace>>"
  kubernetes_service_account = "idp-serviceaccount"
  irsa_iam_policies          = [aws_iam_policy.<<namespace>>_aws_iam_policy.arn]

  depends_on = [
    module.eks,
    kubernetes_namespace.<<namespace>>
  ]
}

module "<<namespace>>-iam-role-maintenance-cli-serviceaccount" {
  source                     = "../../terraform_modules/irsa"
  create_kubernetes_namespace = false
  count = local.create_service_accounts == true ? 1 : 0
  eks_cluster_id             = module.eks.cluster_id
  eks_oidc_provider_arn      = module.eks.oidc_provider_arn
  kubernetes_namespace       = "<<namespace>>"
  kubernetes_service_account = "maintenance-cli-serviceaccount"
  irsa_iam_policies          = [aws_iam_policy.<<namespace>>_aws_iam_policy.arn]

  depends_on = [
    module.eks,
    kubernetes_namespace.<<namespace>>
  ]
}

module "<<namespace>>-iam-role-web-serviceaccount" {
  source                     = "../../terraform_modules/irsa"
  create_kubernetes_namespace = false
  count = local.create_service_accounts == true ? 1 : 0
  eks_cluster_id             = module.eks.cluster_id
  eks_oidc_provider_arn      = module.eks.oidc_provider_arn
  kubernetes_namespace       = "<<namespace>>"
  kubernetes_service_account = "web-serviceaccount"
  irsa_iam_policies          = [aws_iam_policy.<<namespace>>_aws_iam_policy.arn]

  depends_on = [
    module.eks,
    kubernetes_namespace.<<namespace>>
  ]
}

module "<<namespace>>-iam-role-worker-serviceaccount" {
  source                     = "../../terraform_modules/irsa"
  create_kubernetes_namespace = false
  count = local.create_service_accounts == true ? 1 : 0
  eks_cluster_id             = module.eks.cluster_id
  eks_oidc_provider_arn      = module.eks.oidc_provider_arn
  kubernetes_namespace       = "<<namespace>>"
  kubernetes_service_account = "worker-serviceaccount"
  irsa_iam_policies          = [aws_iam_policy.<<namespace>>_aws_iam_policy.arn]

  depends_on = [
    module.eks,
    kubernetes_namespace.<<namespace>>
  ]
}