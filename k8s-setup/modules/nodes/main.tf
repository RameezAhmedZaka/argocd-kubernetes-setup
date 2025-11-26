
resource "aws_security_group" "master_sg" {
  name        = "master-sg"
  description = "Security group for Kubernetes master nodes"
  vpc_id      = var.vpc_id

  # Dynamic ports from your original config
  dynamic "ingress" {
    for_each = var.inbound_ports_for_master
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = [var.ingress_cidr_block]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.egress_cidr_block]
  }

  tags = {
    Name = "${var.environment}-kubernetes-master-sg"
  }
}
resource "aws_security_group" "worker_sg" {
  name        = "worker-sg"
  description = "Security group for Kubernetes worker nodes"
  vpc_id      = var.vpc_id

  # Dynamic ports from your original config
  dynamic "ingress" {
    for_each = var.inbound_ports_for_worker
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = [var.ingress_cidr_block]
    }
  }

  ingress {
    description = "Allow Worker to reach Master K8s API"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "Kubernetes NodePort range"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.egress_cidr_block]
  }

  tags = {
    Name = "${var.environment}-kubernetes-worker-sg"
  }
}
resource "aws_security_group_rule" "worker_kubelet" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = aws_security_group.worker_sg.id
  source_security_group_id = aws_security_group.master_sg.id
}

resource "aws_instance" "master" {
  ami                         = var.ami_id
  instance_type               = var.instance_type_master
  subnet_id                   = var.private_subnet_ids[0]
  vpc_security_group_ids      = [aws_security_group.master_sg.id]
  key_name                    = var.key_name
  associate_public_ip_address = false
  iam_instance_profile        = var.iam_instance_profile

  # user_data = file("${path.module}/user_data_master.sh")
  user_data = templatefile("${path.module}/user_data_master.sh", {
    environment = var.environment
  })

  tags = {
    Name    = "${var.environment}-${var.master_node_name}"
    Role    = var.master_node_role
    Cluster = var.master_node_cluster
  }
}

resource "null_resource" "wait_for_join" {
  depends_on = [aws_instance.master]

  provisioner "local-exec" {
    command = <<EOT
echo "Sleeping for 200 seconds to allow master user-data to complete..."
sleep 200
echo "Waiting for /${var.environment}/k8s/join-command SSM parameter..."
while [ -z "$(aws ssm get-parameter --name "/${var.environment}/k8s/join-command" --region us-east-1 --query "Parameter.Value" --output text 2>/dev/null)" ]; do
  sleep 5
done
echo "SSM parameter exists, continuing..."
EOT
  }
}


resource "aws_instance" "workers" {
  count                       = 2
  ami                         = var.ami_id
  instance_type               = var.instance_type_worker
  subnet_id                   = element(var.private_subnet_ids, count.index + 1)
  vpc_security_group_ids      = [aws_security_group.worker_sg.id]
  key_name                    = var.key_name
  associate_public_ip_address = false
  iam_instance_profile        = var.iam_instance_profile
  # user_data                   = file("${path.module}/user_data_worker.sh")
  user_data = templatefile("${path.module}/user_data_worker.sh", {
    environment = var.environment
  })

  depends_on = [aws_instance.master, null_resource.wait_for_join]

  tags = {
    Name    = "${var.environment}-${var.worker_node_name}-${count.index + 1}"
    Role    = var.worker_node_role
    Cluster = var.worker_node_cluster


  }
}

resource "aws_ssm_document" "run_join_command" {
  name          = "${var.environment}-${var.run_join_command-name}"
  depends_on    = [aws_instance.workers, aws_instance.master]
  document_type = var.document_type

  content = jsonencode({
    schemaVersion = "2.2",
    description   = "Run the kubeadm join command with retry loop",
    mainSteps = [
      {
        action = "aws:runShellScript",
        name   = "runJoin",
        inputs = {
          runCommand = [
            "region=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | cut -d\\\" -f4)",
            "for i in {1..30}; do",
            "  JOIN_CMD=$(aws ssm get-parameter --name /${var.environment}/k8s/join-command --region $region --query 'Parameter.Value' --output text 2>/dev/null)",
            "  if [ -n \"$JOIN_CMD\" ]; then",
            "    sudo $JOIN_CMD",
            "    break",
            "  fi",
            "  echo \"Waiting for master... attempt $i\"",
            "  sleep 10",
            "done"
          ]
        }
      }
    ]
  })
}


resource "aws_ssm_document" "configure_kubeconfig" {
  name          = "${var.environment}-${var.configure_kubeconfig_name}"
  document_type = var.document_type

  content = jsonencode({
    schemaVersion = "2.2",
    description   = "Fetch and configure kubeconfig",
    mainSteps = [
      {
        action = "aws:runShellScript",
        name   = "setupKubeconfig",
        inputs = {
          runCommand = [
            "#!/bin/bash",
            "mkdir -p ~/.kube",
            "aws ssm get-parameter --name /${var.environment}/k8s/kubeconfig --region ${var.region} --query 'Parameter.Value' --output text > ~/.kube/config",
            "chmod 600 ~/.kube/config"
          ]
        }
      }
    ]
  })
}