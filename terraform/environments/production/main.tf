provider "aws" {
    region = "us-east-1"
}

module "static_site" {
    source = "../../modules/static-site"
    providers = {
        aws           = aws
        aws.us-east-1 = aws.us-east-1
    }
    site_name = "beltran-website"
    tag = {
        Name = "beltran-website"
        Environment = "Dev"
    }
    domain_name = "bradbeltran.com"
    subdomain = "www"
    github_username = "darb-darkstar"
    github_repo = "beltran-website"
    github_branch = "main"
    environment = "prod"
    tags = {
        environment = "dev"
        Project = "beltran-website"
    }
}