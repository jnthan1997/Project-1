output "rds_endpint" {
    value = aws_db_instance.my_rds.endpoint
}

output "cd_endpoint" {
    value = aws_cloudfront_distribution.serverless_cdn.domain_name
  
}

output "bastion_public_ip" {

    value = aws_instance.bastion_ec2.public_ip
  
}