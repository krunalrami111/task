provider "aws" {
    region = "ap-south-1"
}

resource "aws_vpc" "demo_vpc" {
  cidr_block       = "192.168.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  instance_tenancy = "default" 

  tags = {
    Name = "My Demo VPC"
  }
}

resource "aws_subnet" "public-1" {
  vpc_id     = aws_vpc.demo_vpc.id
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "Public Subnet"
  }
}

resource "aws_subnet" "private-1" {
  vpc_id     = aws_vpc.demo_vpc.id
  cidr_block = "192.168.3.0/24"
  availability_zone = "ap-south-1c"

  tags = {
    Name = "Private Subnet"
  }
}

resource "aws_subnet" "private-2" {
  vpc_id     = aws_vpc.demo_vpc.id
  cidr_block = "192.168.2.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "Private Subnet"
  }
}
resource "aws_internet_gateway" "demo_vpc_igw" {
  vpc_id = aws_vpc.demo_vpc.id

  tags = {
    Name = "My Demo VPC - Internet Gateway"
  }
}

resource "aws_route_table" "demo_vpc_public_route" {
    vpc_id = aws_vpc.demo_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.demo_vpc_igw.id
    }

    tags = {
        Name = "Public Subnet Route Table."
    }
}

resource "aws_route_table_association" "demo_vpc_public_route" {
    subnet_id = aws_subnet.public-1.id
    route_table_id = aws_route_table.demo_vpc_public_route.id
}

