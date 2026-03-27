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
    username = ""
    password = ""
    db_subnet_group_name = aws_db_subnet_group.rds_sub_group.name
    vpc_security_group_ids = [ aws_security_group.rds_sgroup.id ]
    publicly_accessible = false
    skip_final_snapshot = true
  
}

 #Zip and import the backend code to the lambda
data "archive_file" "function_zip" {
    type = "zip"
    source_dir = "${path.module}/../backend"
    output_path = "${path.module}/app.zip"
   excludes    = [
      ".env", 
      ".git", 
      "tests", 
      "README.md"
    ]
  
}

### Lambda

resource "aws_lambda_function" "backend_function" {
    function_name = "backend"
    runtime = "nodejs18.x"
    handler = "app.handler"
    role = aws_iam_role.lambdabackend_role.arn
    filename = data.archive_file.function_zip.output_path
    source_code_hash = data.archive_file.function_zip.output_base64sha256

    

    vpc_config {
      subnet_ids = [ aws_subnet.lambda_private_subnet1a.id, aws_subnet.lambda_private_subnet1b.id ]
      security_group_ids = [ aws_security_group.lambda_sgroup.id ]
    }

    
    environment {
      variables = {
      SECRET_ARN = aws_secretsmanager_secret.project_secrets.arn
      DB_PORT     = "3306"

    }
      
    }

    depends_on = [
    aws_iam_role_policy_attachment.lambda_vpc,
    aws_iam_role_policy_attachment.lambda_logs
  ]
}

##### BASTION HOST(JUMP SERVER)

resource "aws_instance" "bastion_ec2" {
  ami = "ami-01938df366ac2d954"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.bastion_host.id
  vpc_security_group_ids = [ aws_security_group.bastion_sg.id ]
  key_name = ""
  
}