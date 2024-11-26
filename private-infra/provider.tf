terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.40.0"
    }
  }
}

provider "aws" {
  region = var.region_1
  alias  = "region_1"
}

provider "aws" {
  region = var.region_2
  alias  = "region_2"
}

