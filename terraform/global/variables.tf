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


variable "site_name" {
  description = "The name of the S3 bucket to host the website."
  type        = string
  default     = "brad-beltran-site"
}
