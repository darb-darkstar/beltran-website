variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-east-1"
}

variable "site_name" {
  description = "The name of the S3 bucket to host the website."
  type        = string
  default     = "brad-beltran-site"
}

variable "tag" {
  description = "A map of tags to apply to the resources."
  type        = map(string)
  default     = {
    Name        = "beltran-website"
    Environment = "Dev"
  }
}

variable "domain_name" {
  description = " rootThe domain name for the CloudFront distribution."
  default     = "bradbeltran.com"
}

variable "subdomain" {
  description = "The subdomain for the CloudFront distribution."
  default     = "www"
}
variable "github_repo" {
  description = "The GitHub repository in the format 'owner/repo'."
  type        = string
  default     = "beltran-website"
}

variable "github_username" {
  description = "The GitHub username or organization name."
  type        = string
  default     = "darb-darkstar"
}

variable "github_branch" {
  description = "The GitHub branch to allow for deployments."
  type        = string
  default     = "main"
}