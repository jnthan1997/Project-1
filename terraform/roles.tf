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

##Integrate Lambda to API gateway

resource "aws_lambda_permission" "lambda_api" {
    statement_id = "AllowInvoke"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.backend_function.function_name
    principal = "apigateway.amazonaws.com"
  
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
    role = aws_iam_role.lambdabackend_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  
}

## cdn  policy access object in s3

data "aws_iam_policy_document" "cdn_policy" {

    statement {
      actions = [ "s3:GetObject" ]
      resources = [ "${aws_s3_bucket.static_bucket.arn}/public/*" ]

      principals {
        type = "Service"
        identifiers = [ "cloudfront.amazonaws.com" ]
      }

      condition {
        test = "StringEquals"
        variable = "AWS:SourceArn"
        values = [ aws_cloudfront_distribution.serverless_cdn.arn ]
      }
    }
}

resource "aws_s3_bucket_policy" "allow_cdn_to_s3" {
  bucket = aws_s3_bucket.static_bucket.id
  policy = data.aws_iam_policy_document.cdn_policy.json
}

