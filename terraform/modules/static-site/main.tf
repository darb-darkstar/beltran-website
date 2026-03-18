resource "aws_s3_bucket" "website_bucket" {
    bucket = var.environment == "prod" ? "brad-beltran-site" : "${var.environment}-brad-beltran-site"
    
    tags = var.tag
}

resource "aws_s3_object" "index" {
    bucket = aws_s3_bucket.website_bucket.id
    key    = "index.html"
    source = "${path.root}/../../../website/index.html"
    content_type = "text/html"
    etag = filemd5("${path.root}/../../../website/index.html")
}

resource "aws_s3_object" "error" {
    bucket = aws_s3_bucket.website_bucket.id
    key    = "error.html"
    source = "${path.root}/../../../website/error.html"
    content_type = "text/html"
    etag = filemd5("${path.root}/../../../website/error.html")

}

resource "aws_s3_bucket_public_access_block" "set" {
    bucket = aws_s3_bucket.website_bucket.id

    block_public_acls       = true
    block_public_policy     = false
    ignore_public_acls      = true
    restrict_public_buckets = false
}

data "aws_iam_policy_document" "site_policy" {
    
    statement {
        sid       = "AllowCloudFrontRead"

        actions   = ["s3:GetObject"]

        resources = ["${aws_s3_bucket.website_bucket.arn}/*"]

    
        principals {
            type        = "Service"
            identifiers = ["cloudfront.amazonaws.com"]
        }
    
        condition {
            test     = "StringEquals"
            variable = "AWS:SourceArn"
            values   = ["arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.cdn.id}"]
        }
    }

}

resource "aws_s3_bucket_policy" "cloudfront_policy" {
    bucket = aws_s3_bucket.website_bucket.id
    depends_on = [
        aws_cloudfront_distribution.cdn,
        aws_cloudfront_origin_access_control.oac,
        aws_s3_bucket_public_access_block.set
    ]

    policy = data.aws_iam_policy_document.site_policy.json
}




    






resource "aws_acm_certificate" "cert" {
    provider = aws.us-east-1
    domain_name = "${var.subdomain}.${var.domain_name}"
    validation_method = "DNS"

    subject_alternative_names = ["${var.subdomain}.${var.domain_name}"]

    lifecycle {
        create_before_destroy = true
    }

}


resource "aws_route53_record" "cert_validation" {
    for_each = { 
        for dvo in aws_acm_certificate.cert.domain_validation_options : 
        dvo.domain_name => {
            name   = dvo.resource_record_name
            type   = dvo.resource_record_type
            record = dvo.resource_record_value
        }
    }

    zone_id = data.aws_route53_zone.primary.zone_id
    name    = each.value.name
    type    = each.value.type
    records = [each.value.record]
    ttl= 60
}

resource "aws_acm_certificate_validation" "cert_validation" {
    provider = aws.us-east-1
    certificate_arn = aws_acm_certificate.cert.arn
    validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

resource "aws_route53_record" "website" {
    zone_id = data.aws_route53_zone.primary.zone_id
    name    = "${var.subdomain}.${var.domain_name}"
    type    = "A"
    alias {
        name                   = aws_cloudfront_distribution.cdn.domain_name
        zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
        evaluate_target_health = false
    }
}

data "aws_route53_zone" "primary" {
    name         = var.domain_name
    private_zone = false
}
data "aws_caller_identity" "current" {}

