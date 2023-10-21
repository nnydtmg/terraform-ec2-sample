# ---------------------------
# プロバイダ設定
# ---------------------------
# AWS
provider "aws" {
  region     = "ap-northeast-1"
}

# 自分のパブリックIP取得用
provider "http" {}

# ---------------------------
# VPC
# ---------------------------
resource "aws_vpc" "handson_vpc"{
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true   # DNSホスト名を有効化
  tags = {
    Name = "terraform-handson-vpc"
  }
}

# ---------------------------
# Subnet
# ---------------------------
resource "aws_subnet" "handson_public_1a_sn" {
  vpc_id            = aws_vpc.handson_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.az_a}"

  tags = {
    Name = "terraform-handson-public-1a-sn"
  }
}

# ---------------------------
# Internet Gateway
# ---------------------------
resource "aws_internet_gateway" "handson_igw" {
  vpc_id            = aws_vpc.handson_vpc.id
  tags = {
    Name = "terraform-handson-igw"
  }
}

# ---------------------------
# Route table
# ---------------------------
# Route table作成
resource "aws_route_table" "handson_public_rt" {
  vpc_id            = aws_vpc.handson_vpc.id
  route {
    cidr_block      = "0.0.0.0/0"
    gateway_id      = aws_internet_gateway.handson_igw.id
  }
  tags = {
    Name = "terraform-handson-public-rt"
  }
}

# SubnetとRoute tableの関連付け
resource "aws_route_table_association" "handson_public_rt_associate" {
  subnet_id      = aws_subnet.handson_public_1a_sn.id
  route_table_id = aws_route_table.handson_public_rt.id
}

# ---------------------------
# Security Group
# ---------------------------
# 自分のパブリックIP取得
data "http" "ifconfig" {
  url = "http://ipv4.icanhazip.com/"
}

variable "allowed_cidr" {
  default = null
}

locals {
  myip          = chomp(data.http.ifconfig.body)
  allowed_cidr  = (var.allowed_cidr == null) ? "${local.myip}/32" : var.allowed_cidr
}

# Security Group作成
resource "aws_security_group" "handson_ec2_sg" {
  name              = "terraform-handson-ec2-sg"
  description       = "For EC2 Linux"
  vpc_id            = aws_vpc.handson_vpc.id
  tags = {
    Name = "terraform-handson-ec2-sg"
  }

  # インバウンドルール
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.allowed_cidr]
  }

  # アウトバウンドルール
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# ---------------------------
# EC2
# ---------------------------
# Amazon Linux 2 の最新版AMIを取得
data "aws_ssm_parameter" "amzn2_latest_ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

# EC2作成
resource "aws_instance" "handson_ec2"{
  ami                         = data.aws_ssm_parameter.amzn2_latest_ami.value
  instance_type               = "t2.micro"
  availability_zone           = "${var.az_a}"
  vpc_security_group_ids      = [aws_security_group.handson_ec2_sg.id]
  subnet_id                   = aws_subnet.handson_public_1a_sn.id
  associate_public_ip_address = "true"
  tags = {
    Name = "terraform-handson-ec2"
  }
}