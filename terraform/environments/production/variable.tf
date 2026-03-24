variable "aws_region"{
    type = string
    default = "us-east-1"
}

variable "environment" {
    type = string
    default = "prod"
}

variable "allowed_ips" {
    description = "The IP address allowed to access the S3 bucket (for testing purposes)."
    type        = list(string)
    default     = ["0.0.0.0"]
}