#S3 Bucket
resource "aws_s3_bucket" "static_bucket" {
    bucket = "my-project-1-serverless-bucket-saa"
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
    route_key = "ANY /{proxy+}" #Captures all paths
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
##OAC For s3
resource "aws_cloudfront_origin_access_control" "s3_oac" {
    name = "s3-oac"
    origin_access_control_origin_type = "s3"
    signing_behavior = "always"
    signing_protocol = "sigv4"
}


resource "aws_cloudfront_distribution" "serverless_cdn" {
    enabled = true

    ##Origin 1: For S3 Bucket CSS&JS
    origin {
      domain_name = aws_s3_bucket.static_bucket.bucket_regional_domain_name
      origin_id = "S3-Static-Assets"
      origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
    }

    #Origin 2 for API Gateway
    origin {
      domain_name = replace(aws_apigatewayv2_api.api_gate.api_endpoint,"/^https?://([^/]*).*/", "$1")
      origin_id = "APIGateway-Backend"

      custom_origin_config {
        http_port = 80
        https_port = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols = ["TLSv1.2"]
      }
    }
    
    default_cache_behavior {
    target_origin_id       = "APIGateway-Backend"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]

    forwarded_values {
      query_string = true
      cookies {
        forward = "all" # Necessary to pass your JWT cookie to the Lambda
      }
    }
  }
   ordered_cache_behavior {
     path_pattern = "/public/*"
     target_origin_id = "S3-Static-Assets"
     viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
     forwarded_values {
        query_string = false
      cookies { forward = "none" }
       
     }
   }
   restrictions {
     geo_restriction {
       restriction_type = "none"
     }
   }
   viewer_certificate {
     cloudfront_default_certificate = true
   }
}


