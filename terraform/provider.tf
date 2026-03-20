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
    profile = "homeprofile1"
    region = "ap-southeast-1"
}