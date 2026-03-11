provider "aws" {
    region = var.aws_region
    alias = "admin"
}

provider "aws" {
    region = "us-east-1"
    alias =  "us-east-1"
}
