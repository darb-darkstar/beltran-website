output "bucket_name" {
    value = aws_s3_bucket.website_bucket.bucket
}     

 
output "cloudfront_url" {
    value = aws_cloudfront_distribution.cdn.domain_name
}

output "website_url" {
    value = "https://${var.subdomain}.${var.domain_name}"
}

output "website_bucket_arn" {
    value = aws_s3_bucket.website_bucket.arn
}

output "cloudfront_distribution_id" {
    description = "The ID of the CloudFront distribution"
    value = aws_cloudfront_distribution.cdn.id
}

output "websit_bucket_name" {
    description = "The name of the S3 bucket hosting the website"
    value = aws_s3_bucket.website_bucket.id
}