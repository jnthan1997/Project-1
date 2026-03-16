terraform {
  required_version = ">=1.11.4"
  required_providers {
    aws ={
        source = "hashicorp/aws"
        version = "~> 6.15"
    }
  }
}

provider "aws" {
    profile = "AWS_Project"
    region = "ap-southeast-1"
}