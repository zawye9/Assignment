terraform {
  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = "4.2.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "6.38.0"
    }
  }
}
provider "aws" {
  region = var.aws_region
  profile = "zawye"

}


