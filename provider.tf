terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      
    }
  }
}

provider "aws" {
  region = "us-east-1"
}
#Create VPC
resource "aws_vpc" "myVPC" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "myVPC"
  }
}
#Create Internet Gateway
resource "aws_internet_gateway" "InternetGateway" {
  vpc_id = aws_vpc.myVPC.id

  tags = {
    Name = "myVPC Internet Gateway"
  }
}
#Create Public Subnet 1
resource "aws_subnet" "public_subnet_1" {
  vpc_id     = aws_vpc.myVPC.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  tags={
    Name = "Public Subnet 1"
  }
}
#Create Private Subnet 1
resource "aws_subnet" "private_subnet_1" {
  vpc_id     = aws_vpc.myVPC.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags={
    Name = "Private Subnet 1"
  }
}
#Create Public Subnet 2
resource "aws_subnet" "public_subnet_2" {
  vpc_id     = aws_vpc.myVPC.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags={
    Name = "Public Subnet 2"
  }
}
#Create Private Subnet 2
resource "aws_subnet" "private_subnet_2" {
  vpc_id     = aws_vpc.myVPC.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1b"
  tags={
    Name = "Private Subnet 2"
  }
}