##RDS

resource "aws_db_subnet_group" "rds_sub_group" {
    subnet_ids = [ 
        aws_subnet.rds_private_subnet1a.id,
        aws_subnet.rds_private_subnet1b.id
    ]
}

resource "aws_db_instance" "my_rds" {
    identifier = "my-db-instance"
    allocated_storage = "10"
    engine = "mysql"
    engine_version = "8.0"
    instance_class = "db.t3.micro"
    db_name = "mydatabase"
    username = "admin"
    password = "passwordhere123!"
    db_subnet_group_name = aws_db_subnet_group.rds_sub_group.name
    vpc_security_group_ids = [ aws_security_group.rds_sgroup.id ]
    publicly_accessible = false
    skip_final_snapshot = true
  
}

### Lambda

resource "aws_lambda_function" "backend_function" {
    function_name = "backend"
    runtime = "nodejs18.x"
    handler = "app.handler"
    role = aws_iam_role.lambdabackend_role.arn
    filename = ""

    vpc_config {
      subnet_ids = [ aws_subnet.lambda_private_subnet1a.id, aws_subnet.lambda_private_subnet1b.id ]
      security_group_ids = [ aws_security_group.lambda_sgroup.id ]
    }
}