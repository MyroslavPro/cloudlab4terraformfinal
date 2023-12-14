terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
   cloud {
    organization = "myropro1org"
    workspaces {
      name = "cloudlab4terraformfinal"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-west-1"
}

