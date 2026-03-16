##VPC

resource "aws_vpc" "serverless_vpc" {
    cidr_block = "192.168.0.0/16"
    instance_tenancy = "default"

    enable_dns_hostnames = true
    enable_dns_support = true
  
}


##Internet gateway
resource "aws_internet_gateway" "vpc_gateway" {
    vpc_id = aws_vpc.serverless_vpc.id
  
}

data "aws_availability_zones" "availability_zones" {}

##Public subnet for bastion host
resource "aws_subnet" "bastion_host" {
    cidr_block = "192.168.10.0/24"
    vpc_id = aws_vpc.serverless_vpc.id
    map_public_ip_on_launch = true
    availability_zone = data.aws_availability_zones.availability_zones.names[0]
  
}

##Private Subnet for RDS
resource "aws_subnet" "rds_private_subnet1a" {

    cidr_block = "192.168.1.0/24"
    vpc_id = aws_vpc.serverless_vpc.id
    availability_zone = data.aws_availability_zones.availability_zones.names[0]
    map_public_ip_on_launch = false
}

resource "aws_subnet" "rds_private_subnet1b" {

    cidr_block = "192.168.3.0/24"
    vpc_id = aws_vpc.serverless_vpc.id
    availability_zone = data.aws_availability_zones.availability_zones.names[1]
    map_public_ip_on_launch = false
}


### Private subnet for Lambda

resource "aws_subnet" "lambda_private_subnet1a" {
    cidr_block = "192.168.2.0/24"
    vpc_id = aws_vpc.serverless_vpc.id
    availability_zone = data.aws_availability_zones.availability_zones.names[0]
    map_public_ip_on_launch = false
  
}

resource "aws_subnet" "lambda_private_subnet1b" {
    cidr_block = "192.168.4.0/24"
    vpc_id = aws_vpc.serverless_vpc.id
    availability_zone = data.aws_availability_zones.availability_zones.names[1]
    map_public_ip_on_launch = false
  
}

### Security Groups

resource "aws_security_group" "lambda_sgroup" {
  name = "lambda-vpc-sg"
  vpc_id = aws_vpc.serverless_vpc.id
}

resource "aws_security_group" "rds_sgroup" {
 name = "rds-vpc-sg"
 vpc_id = aws_vpc.serverless_vpc.id
}


##Create rule to Prevent Circulary Dependencies
resource "aws_security_group_rule" "lambda_egress_rds" {
    type = "egress"
    from_port = 3306
    to_port = 3306
    security_group_id = aws_security_group.lambda_sgroup.id ##point to the lambda security-group above
    source_security_group_id = aws_security_group.rds_sgroup.id ## points to rds security group that will send data to lambda
    protocol = "tcp"
  
}

resource "aws_security_group_rule" "rds_ingress_lambda" {
    type = "ingress"
    from_port = 3306
    to_port = 3306
    security_group_id = aws_security_group.rds_sgroup.id
    source_security_group_id = aws_security_group.lambda_sgroup.id
    protocol = "tcp"
  
}

resource "aws_security_group_rule" "rds_egress" {
    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    security_group_id = aws_security_group.rds_sgroup.id
    cidr_blocks = [ "0.0.0.0/0" ]
}
