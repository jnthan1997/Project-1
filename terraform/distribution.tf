#S3 Bucket
resource "aws_s3_bucket" "static_bucket" {
    bucket = "project-1-serverless-bucket"
}

#S3 bucket blocking policy

resource "aws_s3_bucket_public_access_block" "s3_block" {
    bucket = aws_s3_bucket.static_bucket.id

    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
  
}

##API GATEWAY
resource "aws_apigatewayv2_api" "api_gate" {
    name = "api-backend"
    protocol_type = "HTTP"

    cors_configuration {
      allow_origins = [ "*" ]
      allow_methods = [ "POST" ]
      allow_headers = [ "*" ]
    }
  
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
    api_id = aws_apigatewayv2_api.api_gate.id
    integration_type = "AWS_PROXY"
    integration_uri = aws_lambda_function.backend_function.invoke_arn
  
}

resource "aws_apigatewayv2_route" "proxy" {
    api_id = aws_apigatewayv2_api.api_gate.id
    route_key = "ANY / {proxy+}" #Captures all paths
    target = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"  
}

resource "aws_apigatewayv2_route" "root" {
  api_id = aws_apigatewayv2_api.api_gate.id
  route_key = "ANY /"
  target = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"  
}

resource "aws_apigatewayv2_stage" "default" {
    api_id = aws_apigatewayv2_api.api_gate.id
    name = "$default"
    auto_deploy = true
  
}

####Cloud Distribution

resource "aws_cloudfront_origin_access_control" "s3_oac" {
    name = "s3-oac"
    origin_access_control_origin_type = "s3"
    signing_behavior = "always"
    signing_protocol = "sigv4"
}

