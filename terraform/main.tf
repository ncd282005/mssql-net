provider "aws" {
  region = "us-east-1"
  access_key = var.Access_key
  secret_key = var.Secret_key
}

# VPC
resource "aws_vpc" "project" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "project-vpc"
  }
}

# Public Subnet
resource "aws_subnet" "project_sub_pub" {
  vpc_id                  = aws_vpc.project.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

# Private Subnet
resource "aws_subnet" "project_sub_pvt" {
  vpc_id            = aws_vpc.project.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "private-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "project_igw" {
  vpc_id = aws_vpc.project.id

  tags = {
    Name = "project-igw"
  }
}

# Route Table
resource "aws_route_table" "project_route" {
  vpc_id = aws_vpc.project.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.project_igw.id
  }

  tags = {
    Name = "project-route"
  }
}

# Route Table Association
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.project_sub_pub.id
  route_table_id = aws_route_table.project_route.id
}

# Security Group
resource "aws_security_group" "mssql_dotnet_sg" {
  name        = "mssql-dotnet-sg"
  description = "Allow RDP and App Port"
  vpc_id      = aws_vpc.project.id

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance
resource "aws_instance" "mssql_dotnet" {
  ami                    = "ami-05cf1e9f73fbad2e2"
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.project_sub_pub.id
  vpc_security_group_ids = [aws_security_group.mssql_dotnet_sg.id]
  key_name               = "devops-shine"

  tags = {
    Name = "mssql-dotnet-server"
  }
}