# ----------------------------
# VPC Data Source
# ----------------------------
data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = ["my-vpc"]
  }
}

# ----------------------------
# Subnets Data Source
# ----------------------------
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  filter {
    name   = "tag:Name"
    values = ["*public*"]
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}

data "aws_ssm_parameter" "kubeconfig" {
  depends_on      = [module.manager.fetch_kubeconfig_id]
  name            = "/${var.environment}/k8s/kubeconfig"
  with_decryption = true
}

# ----------------------------
# Parse kubeconfig YAML
# ----------------------------
locals {
  kubeconfig_yaml = yamldecode(data.aws_ssm_parameter.kubeconfig.value)

  cluster_info = local.kubeconfig_yaml["clusters"][0]["cluster"]
  user_info    = local.kubeconfig_yaml["users"][0]["user"]
}