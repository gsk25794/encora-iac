#################################################### NETWORKING ####################################################


# NETWORKING #
resource "aws_vpc" "encora-vpc" {
  cidr_block       = "172.31.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "encora-vpc"
  }
}

resource "aws_subnet" "encora-subnet-1" {
  vpc_id     = aws_vpc.encora-vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "encora-subnet-1"
  }
}

resource "aws_subnet" "encora-subnet-2" {
  vpc_id     = aws_vpc.encora-vpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "encora-subnet-2"
  }
}

resource "aws_internet_gateway" "encora-igw" {
  vpc_id = aws_vpc.encora-vpc.id

  tags = {
    Name = "encora-igw"
  }
}
resource "aws_route_table" "encora-rtb" {
  vpc_id = aws_vpc.encora-vpc.id

  route = [
    {
      cidr_block = "10.0.1.0/24"
      gateway_id = aws_internet_gateway.example.id
    },
  ]

}
resource "aws_route_table_association" "encora-rtb-a" {
  subnet_id      = aws_subnet.encora-subnet-1.id
  route_table_id = aws_route_table.encora-rtb.id
}

# SECURITY GROUPS #
resource "aws_security_group" "encora-sg" {
  name   = "encora-sg"
  vpc_id = aws_vpc.encora-vpc.id

  #Allow HTTP from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Enable HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Enable SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Enable SSH"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
