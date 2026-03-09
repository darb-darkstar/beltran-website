provider "aws" {
    region = "us-east-1"
}

module "static_site" {
    source = "../../modules/static-site"
    environment = "dev"
    domain_name = "bradbeltran.com"
    subdomain = "dev"

    tags {

        Environment = "dev"
    }
}