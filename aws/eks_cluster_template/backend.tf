terraform {
  backend "s3" {
    bucket  = "<<terraform_backend_s3_bucket>>"
    key     = "<<terraform_backend_s3_key>>"
    region  = "<<aws_region>>"
    encrypt = <<terraform_backend_s3_encrypt>>
  }
}

provider "aws" {
  region = "<<aws_region>>"
}