aws_region = "us-east-1"
profile    = "default"

# # VPC
# vpc = {
#   vpc_cidr_block              = "10.0.0.0/16"
#   vpc_name                    = "my-k8s-vpc"
#   internet_gateway            = "k8s-igw"
#   public_subnet_cidr          = ["10.0.8.0/24", "10.0.9.0/24"]
#   private_subnet_cidr         = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24", "10.0.2.0/24"]
#   public_availability_zones   = ["us-east-1a"]
#   private_availability_zones  = ["us-east-1a", "us-east-1b", "us-east-1c"]
#   public_subnet_name          = ["public-subnet-1"]
#   private_subnet_name         = ["k8s-private-subnet-1", "k8s-private-subnet-2", "k8s-private-subnet-3"]
#   route_destination           = "0.0.0.0/0"
#   nat_gateway                 = "k8s-nat"
#   route_table_public          = "k8s-public-rt"
#   route_table_private         = "k8s-private-rt"
#   cidr_block                  = "0.0.0.0/0"
#   eip_name                    = "nat-eip"
# }

existing_vpc_name = "my-vpc"

# Nodes
node = {
  ami_id                    = "ami-0c02fb55956c7d316"
  key_name                  = "test-ec2"
  instance_type_master      = "t2.micro"
  instance_type_worker      = "t2.micro"
  allowed_ip                = "203.0.113.10/32"
  sg_name                   = "zb-k8s-sg"
  sg_description            = "Allow K8s and SSH"
  inbound_ports_for_master  = [6443]
  inbound_ports_for_worker  = [30000, 32767]
  egress_cidr_block         = "0.0.0.0/0"
  master_node_name          = "zb-k8s-master-node"
  master_node_role          = "zb-master"
  master_node_cluster       = "zb-dev-cluster"
  ingress_cidr_block        = "10.0.0.0/16"
  worker_node_cluster       = "zb-dev-cluster"
  worker_node_role          = "zb-worker"
  worker_node_name          = "zb-k8s-worker"
  document_type             = "Command"
  run_join_command_name     = "zubair-RunJoinCommand"
  configure_kubeconfig_name = "zubair-configure-kubeconfig"

}

# IAM
iam = {
  manager_role_name    = "zb-manager-ssm-role"
  node_role_name       = "zb-node-ssm-role"
  manager_profile_name = "zb-manager-ssm-profile"
  node_profile_name    = "zb-node-ssm-profile"
}

# manager Host
manager = {
  ami_id                = "ami-0c02fb55956c7d316"
  manager_name          = "zb-nodes-manager"
  manager_role          = "zb-manager"
  manager_cluster       = "zb-dev-cluster"
  manager_sg_name       = "zb-nodes-manager-sg"
  manager_instance_type = "t2.micro"
  user_data_file        = "./user_data_ssm.sh"
  subnet_index          = 2
}


