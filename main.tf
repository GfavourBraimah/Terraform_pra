provider "aws" {
  region = "eu-west-1"
}

variable "subnet_cidr_block" {}
variable "vpc_cidr_block" {}
variable "avail_zone" {}
variable "env_prefix" {}
variable "my_ip" {}
variable "instance_type" {}
variable "public_key_location" {}

resource "aws_vpc" "myapp-vpc" {
  cidr_block =  var.vpc_cidr_block
  tags = {
    Name:  "${var.env_prefix}-vpc"
  }
}

resource "aws_subnet" "dev-subnet-1" {
 vpc_id = aws_vpc.myapp-vpc.id
 cidr_block = var.subnet_cidr_block
 availability_zone = var.avail_zone
  tags = {
    Name: "${var.env_prefix}-vpc"
  }
}


resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp-vpc.id
    tags = {
    Name: "${var.env_prefix}-igw"
  }
}

resource "aws_default_route_table" "main-rtb" {
  default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myapp-igw.id
  }
    tags = {
    Name: "${var.env_prefix}-main-rtb"
  }

}

resource "aws_default_security_group" "default-sg" {
  vpc_id = aws_vpc.myapp-vpc.id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.my_ip]
  }
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    prefix_list_ids = [ ]
  }

   tags = {
    Name: "${var.env_prefix}-default-sg"
  }

}

data "aws_ami" "Latest-amazon-linux-image" {
  most_recent = true
  owners      = ["137112412989"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.3.20231218.0-kernel-6.1-x86_64"]
  }

  filter {
    name   = "virtualization-type"  
    values = ["hvm"]
  }
}


resource "aws_key_pair" "ssh-key" {
  public_key = file(var.public_key_location)
}


resource "aws_instance" "myapp-server" {
  ami = data.aws_ami.Latest-amazon-linux-image.id
  instance_type = var.instance_type

  subnet_id = aws_subnet.dev-subnet-1.id 
  vpc_security_group_ids = [ aws_default_security_group.default-sg.id ]
  availability_zone = var.avail_zone

  associate_public_ip_address = true 
  key_name = aws_key_pair.ssh-key.key_name
    
     user_data = file("entry.sh")
     tags = {
    Name: "${var.env_prefix}-server"
  }

} 
