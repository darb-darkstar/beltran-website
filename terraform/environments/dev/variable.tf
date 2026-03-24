variable "aws_region"{
    type = string
    default = "us-east-1"
}

variable "allowed_ips" {
    description = "The IP address allowed to access the S3 bucket (for testing purposes)."
    type        = list(string)
    default     = [] 
}