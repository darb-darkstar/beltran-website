module "static_site" {
    source = "../../modules/static-site"
        providers = {
        aws           = aws
        aws.us-east-1 = aws.us-east-1
    }
    domain_name = "bradbeltran.com"
    subdomain = "dev"
    github_username = "darb-darkstar"
    github_repo = "beltran-website"
    github_branch = "dev"
    environment = "dev"
    tags = {
        environment = "dev"
        Project = "beltran-website"
    }
}