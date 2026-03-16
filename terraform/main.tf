terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Clé SSH
resource "aws_key_pair" "devops_key" {
  key_name   = "devops-key"
  public_key = file(var.public_key_path)
}

# Security Group
resource "aws_security_group" "devops_sg" {
  name        = "devops-security-group"
  description = "Security group for DevOps cluster"

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # API App (port 8080 - 5000 et 3000 déjà utilisés)
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kubernetes API
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # NodePort Kubernetes
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Communication interne cluster
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devops-sg"
  }
}

# Master Node
resource "aws_instance" "master" {
  ami           = var.ami_id
  instance_type = "t2.micro"  # Free tier 750h

  key_name               = aws_key_pair.devops_key.key_name
  vpc_security_group_ids = [aws_security_group.devops_sg.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp2"
  }

  tags = {
    Name = "k8s-master"
    Role = "master"
  }
}

# Worker Node
resource "aws_instance" "worker" {
  ami           = var.ami_id
  instance_type = "t2.micro"  # Free tier 750h

  key_name               = aws_key_pair.devops_key.key_name
  vpc_security_group_ids = [aws_security_group.devops_sg.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp2"
  }

  tags = {
    Name = "k8s-worker"
    Role = "worker"
  }
}

# Outputs utiles
output "master_ip" {
  value       = aws_instance.master.public_ip
  description = "IP publique du master Kubernetes"
}

output "worker_ip" {
  value       = aws_instance.worker.public_ip
  description = "IP publique du worker Kubernetes"
}
