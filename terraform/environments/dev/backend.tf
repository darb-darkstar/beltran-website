terraform{
    backend "s3" {
        bucket = "beltran-terraform-state"
        key    = "beltran-website/dev/terraform.tfstate"
        region = "us-east-1"
        dynamodb_table = "terraform-locks"
        encrypt = true
    }
}