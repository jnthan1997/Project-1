## Allow Lambda Function to be executed
resource "aws_iam_role" "lambdabackend_role" {

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Effect = "Allow"
            Principal = { Service = "lambda.amazonaws.com"},
            Action = "sts:AssumeRole"
        }]
    })
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
    role = aws_iam_role.lambdabackend_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
    ## Attache Iam policy to role to connect to VPC

}