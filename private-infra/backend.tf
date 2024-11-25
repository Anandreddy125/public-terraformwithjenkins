terraform {
  backend "s3" {
    bucket         = "anrs-k3s" # change this
    key            = "anrs/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "k3s-terraform-lock"
  }
}