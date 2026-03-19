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


variable "github_repo" {
  description = "The GitHub repository in the format 'owner/repo'."
  type        = string
}

variable "github_username" {
  description = "The GitHub username or organization name."
  type        = string
}

variable "github_branch" {
  description = "The GitHub branch to allow for deployments."
  type        = string
}

variable "environment" {
  type        = string
}

variable "domain_name" {
  type        = string
}

variable "subdomain" {
  type        = string
}

variable "tags" {
  type        = map(string)
}
variable "allowed_ips" {
    description = "A list of IP addresses allowed to access the website."
    type        = list(string)
    default     = []
}