terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.92.0"
    }
  }
}

provider "aws" {}

variable "prefix" {
  type = string
  default = "project-delta"
}

variable "vpc_cidr_block" {
  type = string
  default = "10.0.0.0/16"
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "${var.prefix}-vpc"
  }
}

variable "subnet_cidr_block" {
  type = string
  default = "10.0.1.0/24"
}

# resource_type.resource_name/logical_name.attribute
# aws_vpc.main.id
# Terraform Resource Address
resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.subnet_cidr_block

  tags = {
    Name = "${var.prefix}-subnet"
  }
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "${var.prefix}-sg"
  }
}

variable "allow_ssh" {
  type = bool
  default = false
}

# variable "allow_ssh_count" {
#   type = number
#   default = 1
# }

            #  `is true` means `?`   `otherwise` means `:`
            # if var.allow_ssh is true create 1 otherwise create 0
            #  count             = var.allow_ssh ? 1 : 0
resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  count             = var.allow_ssh ? 1 : 0
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv4         = aws_vpc.main.cidr_block
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  subnet_id = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  tags = {
    Name = "${var.prefix}-ec2"
  }
}
