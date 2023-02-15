
locals {
  subnet_ids = <<subnet_ids>>
  create_service_accounts = <<enable_aws_secret_manager>>
}

################################################################################
# EC2 Key Pair Module
################################################################################


resource "tls_private_key" "this" {
  algorithm = "RSA"
}

module "key_pair" {
  source = "../../terraform_modules/key-pair"

  key_name   = "<<key_name>>"
  public_key = tls_private_key.this.public_key_openssh
}

output "private_key" {
  value     = tls_private_key.this.private_key_pem
  sensitive = true
}

################################################################################
# S3 Buket Module
################################################################################
resource "aws_s3_bucket" "bucket" {
  bucket = "<<cinchy_s3_bucket>>"
  
  tags = {
    Environment = "<<cinchy_s3_environment_tag>>"
    terraformed = true
  }
}

################################################################################
# EKS Module
################################################################################
module "eks" {
  source = "../../terraform_modules/eks"

  cluster_name                    = "<<cluster_name>>"
  cluster_version                 = "<<cluster_version>>"
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  vpc_id     = "<<vpc_id>>"
  subnet_ids = local.subnet_ids

  # Extend node-to-node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    },
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    },
    ingress_cluster_all = {
      description                   = "Cluster to node all ports/protocols"
      protocol                      = "-1"
      from_port                     = 0
      to_port                       = 0
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }
  # EKS Managed Node Group(s)
  eks_managed_node_group_defaults = {
    ami_type               = "AL2_x86_64"
    disk_size              = <<disk_size>>
    instance_types         = <<instance_types>>
  }

  eks_managed_node_groups = {
    cinchy-nodes-az-1 = {
      min_size     = <<min_size>>
      max_size     = <<max_size>>
      desired_size = <<desired_size>>
      key_name = module.key_pair.key_pair_key_name
      subnet_ids = [local.subnet_ids[0]]
    }
    cinchy-nodes-az-2 = {
      min_size     = <<min_size>>
      max_size     = <<max_size>>
      desired_size = <<desired_size>>
      key_name = module.key_pair.key_pair_key_name
      subnet_ids = [local.subnet_ids[1]]
    }
    cinchy-nodes-az-3 = {
      min_size     = <<min_size>>
      max_size     = <<max_size>>
      desired_size = <<desired_size>>
      key_name = module.key_pair.key_pair_key_name
      subnet_ids = [local.subnet_ids[2]]
    }
  }
}


# ################################################################################
# # RDS Aurora Module
# ################################################################################

module "aurora" {
  source  = "../../terraform_modules/aurora"

  name           = "<<database_instance_name>>"
  database_name  = "<<database_name>>"
  engine         = "aurora-postgresql"
  engine_version = "<<engine_version>>"
  instance_class = "<<instance_class>>"
  port           = 5432
  instances = {
    instance-1 = {}
    # instance-2 = {} # Multi-AZ RDS when you add more than one instances.
  }

  vpc_id  = "<<vpc_id>>"
  subnets = local.subnet_ids
  
  allowed_security_groups = ["${module.eks.cluster_security_group_id}"]
  allowed_cidr_blocks     = <<allowed_cidr_blocks>>
  publicly_accessible     = <<publicly_accessible>>

  storage_encrypted   = true
  apply_immediately   = true
  monitoring_interval = 10

  db_parameter_group_name         = "default.aurora-postgresql14"
  db_cluster_parameter_group_name = "default.aurora-postgresql14"

  enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = {
    Environment = "<<aurora_environment_tag>>"
    terraformed = true
  }
}

output "aurora_rds_password" {
  value     = module.aurora.cluster_master_password
  sensitive = true
}
output "aurora_cluster_endpoint" {
  value     = module.aurora.cluster_endpoint
}


#--------------------------------------------
# Deploy Kubernetes Add-ons with sub module
#--------------------------------------------
module "eks-kubernetes-addons" {
    source = "../../terraform_modules/kubernetes-addons"

    eks_cluster_id                               = module.eks.cluster_id
    #K8s Add-ons
    enable_metrics_server                        = true
    enable_cluster_autoscaler                    = true
    enable_secrets_store_csi_driver_provider_aws = <<enable_aws_secret_manager>>
    enable_secrets_store_csi_driver              = <<enable_aws_secret_manager>>
    depends_on                                   = [module.eks.managed_node_groups]
}

data "aws_region" "current" {}

data "aws_availability_zones" "available" {}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "aws" {
  region = data.aws_region.current.id
  alias  = "default"
}

provider "kubernetes" {
  experiments {
    manifest_resource = true
  }
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster.endpoint
    token                  = data.aws_eks_cluster_auth.cluster.token
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  }
}

#-----------------------------------------------------------------
# Secret and stores in AWS Secret Manager
#-----------------------------------------------------------------

data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "eks_cluster" {
  name = module.eks.cluster_id
}
