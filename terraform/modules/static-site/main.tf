resource "aws_s3_bucket" "website_bucket" {
    bucket = "${var.environment}-${var.site_name}"
    tags = var.tag
}

resource "aws_s3_object" "index" {
    bucket = aws_s3_bucket.website_bucket.id
    key    = "index.html"
    source = "${path.module}/../website/index.html"
    content_type = "text/html"
    etag = filemd5("${path.module}/../website/index.html")
}

resource "aws_s3_object" "error" {
    bucket = aws_s3_bucket.website_bucket.id
    key    = "error.html"
    source = "${path.module}/../website/error.html"
    content_type = "text/html"
    etag = filemd5("${path.module}/../website/error.html")

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



data "aws_cloudfront_cache_policy" "caching_optimized" {
    name = "Managed-CachingOptimized"
}

resource "aws_cloudfront_distribution" "cdn" {
    depends_on = [aws_acm_certificate_validation.cert_validation]
    
    origin {
        domain_name = aws_s3_bucket.website_bucket.bucket_regional_domain_name
        origin_id   = "S3-${aws_s3_bucket.website_bucket.id}"
        origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
    }

    enabled             = true
    comment             = "CDN for ${var.site_name}"
    default_root_object = "index.html"
    aliases             = ["${var.subdomain}.${var.domain_name}"]




    default_cache_behavior {
        target_origin_id       = "S3-${aws_s3_bucket.website_bucket.id}"
        viewer_protocol_policy = "redirect-to-https"
        allowed_methods        = ["GET", "HEAD"]
        cached_methods         = ["GET", "HEAD"]
        cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized.id
    }

    restrictions {
        geo_restriction {
            restriction_type = "none"
        }
    }

    viewer_certificate {
        acm_certificate_arn = aws_acm_certificate.cert.arn
        ssl_support_method  = "sni-only"
        minimum_protocol_version = "TLSv1.2_2021"
    }

    custom_error_response {
        error_code         = 403
        response_code      = 404
        response_page_path = "/../website/error.html"
    }

    lifecycle {
        prevent_destroy = true
    }
}

resource "aws_cloudfront_distribution" "apex_redirect" {
    enabled = true
    aliases = [var.domain_name]

    origin {
        domain_name = aws_cloudfront_distribution.cdn.domain_name
        origin_id   = "redirect-origin"
    
    custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2"]
    
    }
    }

    default_cache_behavior {
        target_origin_id       = "redirect-origin"
        viewer_protocol_policy = "redirect-to-https"
        allowed_methods        = ["GET", "HEAD"]
        cached_methods         = ["GET", "HEAD"]
        cache_policy_id        = data.aws_cloudfront_cache_policy.caching_optimized.id
        function_association {
            event_type   = "viewer-request"
            function_arn = aws_cloudfront_function.apex_redirect.arn
        }
    }

    

    viewer_certificate {
        acm_certificate_arn = aws_acm_certificate.cert.arn
        ssl_support_method  = "sni-only"
        minimum_protocol_version = "TLSv1.2_2021"
    }

    restrictions {
        geo_restriction {
            restriction_type = "none"
        }
    }
       
}
    

    




resource "aws_cloudfront_origin_access_control" "oac" {
    name = "${var.site_name}-oac"
    description     = "OAC for ${var.site_name}"
    signing_behavior = "always"
    signing_protocol = "sigv4"
    origin_access_control_origin_type    = "s3"
    
}

resource "aws_acm_certificate" "cert" {
    provider = aws.us-east-1
    domain_name = "${var.domain_name}"
    validation_method = "DNS"

    subject_alternative_names = ["${var.subdomain}.${var.domain_name}"]

    lifecycle {
        create_before_destroy = true
    }

}

resource "aws_cloudfront_function" "apex_redirect"  {
    name    = "${var.site_name}-apex-redirect"
    runtime = "cloudfront-js-1.0"
    code    = <<EOF
function handler(event) {
    var request = event.request;
    var host = request.headers.host.value;

    if (host === "${var.domain_name}") {
        var response = {
            statusCode: 301,
            statusDescription: 'Moved Permanently',
            headers: {
                "location": { "value": "https://${var.subdomain}.${var.domain_name}$"}
            }
        };
        return response;
    }
    EOF
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
