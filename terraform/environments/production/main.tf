provider "aws" {
    region = "us-east-1"
}

module "static_site" {
    source = "../../modules/static-site"
    site_name = "beltran-website"
    tag = {
        Name = "beltran-website"
        Environment = "Dev"
    }
    domain_name = "bradbeltran.com"
    subdomain = ""
    github_repo = "beltran-website"
    environment = "prod"
}