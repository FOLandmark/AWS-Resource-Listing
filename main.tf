# Create a VPC
resource "aws_vpc" "CE" {
  cidr_block = "10.0.0.0/16"

 tags = {
    Name = "testNuvei"
  }
}

# Create two public subnets

#Public Subnet 1
resource "aws_subnet" "pbsn1" {
  vpc_id = aws_vpc.CE.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
 tags = {
    Name = "Public Subnet 1"
  }
}

#Public Subnet 2
resource "aws_subnet" "pbsn2" {
  vpc_id = aws_vpc.CE.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
 tags = {
    Name = "Public Subnet 2"
  }
}

#Private Subnet 1
# Create two private subnets
resource "aws_subnet" "pvsn1" {
  vpc_id = aws_vpc.CE.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1a"
 tags = {
    Name = "Private Subnet 1"
  }
}

#Private Subnet 2
resource "aws_subnet" "pvsn2" {
  vpc_id = aws_vpc.CE.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1b"
 tags = {
    Name = "Private Subnet 2"
  }
}

# Create internet gateway
resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.CE.id
 tags = {
    Name = "Test CE_VPC_IGW"
  }
}

# Create route tables

#Public Route Table 1
resource "aws_route_table" "pbrt1" {
  vpc_id = aws_vpc.CE.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW.id
  }
 tags = {
    Name = "Public RT1"
  }
}


#Public Route Table 2
resource "aws_route_table" "pbrt2" {
  vpc_id = aws_vpc.CE.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW.id
  }
   tags = {
    Name = "Public RT2"
  }
}

#Private Route Table 1
resource "aws_route_table" "pvrt1" {
  vpc_id = aws_vpc.CE.id
   tags = {
    Name = "Private RT1"
  }
}

#Private Route Table 2
resource "aws_route_table" "pvrt2" {
  vpc_id = aws_vpc.CE.id
   tags = {
    Name = "Private RT2"
  }
}

# Associate route tables with subnets
resource "aws_route_table_association" "public_association_1" {
  subnet_id = aws_subnet.pbsn1.id
  route_table_id = aws_route_table.pbrt1.id

}

resource "aws_route_table_association" "public_association_2" {
  subnet_id = aws_subnet.pbsn2.id
  route_table_id = aws_route_table.pbrt2.id
}

resource "aws_route_table_association" "private_association_1" {
  subnet_id = aws_subnet.pvsn1.id
  route_table_id = aws_route_table.pvrt1.id
}

resource "aws_route_table_association" "private_association_2" {
  subnet_id = aws_subnet.pvsn2.id
  route_table_id = aws_route_table.pvrt2.id
}


# Create a security group
resource "aws_security_group" "testSG" {
  name_prefix = "testSG"
  vpc_id = aws_vpc.CE.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "testSG"
  }
}


# Define variables stored in terraform.tfvars
variable "domain_name" {
  description = "The name of the domain to create in Route53."
  type        = string
}

variable "elb_name" {
  description = "The name of the ELB to create."
  type        = string
}

variable "subnet_ids" {
  description = "A list of subnet IDs in which to place the ELB."
  type        = list(string)
}

variable "vpc_id" {
  description = "The ID of the VPC in which to create the ELB."
  type        = string
}

# Create the ELB
resource "aws_elb" "elb1" {
  name               = var.elb_name
  
  subnets            = [aws_subnet.pbsn1.id, aws_subnet.pbsn2.id]
  #subnet            = var.subnet_id2.id
  security_groups    = [aws_security_group.testSG.id]
  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }
  listener {
    instance_port     = 443
    instance_protocol = "HTTPS"
    lb_port           = 443
    lb_protocol       = "HTTPS"
    ssl_certificate_id = "arn:aws:acm:us-east-1:804115843256:certificate/364119bb-8f9c-4515-ac03-05fcb484fc4f"
  }
}

# Create the Route53 hosted zone
resource "aws_route53_zone" "CE_Test" {
  name = var.domain_name
}

# Create the CNAME record for the ELB
resource "aws_route53_record" "CE_Test" {
  zone_id = "Z01002193LGXMWNQITFGQ" 
  name    = "www.coldenergytek.com"
  type    = "CNAME"
  ttl     = "300"
  records = ["api.coldenergytek.com"]
}


