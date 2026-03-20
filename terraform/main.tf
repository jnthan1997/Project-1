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

resource "aws_security_group_rule" "lambda_general_egress" {
    type              = "egress"
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = aws_security_group.lambda_sgroup.id
}

resource "aws_security_group_rule" "rds_ingress_lambda" {
    type = "ingress"
    from_port = 3306
    to_port = 3306
    security_group_id = aws_security_group.rds_sgroup.id
    source_security_group_id = aws_security_group.lambda_sgroup.id
    protocol = "tcp"
  
}

resource "aws_security_group_rule" "rds_ingress_bastion" {
    type = "ingress"
    from_port = 3306
    to_port = 3306
    security_group_id = aws_security_group.rds_sgroup.id
    source_security_group_id = aws_security_group.bastion_sg.id
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

#### Security Group for the Bastion host
resource "aws_security_group" "bastion_sg" {
    vpc_id = aws_vpc.serverless_vpc.id
    name = "Bastion-Security" 
}

resource "aws_security_group_rule" "bastion_sg_rule" {
    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "TCP"
    cidr_blocks = ["0.0.0.0/0" ]
    security_group_id = aws_security_group.bastion_sg.id
}

resource "aws_security_group_rule" "bastion_sg_egress" {
    type = "egress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
    security_group_id = aws_security_group.bastion_sg.id
  
}

resource "aws_route_table" "bastion_rt" {
    vpc_id = aws_vpc.serverless_vpc.id
    route  {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.vpc_gateway.id
    }  
    tags = {
      Name = "Route table for bastion host"
    }
}

resource "aws_route_table_association" "bastion_rt_assoc" {
    subnet_id = aws_subnet.bastion_host.id
    route_table_id = aws_route_table.bastion_rt.id  
}