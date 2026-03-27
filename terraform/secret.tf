resource "aws_secretsmanager_secret" "project_secrets" {
    name = "My-Secrets"
    description = "Environment Secrets for RDS and Lambda"
}

resource "aws_secretsmanager_secret_version" "project_secrets_value" {

    secret_id = aws_secretsmanager_secret.project_secrets.id
    secret_string = jsonencode({
        DB_HOST = aws_db_instance.my_rds.address
        DB_USER = "admin"
        DB_PASSWORD = ""
        DB_NAME = ""
        JWT_SECRET = ""

    })
}

### VPC Endpoint for lambda to connect to Secrets Manager

resource "aws_vpc_endpoint" "secret_endpoint" {
  vpc_id = aws_vpc.serverless_vpc.id
  service_name = "com.amazonaws${data.aws_region.current.name}.secretsmanager"
  vpc_endpoint_type = "Interface"
  subnet_ids = [aws_subnet.lambda_private_subnet1a, aws_subnet.lambda_private_subnet1b]
  security_group_ids = [aws_security_group.vpc_endpoint_sg.id ]
}