terraform {
    required_providers{
        aws = {
            source= "hashicorp/aws"
        }
    }
  
}

provider "aws" {
    region = "us-east-1"
    profile = "aws_harika"
}

resource "aws_iam_user" "my_user1" {
    name = "user1"  
}