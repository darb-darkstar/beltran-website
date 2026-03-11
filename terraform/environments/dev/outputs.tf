output "bucket_name"{
    value = module.static_site.bucket_name
}

output "cloudfront_distribution_id" {
    value = module.static_site.cloudfront_distribution_id
}