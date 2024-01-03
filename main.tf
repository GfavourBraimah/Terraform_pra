provider "aws" {
  region     = "eu-west-3"

}


variable "cidr_block" {
  description = "cidr blocks for vpc and subnets"
  type = list(object({
    cidr_block = string 
    name = string
  }))

}

resource "aws_vpc" "development-vpc" {
  cidr_block = var.cidr_block[0].cidr_block
  tags = {
    Name: var.cidr_block[0].name 
  }
}

resource "aws_subnet" "dev_subnet-1" {
  vpc_id            = aws_vpc.development-vpc.id
  cidr_block        = var.cidr_block[1].cidr_block
  availability_zone = "eu-west-3a"
  tags = {
    Name: var.cidr_block[1].name 
  }
}