terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.41.0"
    }
  }
  backend "s3" {
    bucket  = "terraform-statefiles-yt"
    key     = "terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

provider "aws" {
    region = "us-east-1"
    profile = "default"
}
