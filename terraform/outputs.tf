output "bucket_name" {
    value = aws_s3_bucket.website_bucket.bucket
}     

 
output "cloudfront_url" {
    value = aws_cloudfront_distribution.cdn.domain_name
}

output "website_url" {
    value = "https://${var.subdomain}.${var.domain_name}"
}