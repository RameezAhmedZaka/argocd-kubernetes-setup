provider "aws" {
  region = var.aws_region
  profile = var.profile
}

terraform {
  required_version = ">= 0.13.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
  }
}


provider "kubectl" {
  host                   = "https://${module.nodes.master_private_ip}:6443"
  client_certificate     = base64decode(yamldecode(data.aws_ssm_parameter.kubeconfig.value)["users"][0]["user"]["client-certificate-data"])
  client_key             = base64decode(yamldecode(data.aws_ssm_parameter.kubeconfig.value)["users"][0]["user"]["client-key-data"])
  load_config_file       = false
  insecure               = true
}

# ----------------------------
# helm provider
# ----------------------------
provider "helm" {
  kubernetes = {
    host                   = "https://${module.nodes.master_private_ip}:6443"
    client_certificate     = base64decode(yamldecode(data.aws_ssm_parameter.kubeconfig.value)["users"][0]["user"]["client-certificate-data"])
    client_key             = base64decode(yamldecode(data.aws_ssm_parameter.kubeconfig.value)["users"][0]["user"]["client-key-data"])
    load_config_file       = false
    insecure               = true
  }
}


provider "kubernetes" {
  host                   = "https://${module.nodes.master_private_ip}:6443"
  client_certificate     = base64decode(yamldecode(data.aws_ssm_parameter.kubeconfig.value)["users"][0]["user"]["client-certificate-data"])
  client_key             = base64decode(yamldecode(data.aws_ssm_parameter.kubeconfig.value)["users"][0]["user"]["client-key-data"])
  insecure               = true
}

